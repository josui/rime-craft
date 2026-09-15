// rime-dashboard v2.4.0
// Entry: CLI parsing / launcher (finds or starts a detached server on a stable port) / server (--serve: HTTP + SSE live reload)
// The board page template is board.html in this directory (data injected via placeholders); UI changes touch the template only
import { createServer, request as httpRequest } from 'node:http'
import { readFileSync, writeFileSync, watch, existsSync, openSync, closeSync } from 'node:fs'
import { join, resolve, dirname, relative, basename, sep } from 'node:path'
import { fileURLToPath } from 'node:url'
import { createHash } from 'node:crypto'
import { exec, execFileSync, spawn } from 'node:child_process'
import { tmpdir } from 'node:os'

const [major] = process.versions.node.split('.').map(Number)
if (major < 18) {
  console.error(`Node.js 18+ required (current: ${process.version})`)
  process.exit(1)
}

// .rime directory resolution. The authoritative definition of the resolution
// order is "Storage Location & Resolution Order" in skills/rime-flow/data-contract.md.
// Keep this equivalent to rime_resolve_base in hooks/scripts/rime-utils.sh —
// if the two drift apart, hooks and the dashboard see different data.
function gitOut(args, cwd) {
  try {
    return execFileSync('git', args, { cwd, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim()
  } catch {
    return ''
  }
}

// Map a linked worktree's cwd to its equivalent path in the main working tree:
// <wt>/apps/foo → <main>/apps/foo. In the main checkout, return cwd as-is.
function resolveBase(cwd) {
  // Normalize both with --path-format=absolute (--git-dir returns the relative
  // path .git at the repo root, so they can't be compared unnormalized. git ≥ 2.31)
  const gitDir = gitOut(['rev-parse', '--path-format=absolute', '--git-dir'], cwd)
  const gitCommon = gitOut(['rev-parse', '--path-format=absolute', '--git-common-dir'], cwd)
  if (!gitDir || !gitCommon || gitDir === gitCommon) return cwd

  const wtRoot = gitOut(['rev-parse', '--show-toplevel'], cwd)
  const mainRoot = dirname(gitCommon)
  // With a bare repo + worktree, dirname(git-common-dir) is merely the bare repo's parent
  if (!wtRoot || !existsSync(join(mainRoot, '.git'))) return cwd

  const rel = relative(wtRoot, cwd)
  return rel ? join(mainRoot, rel) : mainRoot
}

const rimeDirArg = process.argv.indexOf('--rime-dir')
const RIME_DIR = rimeDirArg !== -1 && process.argv[rimeDirArg + 1]
  ? resolve(process.argv[rimeDirArg + 1])
  : process.env.RIME_DIR && existsSync(process.env.RIME_DIR)
    ? resolve(process.env.RIME_DIR)
    : join(resolveBase(process.cwd()), '.rime')
const ONCE = process.argv.includes('--once')
const SERVE = process.argv.includes('--serve')
const portArgIdx = process.argv.indexOf('--port')
const PORT = portArgIdx !== -1 ? Number(process.argv[portArgIdx + 1]) : null
const PROJECT_DIR = resolve(RIME_DIR, '..')
const TEMPLATE_PATH = join(dirname(fileURLToPath(import.meta.url)), 'board.html')

if (!existsSync(join(RIME_DIR, 'tasks.json'))) {
  console.error(`No .rime/ data found at: ${RIME_DIR}`)
  console.error('Run /rime-init to initialize the project first.')
  process.exit(1)
}

function readJson(filename) {
  try {
    return readFileSync(join(RIME_DIR, filename), 'utf8').trim()
  } catch {
    return filename.endsWith('cautions.json') ? '[]' : '{}'
  }
}

function openBrowser(url) {
  const cmd = process.platform === 'darwin' ? 'open'
            : process.platform === 'win32'  ? 'start'
            : 'xdg-open'
  exec(`${cmd} "${url}"`)
}

function escapeHtml(s) {
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
}

function generateHtml(isLive) {
  return readFileSync(TEMPLATE_PATH, 'utf8')
    .replace('__PROJECT_NAME__', () => escapeHtml(basename(PROJECT_DIR)))
    .replace('__TASKS_DATA__', () => readJson('tasks.json'))
    .replace('__PHASE_DATA__', () => readJson('phase.json'))
    .replace('__CAUTIONS_DATA__', () => readJson('cautions.json'))
    .replace('__WATCH_MODE__', () => isLive ? 'true' : 'false')
    .replace('__LIVE_CLASS__', () => isLive ? 'on' : '')
}

// --once mode
if (ONCE) {
  const html = generateHtml(false)
  const hash = createHash('md5').update(RIME_DIR).digest('hex').slice(0, 8)
  const outPath = join(tmpdir(), `rime-dashboard-${hash}.html`)
  writeFileSync(outPath, html)
  console.log(`Dashboard: ${outPath}`)
  openBrowser(outPath)
  process.exit(0)
}

// Ask a candidate server's /health endpoint whether it is up, and if so what
// project it is serving. Used both to probe for a reusable instance and to
// poll a freshly spawned one until it answers.
function probeHealth(port, timeoutMs) {
  return new Promise((settle) => {
    const req = httpRequest({ host: '127.0.0.1', port, path: '/health', method: 'GET', timeout: timeoutMs }, (res) => {
      let body = ''
      res.on('data', (chunk) => { body += chunk })
      res.on('end', () => {
        try {
          settle({ up: true, json: JSON.parse(body) })
        } catch {
          settle({ up: true, json: null })
        }
      })
    })
    req.on('timeout', () => {
      req.destroy()
      settle({ up: false, refused: false })
    })
    req.on('error', (err) => {
      settle({ up: false, refused: err.code === 'ECONNREFUSED' })
    })
    req.end()
  })
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms))
}

// Find a port for this project: reuse a running instance if one already
// answers for RIME_DIR, otherwise the first free port from preferredPort up.
async function findPort(preferredPort) {
  for (let i = 0; i < 20; i++) {
    const port = preferredPort + i
    const result = await probeHealth(port, 500)
    if (result.up && result.json && result.json.rimeDir === RIME_DIR) {
      return { reuse: true, port, pid: result.json.pid }
    }
    if (!result.up && result.refused) {
      return { reuse: false, port }
    }
    // Answered but for a different project, or timed out / errored some other
    // way: treat the port as taken and move on to the next candidate.
  }
  return null
}

async function waitForHealth(port, attempts, intervalMs) {
  for (let i = 0; i < attempts; i++) {
    const result = await probeHealth(port, intervalMs)
    if (result.up && result.json && result.json.rimeDir === RIME_DIR) return true
    await sleep(intervalMs)
  }
  return false
}

// Launcher (default invocation): find or start a detached server for this
// project, then exit. Spawned detached because a child of the launching
// session is killed the moment that session ends; detaching lets the
// dashboard outlive it.
async function runLauncher() {
  const hash8 = createHash('md5').update(RIME_DIR).digest('hex').slice(0, 8)
  const preferredPort = 40000 + (parseInt(hash8, 16) % 10000)
  const logPath = join(tmpdir(), `rime-dashboard-${hash8}.log`)

  const found = await findPort(preferredPort)
  if (!found) {
    console.error(`Could not find a free port near ${preferredPort} for the dashboard server.`)
    process.exit(1)
  }

  if (found.reuse) {
    const url = `http://localhost:${found.port}`
    console.log(`Dashboard: ${url}`)
    console.log(`Reusing existing instance (pid ${found.pid})`)
    openBrowser(url)
    process.exit(0)
  }

  const scriptPath = fileURLToPath(import.meta.url)
  const logFd = openSync(logPath, 'a')
  const child = spawn(process.execPath, [scriptPath, '--serve', '--port', String(found.port), '--rime-dir', RIME_DIR], {
    detached: true,
    stdio: ['ignore', logFd, logFd],
    cwd: PROJECT_DIR,
  })
  closeSync(logFd)
  child.unref()

  const ready = await waitForHealth(found.port, 50, 100)
  if (!ready) {
    console.error(`Dashboard server did not become ready. See log: ${logPath}`)
    process.exit(1)
  }

  const url = `http://localhost:${found.port}`
  console.log(`Dashboard: ${url}`)
  console.log(`Watching: ${RIME_DIR}`)
  console.log(`Server pid ${child.pid} runs detached; stop it with: kill ${child.pid}`)
  openBrowser(url)
  process.exit(0)
}

// Server (--serve --port <n>): HTTP + SSE + fs.watch. Runs detached from
// whatever launched it; does not open a browser itself.
function runServer() {
  let html = generateHtml(true)
  const sseClients = new Set()

  const server = createServer((req, res) => {
    if (req.url === '/health') {
      res.writeHead(200, { 'Content-Type': 'application/json' })
      res.end(JSON.stringify({ rimeDir: RIME_DIR, pid: process.pid }))
      return
    }
    if (req.url === '/events') {
      res.writeHead(200, {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        Connection: 'keep-alive',
      })
      sseClients.add(res)
      req.on('close', () => sseClients.delete(res))
      return
    }
    if (req.url === '/' || req.url === '') {
      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' })
      res.end(html)
      return
    }
    if (req.url.startsWith('/archives/')) {
      const phaseId = decodeURIComponent(req.url.slice(10))
      const archivePath = join(RIME_DIR, 'archives', `tasks.${phaseId}.json`)
      try {
        const data = readFileSync(archivePath, 'utf8')
        res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' })
        res.end(data)
      } catch {
        res.writeHead(404, { 'Content-Type': 'application/json' })
        res.end('{"error":"not_found"}')
      }
      return
    }
    if (req.url.startsWith('/file/')) {
      const relPath = decodeURIComponent(req.url.slice(6))
      const filePath = join(PROJECT_DIR, relPath)
      // Containment check: separator-aware prefix so a sibling directory
      // sharing the project's name as a prefix (e.g. rime-craft-evil) cannot pass.
      if (!filePath.startsWith(PROJECT_DIR + sep)) {
        res.writeHead(403)
        res.end('Forbidden')
        return
      }
      try {
        const raw = readFileSync(filePath)
        const ext = relPath.slice(relPath.lastIndexOf('.') + 1).toLowerCase()
        if (ext === 'md' || ext === 'markdown') {
          const mdTemplatePath = join(dirname(TEMPLATE_PATH), 'md.html')
          const mdDir = dirname(relPath)
          // Escaping angle brackets as a unicode sequence keeps a literal closing-script-tag inside the markdown from ending the embedding tag early
          const jsSafe = s => JSON.stringify(s).replace(/</g, '\\u003c')
          const html = readFileSync(mdTemplatePath, 'utf8')
            .replace('__DOC_TITLE__', () => escapeHtml(`${basename(relPath)} — ${basename(PROJECT_DIR)}`))
            .replace('__MD_SOURCE__', () => jsSafe(raw.toString('utf8')))
            .replace('__MD_DIR__', () => jsSafe(mdDir === '.' ? '' : mdDir))
          res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' })
          res.end(html)
          return
        }
        const TYPES = { html: 'text/html', htm: 'text/html', css: 'text/css', js: 'text/javascript', json: 'application/json', svg: 'image/svg+xml' }
        const type = TYPES[ext] || 'text/plain'
        res.writeHead(200, { 'Content-Type': `${type}; charset=utf-8` })
        res.end(raw)
      } catch {
        res.writeHead(404)
        res.end('File not found')
      }
      return
    }
    res.writeHead(404)
    res.end('Not Found')
  })

  server.on('error', (err) => {
    console.error(`Dashboard server error: ${err.message}`)
    process.exit(1)
  })

  server.listen(PORT, () => {
    console.log(`Dashboard server listening on port ${PORT}`)
    console.log(`Watching: ${RIME_DIR}`)
    console.log(`pid ${process.pid}`)
  })

  let debounceTimer = null
  watch(RIME_DIR, () => {
    clearTimeout(debounceTimer)
    debounceTimer = setTimeout(() => {
      html = generateHtml(true)
      for (const client of sseClients) {
        client.write('data: reload\n\n')
      }
    }, 300)
  })

  function shutdown() {
    server.close()
    process.exit(0)
  }
  process.on('SIGINT', shutdown)
  process.on('SIGTERM', shutdown)
}

if (SERVE) {
  runServer()
} else {
  runLauncher()
}
