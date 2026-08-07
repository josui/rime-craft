// rime-dashboard v2.3.0
// Entry: CLI parsing / HTTP server / SSE live reload / fs.watch
// The board page template is board.html in this directory (data injected via placeholders); UI changes touch the template only
import { createServer } from 'node:http'
import { readFileSync, writeFileSync, watch, existsSync } from 'node:fs'
import { join, resolve, dirname, relative, basename } from 'node:path'
import { fileURLToPath } from 'node:url'
import { createHash } from 'node:crypto'
import { exec, execFileSync } from 'node:child_process'
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

// Watch mode (default) - HTTP server + SSE + fs.watch
let html = generateHtml(true)
const sseClients = new Set()

const server = createServer((req, res) => {
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
    // Security check: no path traversal outside the project directory
    if (!filePath.startsWith(PROJECT_DIR)) {
      res.writeHead(403)
      res.end('Forbidden')
      return
    }
    try {
      const raw = readFileSync(filePath)
      const ext = relPath.slice(relPath.lastIndexOf('.') + 1).toLowerCase()
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

server.listen(0, () => {
  const { port } = server.address()
  const url = `http://localhost:${port}`
  console.log(`Dashboard: ${url}`)
  console.log(`Watching: ${RIME_DIR}`)
  console.log('Press Ctrl+C to stop')
  openBrowser(url)
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
