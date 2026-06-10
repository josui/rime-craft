// rime-dashboard v2.1.0
// 入口：CLI 解析 / HTTP server / SSE live reload / fs.watch
// 看板页面模板在同目录 board.html（占位符注入数据），改 UI 只动模板文件
import { createServer } from 'node:http'
import { readFileSync, writeFileSync, watch, existsSync } from 'node:fs'
import { join, resolve, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'
import { createHash } from 'node:crypto'
import { exec } from 'node:child_process'
import { tmpdir } from 'node:os'

const [major] = process.versions.node.split('.').map(Number)
if (major < 18) {
  console.error(`Node.js 18+ required (current: ${process.version})`)
  process.exit(1)
}

// --rime-dir <path> で指定、なければ cwd/.rime、最後にスクリプト所在ディレクトリ
const rimeDirArg = process.argv.indexOf('--rime-dir')
const RIME_DIR = rimeDirArg !== -1 && process.argv[rimeDirArg + 1]
  ? resolve(process.argv[rimeDirArg + 1])
  : existsSync(join(process.cwd(), '.rime'))
    ? join(process.cwd(), '.rime')
    : join(process.cwd(), '.rime')
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

function generateHtml(isLive) {
  return readFileSync(TEMPLATE_PATH, 'utf8')
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
    // 安全检查：不允许路径遍历到项目目录之外
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
