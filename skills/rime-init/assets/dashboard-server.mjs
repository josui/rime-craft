// rime-dashboard v2.0.0
import { createServer } from 'node:http'
import { readFileSync, writeFileSync, watch, existsSync } from 'node:fs'
import { join, resolve } from 'node:path'
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
  const tasksJson = readJson('tasks.json')
  const phaseJson = readJson('phase.json')
  const cautionsJson = readJson('cautions.json')

  const reloadScript = isLive
    ? `const es = new EventSource('/events')
es.onmessage = () => location.reload()
es.onerror = () => {
  document.querySelector('.live-dot')?.classList.remove('on')
}`
    : ''

  const html = `<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Rime Dashboard</title>
<style>
  @font-face {
    font-family: 'Cascadia Code';
    src: local('Cascadia Code'), local('CascadiaCode-Regular');
  }

  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

  :root {
    --bg: #f4f2ed;
    --surface: #faf9f6;
    --border: #ddd9d1;
    --text: #2c2a25;
    --text-2: #635e56;
    --text-3: #8a857c;
    --accent: #4355db;
    --accent-soft: #eef0fb;
    --done: #3d8b5e;
    --done-soft: #edf6f0;
    --doing: #c0690b;
    --doing-soft: #fef5e7;
    --high: #c53030;
    --medium: #c0690b;
    --low: #7a756c;
    --radius: 5px;
    --font: 'Cascadia Code', 'Cascadia Mono', "PingFang SC", "Hiragino Sans", system-ui, sans-serif;
  }

  body {
    font-family: var(--font);
    -webkit-font-smoothing: antialiased;
    background: var(--bg);
    color: var(--text);
    font-size: 14px;
    line-height: 1.6;
    padding: clamp(1rem, 3vw, 2.5rem);
    max-width: 1400px;
    margin: 0 auto;
  }

  /* ── Header ── */
  header {
    display: flex;
    align-items: center;
    gap: 0.65rem;
    margin-bottom: 1.25rem;
    padding-bottom: 0.85rem;
    border-bottom: 1px solid var(--border);
  }

  header h1 {
    font-size: 1.05rem;
    font-weight: 700;
    letter-spacing: -0.02em;
  }

  .live-dot {
    width: 6px;
    height: 6px;
    border-radius: 50%;
    background: var(--text-3);
    flex-shrink: 0;
  }

  .live-dot.on {
    background: var(--done);
    animation: pulse 2s ease-in-out infinite;
  }

  @keyframes pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.3; }
  }

  /* Phase badge + dropdown */
  .phase-wrap {
    position: relative;
  }

  .phase-badge {
    display: inline-flex;
    align-items: center;
    gap: 0.3rem;
    padding: 0.15rem 0.5rem;
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: 4px;
    font-size: 0.78rem;
    cursor: pointer;
    transition: background 0.15s, border-color 0.15s;
    user-select: none;
  }

  .phase-badge:hover {
    background: var(--bg);
    border-color: var(--text-3);
  }

  .phase-badge .id {
    font-weight: 700;
    color: var(--text);
  }

  .phase-badge .name { color: var(--text-2); }

  .phase-drop {
    position: absolute;
    top: calc(100% + 0.35rem);
    left: 0;
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: 6px;
    padding: 0.35rem 0;
    min-width: 250px;
    box-shadow: 0 6px 24px rgba(44,42,37,0.1);
    opacity: 0;
    pointer-events: none;
    transform: translateY(-4px);
    transition: opacity 0.2s cubic-bezier(0.16,1,0.3,1), transform 0.2s cubic-bezier(0.16,1,0.3,1);
    z-index: 50;
  }

  .phase-drop.open {
    opacity: 1;
    pointer-events: auto;
    transform: translateY(0);
  }

  .ph-item {
    display: flex;
    align-items: center;
    gap: 0.45rem;
    padding: 0.35rem 0.75rem;
    font-size: 0.75rem;
  }

  .ph-item .dot {
    width: 6px;
    height: 6px;
    border-radius: 50%;
    flex-shrink: 0;
  }

  .ph-item[data-status="active"] .dot { background: var(--accent); }
  .ph-item[data-status="done"] .dot { background: var(--done); }
  .ph-item[data-status="done"] { opacity: 0.45; }
  .ph-item .ph-id { font-weight: 700; color: var(--text-2); }
  .ph-item .ph-date { color: var(--text-3); margin-left: auto; }

  /* Tabs */
  .tabs {
    display: flex;
    gap: 0;
    margin-left: auto;
    border: 1px solid var(--border);
    border-radius: 4px;
    padding: 2px;
    background: var(--surface);
  }

  .tab {
    padding: 0.25rem 0.7rem;
    font-size: 0.78rem;
    font-weight: 600;
    color: var(--text-3);
    cursor: pointer;
    border-radius: 3px;
    transition: background 0.15s, color 0.15s;
    user-select: none;
  }

  .tab:hover { color: var(--text-2); }

  .tab.active {
    background: var(--text);
    color: var(--surface);
  }

  .tab .cnt {
    font-weight: 500;
    opacity: 0.65;
    margin-left: 0.2rem;
  }

  .meta {
    font-size: 0.7rem;
    color: var(--text-3);
    margin-left: 0.5rem;
  }

  .tab-panel { display: none; }
  .tab-panel.active { display: block; }

  /* ── Filters ── */
  .filters {
    display: flex;
    gap: 0.35rem;
    margin-bottom: 0.65rem;
    flex-wrap: wrap;
    align-items: center;
  }

  .fg {
    display: flex;
    align-items: center;
    gap: 0.15rem;
  }

  .fl {
    font-size: 0.68rem;
    color: var(--text-3);
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    margin-right: 0.1rem;
  }

  .fb {
    font-size: 0.7rem;
    font-family: var(--font);
    padding: 0.15rem 0.45rem;
    border-radius: 3px;
    border: 1px solid transparent;
    background: transparent;
    color: var(--text-2);
    cursor: pointer;
    font-weight: 500;
    transition: all 0.12s;
  }

  .fb:hover {
    background: var(--surface);
    border-color: var(--border);
  }

  .fb.on {
    background: var(--text);
    color: var(--surface);
    border-color: var(--text);
  }

  .fsep {
    width: 1px;
    height: 12px;
    background: var(--border);
    margin: 0 0.15rem;
  }

  /* ── Board ── */
  .board {
    display: grid;
    grid-template-columns: 2fr 3fr 2fr;
    gap: 0.65rem;
    align-items: start;
  }

  .col {
    border-radius: var(--radius);
    background: var(--surface);
    border: 1px solid var(--border);
    overflow: hidden;
  }

  .col[data-status="doing"] {
    border-color: color-mix(in srgb, var(--doing) 25%, var(--border));
  }

  .col-h {
    display: flex;
    align-items: center;
    gap: 0.4rem;
    padding: 0.6rem 0.8rem;
    font-size: 0.72rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.06em;
    color: var(--text-3);
    border-bottom: 1px solid var(--border);
  }

  .col-h .dot {
    width: 6px;
    height: 6px;
    border-radius: 50%;
    flex-shrink: 0;
  }

  .col[data-status="todo"] .col-h .dot { background: var(--text-3); }
  .col[data-status="doing"] .col-h .dot { background: var(--doing); }
  .col[data-status="doing"] .col-h { color: var(--doing); }
  .col[data-status="done"] .col-h .dot { background: var(--done); }

  .col-h .n {
    margin-left: auto;
    font-weight: 500;
    font-size: 0.65rem;
    color: var(--text-3);
    opacity: 0.75;
  }

  .col-b {
    padding: 0.35rem;
    max-height: 72vh;
    overflow-y: auto;
    min-height: 40px;
    display: flex;
    flex-direction: column;
    gap: 0.3rem;
  }

  /* ── Task item ── */
  .tk {
    padding: 0.6rem 0.65rem;
    border-radius: 4px;
    border: 1px solid color-mix(in srgb, var(--border) 60%, transparent);
    position: relative;
    transition: background 0.12s;
  }

  .tk:hover {
    background: color-mix(in srgb, var(--bg) 50%, transparent);
  }

  .col[data-status="todo"] .tk,
  .col[data-status="done"] .tk { cursor: pointer; }

  .col[data-status="done"] .tk { opacity: 0.55; }
  .col[data-status="done"] .tk:hover { opacity: 0.8; }

  .tk-head {
    display: flex;
    align-items: center;
    gap: 0.3rem;
    margin-bottom: 0.1rem;
  }

  .tk-id {
    font-size: 0.7rem;
    font-weight: 700;
    color: var(--text-3);
    cursor: pointer;
    border-radius: 2px;
    padding: 0.02rem 0.12rem;
    margin: -0.02rem -0.12rem;
    transition: background 0.12s, color 0.12s;
  }

  .tk-id:hover { background: var(--accent); color: #fff; }
  .tk-id.copied { background: var(--done); color: #fff; }

  .tk-mod {
    font-size: 0.62rem;
    padding: 0.08rem 0.3rem;
    border-radius: 2px;
    background: #d0d6f0;
    color: var(--accent);
    font-weight: 600;
  }

  .tk-ph {
    font-size: 0.62rem;
    padding: 0.08rem 0.25rem;
    border-radius: 2px;
    background: var(--bg);
    color: var(--text-2);
  }

  .tk-title {
    font-size: 0.9rem;
    font-weight: 600;
    line-height: 1.45;
    margin-bottom: 0.1rem;
    letter-spacing: -0.01em;
  }

  .tk-desc {
    font-size: 0.78rem;
    color: var(--text-2);
    line-height: 1.55;
    margin-bottom: 0.25rem;
  }

  /* Todo: truncate desc */
  .col[data-status="todo"] .tk-desc {
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }

  /* Done: compact — hide desc, subtasks, docs, git */
  .col[data-status="done"] .tk-desc,
  .col[data-status="done"] .subs,
  .col[data-status="done"] .tk-docs,
  .col[data-status="done"] .tk-git { display: none; }

  .tk-meta {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    flex-wrap: wrap;
    margin-top: 0.15rem;
  }

  .badge {
    display: inline-flex;
    align-items: center;
    gap: 0.2rem;
    padding: 0.08rem 0.35rem;
    border-radius: 3px;
    font-size: 0.68rem;
    font-weight: 600;
  }

  .badge .dot {
    width: 5px;
    height: 5px;
    border-radius: 50%;
    flex-shrink: 0;
  }

  .badge.high { background: #fce4e4; color: var(--high); }
  .badge.high .dot { background: var(--high); }
  .badge.medium { background: #fcecd4; color: var(--medium); }
  .badge.medium .dot { background: var(--medium); }
  .badge.low { background: #e8e5df; color: var(--low); }
  .badge.low .dot { background: var(--low); }

  .diff {
    font-size: 0.68rem;
    font-weight: 600;
    padding: 0.08rem 0.35rem;
    border-radius: 2px;
  }

  .diff.small { background: #d4eddb; color: var(--done); }
  .diff.medium { background: #fce8c8; color: var(--doing); }
  .diff.large { background: #fce4e4; color: var(--high); }

  .tk-date {
    font-size: 0.68rem;
    color: var(--text-3);
    margin-left: auto;
  }

  /* Doc links */
  .tk-docs {
    display: flex;
    gap: 0.6rem;
    flex-wrap: wrap;
    margin-top: 0.35rem;
    padding-top: 0.3rem;
    border-top: 1px solid color-mix(in srgb, var(--border) 50%, transparent);
  }

  .doc-lk {
    display: inline-flex;
    align-items: center;
    gap: 0.2rem;
    font-size: 0.78rem;
    color: var(--text-2);
    font-weight: 500;
    text-decoration: none;
    transition: color 0.12s;
  }

  .doc-lk:hover { color: var(--accent); }

  .doc-lk svg {
    width: 0.85em;
    height: 0.85em;
    flex-shrink: 0;
  }

  /* Git info */
  .tk-git {
    display: flex;
    gap: 0.2rem;
    flex-wrap: wrap;
    margin-top: 0.2rem;
  }

  .git-b {
    font-size: 0.62rem;
    padding: 0.1rem 0.35rem;
    border-radius: 2px;
    font-weight: 600;
  }

  .git-b.branch { background: var(--done-soft); color: var(--done); }
  .git-b.commits { background: var(--accent-soft); color: var(--accent); }

  /* Subtasks */
  .subs {
    margin-top: 0.3rem;
    padding-top: 0.25rem;
    border-top: 1px solid color-mix(in srgb, var(--border) 50%, transparent);
  }

  .sub {
    display: flex;
    align-items: flex-start;
    gap: 0.3rem;
    font-size: 0.72rem;
    color: var(--text-2);
    padding: 0.08rem 0;
  }

  .sub .ck {
    width: 12px;
    height: 12px;
    border-radius: 2px;
    border: 1.5px solid var(--border);
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
    font-size: 7px;
    margin-top: 0.2em;
  }

  .sub[data-done="true"] .ck {
    background: var(--done);
    border-color: var(--done);
    color: #fff;
  }

  .sub[data-done="true"] span:last-child {
    text-decoration: line-through;
    opacity: 0.4;
  }

  /* ── Task Modal ── */
  .dw-overlay {
    display: none;
    position: fixed;
    inset: 0;
    background: rgba(44,42,37,0.25);
    z-index: 90;
    justify-content: center;
    align-items: flex-start;
    padding-top: 8vh;
  }

  .dw-overlay.open {
    display: flex;
  }

  .dw {
    width: 580px;
    min-height: 320px;
    max-height: 80vh;
    background: var(--surface);
    border-radius: 10px;
    box-shadow: 0 12px 40px rgba(44,42,37,0.15);
    overflow-y: auto;
    padding: 1.5rem 1.75rem;
    position: relative;
    z-index: 100;
  }

  .dw-x {
    position: absolute;
    top: 0.85rem;
    right: 0.85rem;
    width: 28px;
    height: 28px;
    display: flex;
    align-items: center;
    justify-content: center;
    border: none;
    background: transparent;
    color: var(--text-3);
    font-size: 1.1rem;
    cursor: pointer;
    border-radius: 4px;
    transition: background 0.12s, color 0.12s;
    font-family: var(--font);
  }

  .dw-x:hover {
    background: var(--bg);
    color: var(--text);
  }

  .dw .tk-title {
    font-size: 1rem;
    margin-bottom: 0.5rem;
    padding-right: 2rem;
  }

  .dw .tk-desc {
    display: block !important;
    -webkit-line-clamp: unset !important;
    overflow: visible !important;
    margin-bottom: 0.6rem;
  }

  .dw .tk-meta { margin-bottom: 0.6rem; }

  .dw .subs,
  .dw .tk-docs,
  .dw .tk-git {
    display: flex !important;
  }

  .dw .subs {
    display: block !important;
    margin-top: 0.6rem;
  }

  .dw .tk-docs { margin-top: 0.6rem; }
  .dw .tk-git { margin-top: 0.5rem; }

  .sec-label {
    font-size: 0.65rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.06em;
    color: var(--text-3);
    margin-top: 1rem;
    margin-bottom: 0.35rem;
  }

  /* ── Cautions ── */
  .caution-list {
    columns: 3;
    column-gap: 0.6rem;
  }

  .ctn {
    padding: 0.65rem 0.75rem;
    border-radius: var(--radius);
    background: var(--surface);
    border: 1px solid var(--border);
    transition: box-shadow 0.12s;
    break-inside: avoid;
    margin-bottom: 0.6rem;
  }

  .ctn:hover {
    box-shadow: 0 2px 8px rgba(44,42,37,0.06);
  }

  .ctn-head {
    display: flex;
    align-items: center;
    gap: 0.3rem;
    margin-bottom: 0.15rem;
  }

  .ctn-id {
    font-size: 0.7rem;
    font-weight: 700;
    color: var(--text-3);
    cursor: pointer;
    border-radius: 2px;
    padding: 0.02rem 0.12rem;
    margin: -0.02rem -0.12rem;
    transition: background 0.12s, color 0.12s;
  }

  .ctn-id:hover { background: var(--accent); color: #fff; }
  .ctn-id.copied { background: var(--done); color: #fff; }

  .ctn-title {
    font-size: 0.88rem;
    font-weight: 600;
    line-height: 1.45;
    margin-bottom: 0.15rem;
  }

  .ctn-field {
    font-size: 0.78rem;
    line-height: 1.55;
    color: var(--text-2);
    margin-bottom: 0.1rem;
  }

  .ctn-field strong {
    color: var(--text);
    font-weight: 600;
    margin-right: 0.15rem;
  }

  .ctn-tags {
    display: flex;
    gap: 0.2rem;
    flex-wrap: wrap;
    margin-top: 0.2rem;
  }

  .ctn-tag {
    font-size: 0.62rem;
    padding: 0.03rem 0.25rem;
    border-radius: 2px;
    background: #fbe5a0;
    color: #7c3a06;
    font-weight: 500;
  }

  .ctn-meta {
    display: flex;
    gap: 0.35rem;
    margin-top: 0.2rem;
    font-size: 0.65rem;
    color: var(--text-3);
  }

  .empty {
    text-align: center;
    padding: 1.25rem;
    color: var(--text-3);
    font-size: 0.8rem;
  }

  /* Entrance */
  @keyframes up {
    from { opacity: 0; transform: translateY(6px); }
    to { opacity: 1; transform: translateY(0); }
  }

  .tk { animation: up 0.25s cubic-bezier(0.16,1,0.3,1) both; }

  @media (max-width: 768px) {
    body { padding: 0.75rem; }
    .board { grid-template-columns: 1fr; }
    .dw { width: 95vw; min-height: auto; }
  }
</style>
</head>
<body>

<header>
  <h1>Rime</h1>
  <span class="live-dot __LIVE_CLASS__"></span>
  <div class="phase-wrap">
    <span class="phase-badge" id="pbadge"></span>
    <div class="phase-drop" id="pdrop"></div>
  </div>
  <nav class="tabs" id="tabs">
    <div class="tab active" data-tab="tasks">Tasks<span class="cnt" id="cnt-tasks"></span></div>
    <div class="tab" data-tab="cautions">Cautions<span class="cnt" id="cnt-cautions"></span></div>
  </nav>
  <span class="meta" id="ts"></span>
</header>

<div class="dw-overlay" id="dw-overlay">
  <div class="dw" id="dw">
    <button class="dw-x" id="dw-x">\u00d7</button>
    <div id="dw-body"></div>
  </div>
</div>

<div class="tab-panel active" data-panel="tasks">
  <div class="filters" id="filters"></div>
  <section class="board" id="board">
    <div class="col" data-status="todo">
      <div class="col-h"><span class="dot"></span>Todo<span class="n" id="n-todo">0</span></div>
      <div class="col-b" id="col-todo"></div>
    </div>
    <div class="col" data-status="doing">
      <div class="col-h"><span class="dot"></span>Doing<span class="n" id="n-doing">0</span></div>
      <div class="col-b" id="col-doing"></div>
    </div>
    <div class="col" data-status="done">
      <div class="col-h"><span class="dot"></span>Done<span class="n" id="n-done">0</span></div>
      <div class="col-b" id="col-done"></div>
    </div>
  </section>
</div>

<div class="tab-panel" data-panel="cautions">
  <div class="caution-list" id="caution-list"></div>
</div>

<script>
const TASKS = __TASKS_DATA__;
const PHASE = __PHASE_DATA__;
const CAUTIONS = __CAUTIONS_DATA__;

document.getElementById('ts').textContent = new Date().toLocaleString('ja-JP');

if (__WATCH_MODE__) {
  ${reloadScript}
}

// Tabs
document.querySelectorAll('.tab').forEach(tab => {
  tab.addEventListener('click', () => {
    document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
    document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
    tab.classList.add('active');
    document.querySelector(\`[data-panel="\${tab.dataset.tab}"]\`).classList.add('active');
  });
});

// Phase
const phases = PHASE.phases || [];
const cur = phases.find(p => p.status === 'active') || phases[phases.length - 1];
const pB = document.getElementById('pbadge');
const pD = document.getElementById('pdrop');

if (cur) {
  pB.innerHTML = \`<span class="id">\${cur.id}</span><span class="name">\${cur.name}</span>\`;
} else {
  pB.parentElement.style.display = 'none';
}

phases.forEach(p => {
  const d = p.completedAt || p.startedAt || '';
  pD.innerHTML += \`<div class="ph-item" data-status="\${p.status}">
    <span class="dot"></span><span class="ph-id">\${p.id}</span><span>\${p.name}</span>
    \${d ? \`<span class="ph-date">\${d}</span>\` : ''}</div>\`;
});

pB.addEventListener('click', e => { e.stopPropagation(); pD.classList.toggle('open'); });
document.addEventListener('click', () => pD.classList.remove('open'));

// Labels
const DL = { small: 'S', medium: 'M', large: 'L' };
const PL = { high: 'High', medium: 'Med', low: 'Low' };

const items = TASKS.items || [];

// Filters
const aPhases = [...new Set(items.map(t => t.phase).filter(Boolean))].sort();
const aPrio = ['high','medium','low'].filter(p => items.some(t => t.priority === p));
const aDiff = ['small','medium','large'].filter(d => items.some(t => t.difficulty === d));
const aMods = [...new Set(items.map(t => t.module).filter(Boolean))].sort();

const flt = { phase: null, priority: null, difficulty: null, module: null };

function buildFilters() {
  const el = document.getElementById('filters');
  let h = '';
  const grp = (label, key, vals, fn) => {
    if (!vals.length) return '';
    let s = \`<div class="fg"><span class="fl">\${label}</span>\`;
    s += vals.map(v => \`<button class="fb" data-key="\${key}" data-value="\${v}">\${fn ? fn(v) : v}</button>\`).join('');
    s += '</div><div class="fsep"></div>';
    return s;
  };
  h += grp('Phase', 'phase', aPhases);
  h += grp('Module', 'module', aMods);
  h += grp('Priority', 'priority', aPrio, v => PL[v] || v);
  h += grp('Difficulty', 'difficulty', aDiff, v => DL[v] || v);
  h = h.replace(/<div class="fsep"><\\/div>$/, '');
  el.innerHTML = h;

  el.querySelectorAll('.fb').forEach(btn => {
    btn.addEventListener('click', () => {
      const k = btn.dataset.key, v = btn.dataset.value;
      if (flt[k] === v) { flt[k] = null; btn.classList.remove('on'); }
      else {
        el.querySelectorAll(\`[data-key="\${k}"]\`).forEach(b => b.classList.remove('on'));
        flt[k] = v; btn.classList.add('on');
      }
      renderTasks();
    });
  });
}

function renderTasks() {
  const f = items.filter(t => {
    if (flt.phase && t.phase !== flt.phase) return false;
    if (flt.priority && t.priority !== flt.priority) return false;
    if (flt.difficulty && t.difficulty !== flt.difficulty) return false;
    if (flt.module && t.module !== flt.module) return false;
    return true;
  });

  const g = { todo: [], doing: [], done: [] };
  f.forEach(t => { const s = t.status || 'todo'; if (g[s]) g[s].push(t); });

  document.getElementById('cnt-tasks').textContent = f.length;

  Object.entries(g).forEach(([status, tasks]) => {
    document.getElementById(\`n-\${status}\`).textContent = tasks.length;
    const col = document.getElementById(\`col-\${status}\`);

    if (!tasks.length) { col.innerHTML = '<div class="empty">\u2014</div>'; return; }

    col.innerHTML = tasks.map((t, i) => {
      const docs = (t.docs && t.docs.length)
        ? \`<div class="tk-docs">\${t.docs.map(d =>
            \`<a class="doc-lk" href="/file/\${encodeURIComponent(d.path)}" target="_blank"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M10 6V8H5V19H16V14H18V20C18 20.5523 17.5523 21 17 21H4C3.44772 21 3 20.5523 3 20V7C3 6.44772 3.44772 6 4 6H10ZM21 3V11H19L18.9999 6.413L11.2071 14.2071L9.79289 12.7929L17.5849 5H13V3H21Z"></path></svg>\${d.type === 'spec' ? 'design spec' : d.type === 'plan' ? 'implementation plan' : d.type || 'doc'}</a>\`
          ).join('')}</div>\` : '';

      const git = (t.branch || t.commits)
        ? \`<div class="tk-git">
            \${t.branch ? \`<span class="git-b branch">\${t.branch}</span>\` : ''}
            \${t.commits ? \`<span class="git-b commits">\${t.commits.from.slice(0,7)}\u2192\${t.commits.to.slice(0,7)}</span>\` : ''}
          </div>\` : '';

      const subs = (t.subtasks && t.subtasks.length)
        ? \`<div class="subs">\${t.subtasks.map(s =>
            \`<div class="sub" data-done="\${s.status === 'done'}">
              <span class="ck">\${s.status === 'done' ? '\u2713' : ''}</span>
              <span>\${s.title}</span></div>\`
          ).join('')}</div>\` : '';

      return \`<div class="tk" data-task-id="\${t.id}" style="animation-delay:\${i * 25}ms">
        <div class="tk-head">
          <span class="tk-id">\${t.id}</span>
          \${t.module ? \`<span class="tk-mod">\${t.module}</span>\` : ''}
          \${t.phase ? \`<span class="tk-ph">\${t.phase}</span>\` : ''}
        </div>
        <div class="tk-title">\${t.title}</div>
        \${t.description ? \`<div class="tk-desc">\${t.description}</div>\` : ''}
        <div class="tk-meta">
          \${t.priority ? \`<span class="badge \${t.priority}"><span class="dot"></span>\${PL[t.priority] || t.priority}</span>\` : ''}
          \${t.difficulty ? \`<span class="diff \${t.difficulty}">\${DL[t.difficulty] || t.difficulty}</span>\` : ''}
          \${t.createdAt ? \`<span class="tk-date">\${t.createdAt}</span>\` : ''}
        </div>
        \${git}\${subs}\${docs}
      </div>\`;
    }).join('');
  });
}

buildFilters();
renderTasks();

// Copy ID
function copyId(el) {
  const id = el.textContent.trim();
  navigator.clipboard.writeText(id).then(() => {
    el.classList.add('copied');
    const orig = el.textContent;
    el.textContent = '\u2713';
    setTimeout(() => { el.textContent = orig; el.classList.remove('copied'); }, 600);
  });
}

document.addEventListener('click', e => {
  if (e.target.classList.contains('tk-id') || e.target.classList.contains('ctn-id')) copyId(e.target);
});

// Drawer
const dwOverlay = document.getElementById('dw-overlay');
const dw = document.getElementById('dw');
const dwBody = document.getElementById('dw-body');

function openDw(taskId) {
  const t = items.find(x => x.id === taskId);
  if (!t) return;

  const subs = (t.subtasks && t.subtasks.length)
    ? \`<div class="sec-label">Subtasks</div>
       <div class="subs">\${t.subtasks.map(s =>
        \`<div class="sub" data-done="\${s.status === 'done'}">
          <span class="ck">\${s.status === 'done' ? '\u2713' : ''}</span>
          <span>\${s.title}</span></div>\`
      ).join('')}</div>\` : '';

  const docs = (t.docs && t.docs.length)
    ? \`<div class="sec-label">Documents</div>
       <div class="tk-docs">\${t.docs.map(d =>
        \`<a class="doc-lk" href="/file/\${encodeURIComponent(d.path)}" target="_blank"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M10 6V8H5V19H16V14H18V20C18 20.5523 17.5523 21 17 21H4C3.44772 21 3 20.5523 3 20V7C3 6.44772 3.44772 6 4 6H10ZM21 3V11H19L18.9999 6.413L11.2071 14.2071L9.79289 12.7929L17.5849 5H13V3H21Z"></path></svg>\${d.type === 'spec' ? 'design spec' : d.type === 'plan' ? 'implementation plan' : d.type || 'doc'}</a>\`
      ).join('')}</div>\` : '';

  const git = (t.branch || t.commits)
    ? \`<div class="sec-label">Git</div>
       <div class="tk-git">
         \${t.branch ? \`<span class="git-b branch">\${t.branch}</span>\` : ''}
         \${t.commits ? \`<span class="git-b commits">\${t.commits.from.slice(0,7)} \u2192 \${t.commits.to.slice(0,7)}</span>\` : ''}
       </div>\` : '';

  dwBody.innerHTML = \`
    <div class="tk-head">
      <span class="tk-id">\${t.id}</span>
      \${t.module ? \`<span class="tk-mod">\${t.module}</span>\` : ''}
      \${t.phase ? \`<span class="tk-ph">\${t.phase}</span>\` : ''}
    </div>
    <div class="tk-title">\${t.title}</div>
    \${t.description ? \`<div class="tk-desc">\${t.description}</div>\` : ''}
    <div class="tk-meta">
      \${t.priority ? \`<span class="badge \${t.priority}"><span class="dot"></span>\${PL[t.priority] || t.priority}</span>\` : ''}
      \${t.difficulty ? \`<span class="diff \${t.difficulty}">\${DL[t.difficulty] || t.difficulty}</span>\` : ''}
      \${t.completedAt ? \`<span class="tk-date">Completed \${t.completedAt}</span>\` : t.createdAt ? \`<span class="tk-date">\${t.createdAt}</span>\` : ''}
    </div>
    \${docs}\${git}\${subs}
  \`;

  dwOverlay.classList.add('open');
  dw.classList.add('open');
}

function closeDw() {
  dwOverlay.classList.remove('open');
  dw.classList.remove('open');
}

dwOverlay.addEventListener('click', e => { if (e.target === dwOverlay) closeDw(); });
document.getElementById('dw-x').addEventListener('click', closeDw);
document.addEventListener('keydown', e => { if (e.key === 'Escape') closeDw(); });

document.addEventListener('click', e => {
  const card = e.target.closest('.tk');
  if (!card) return;
  if (e.target.closest('a') || e.target.classList.contains('tk-id')) return;
  const col = card.closest('.col');
  if (!col) return;
  if (col.dataset.status === 'todo' || col.dataset.status === 'done') openDw(card.dataset.taskId);
});

// Cautions
document.getElementById('cnt-cautions').textContent = CAUTIONS.length || 0;
const cList = document.getElementById('caution-list');

if (!CAUTIONS.length) {
  cList.innerHTML = '<div class="empty">\u2014</div>';
} else {
  CAUTIONS.forEach(c => {
    const title = c.title || c.summary || '';
    const summary = c.title ? (c.summary || '') : '';
    cList.innerHTML += \`<div class="ctn">
      <div class="ctn-head">
        <span class="ctn-id">\${c.id || ''}</span>
        \${c.module ? \`<span class="tk-mod">\${c.module}</span>\` : ''}
      </div>
      <div class="ctn-title">\${title}</div>
      \${summary ? \`<div class="ctn-field"><strong>Summary</strong>\${summary}</div>\` : ''}
      \${c.solution ? \`<div class="ctn-field"><strong>Solution</strong>\${c.solution}</div>\` : ''}
      \${c.reference ? \`<div class="ctn-field"><strong>Ref</strong>\${c.reference}</div>\` : ''}
      \${(c.tags && c.tags.length) ? \`<div class="ctn-tags">\${c.tags.map(t => \`<span class="ctn-tag">\${t}</span>\`).join('')}</div>\` : ''}
      <div class="ctn-meta">
        \${c.createdAt || c.discoveredAt ? \`<span>\${c.createdAt || c.discoveredAt}</span>\` : ''}
        \${c.source ? \`<span>\${c.source}</span>\` : ''}
      </div>
    </div>\`;
  });
}
</script>
</body>
</html>`

  return html
    .replace('__TASKS_DATA__', () => tasksJson)
    .replace('__PHASE_DATA__', () => phaseJson)
    .replace('__CAUTIONS_DATA__', () => cautionsJson)
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

// Lightweight markdown → HTML renderer
function esc(s) {
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
}

function renderMarkdown(src) {
  const lines = src.split('\n')
  let out = ''
  let inCode = false
  let inTable = false
  let inList = false
  let codeLang = ''

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i]

    // 代码块
    if (line.startsWith('```')) {
      if (!inCode) {
        if (inList) { out += '</ul>'; inList = false }
        if (inTable) { out += '</table>'; inTable = false }
        codeLang = esc(line.slice(3).trim())
        out += `<div class="code-block">${codeLang ? `<span class="code-lang">${codeLang}</span>` : ''}<pre><code>`
        inCode = true
      } else {
        out += '</code></pre></div>'
        inCode = false
      }
      continue
    }

    if (inCode) {
      out += esc(line) + '\n'
      continue
    }

    // 空行
    if (line.trim() === '') {
      if (inList) { out += '</ul>'; inList = false }
      if (inTable) { out += '</table>'; inTable = false }
      continue
    }

    // 标题
    const hMatch = line.match(/^(#{1,6})\s+(.+)/)
    if (hMatch) {
      if (inList) { out += '</ul>'; inList = false }
      if (inTable) { out += '</table>'; inTable = false }
      const level = hMatch[1].length
      out += `<h${level}>${inlineFormat(esc(hMatch[2]))}</h${level}>`
      continue
    }

    // 水平线
    if (/^-{3,}$/.test(line.trim()) || /^\*{3,}$/.test(line.trim())) {
      if (inList) { out += '</ul>'; inList = false }
      if (inTable) { out += '</table>'; inTable = false }
      out += '<hr>'
      continue
    }

    // 表格
    if (line.includes('|') && line.trim().startsWith('|')) {
      const cells = line.split('|').slice(1, -1).map(c => c.trim())
      // 分隔行跳过
      if (cells.every(c => /^[-:]+$/.test(c))) continue
      if (!inTable) {
        if (inList) { out += '</ul>'; inList = false }
        out += '<table>'
        // 判断是否是表头（下一行是分隔行）
        const next = lines[i + 1] || ''
        const isHeader = next.includes('|') && next.split('|').slice(1, -1).every(c => /^[-:\s]+$/.test(c.trim()))
        const tag = isHeader ? 'th' : 'td'
        out += `<tr>${cells.map(c => `<${tag}>${inlineFormat(esc(c))}</${tag}>`).join('')}</tr>`
        inTable = true
      } else {
        out += `<tr>${cells.map(c => `<td>${inlineFormat(esc(c))}</td>`).join('')}</tr>`
      }
      continue
    }

    if (inTable && !line.includes('|')) {
      out += '</table>'
      inTable = false
    }

    // 列表
    const listMatch = line.match(/^(\s*)[-*]\s+(.+)/)
    if (listMatch) {
      if (!inList) { out += '<ul>'; inList = true }
      out += `<li>${inlineFormat(esc(listMatch[2]))}</li>`
      continue
    }

    // 引用
    if (line.startsWith('>')) {
      if (inList) { out += '</ul>'; inList = false }
      out += `<blockquote>${inlineFormat(esc(line.replace(/^>\s*/, '')))}</blockquote>`
      continue
    }

    // 段落
    if (inList) { out += '</ul>'; inList = false }
    out += `<p>${inlineFormat(esc(line))}</p>`
  }

  if (inCode) out += '</code></pre></div>'
  if (inList) out += '</ul>'
  if (inTable) out += '</table>'
  return out
}

function inlineFormat(s) {
  return s
    .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
    .replace(/`([^`]+)`/g, '<code class="inline">$1</code>')
    .replace(/\[([^\]]+)\]\([^)]+\)/g, '$1')
}

function fileViewerHtml(fileName, relPath, content) {
  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>${fileName}</title>
<style>
  @font-face {
    font-family: 'Cascadia Code';
    src: local('Cascadia Code'), local('CascadiaCode-Regular');
  }

  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

  :root {
    --bg: #fafaf9;
    --surface: #fff;
    --text: #1c1917;
    --text-2: #78716c;
    --text-3: #a8a29e;
    --border: #e7e5e4;
    --accent: #3b82f6;
    --code-bg: #f5f5f4;
    --font: 'Cascadia Code', 'SF Mono', ui-monospace, monospace;
  }

  body {
    font-family: var(--font);
    -webkit-font-smoothing: antialiased;
    background: var(--bg);
    color: var(--text);
    font-size: 13px;
    line-height: 1.75;
  }

  .viewer {
    max-width: 780px;
    margin: 0 auto;
    padding: 3rem 2rem 6rem;
  }

  .breadcrumb {
    font-size: 11px;
    color: var(--text-3);
    letter-spacing: 0.02em;
    margin-bottom: 2.5rem;
    padding-bottom: 1rem;
    border-bottom: 1px solid var(--border);
  }

  .breadcrumb span { color: var(--text-2); }

  /* Typography */
  h1 {
    font-size: 1.5rem;
    font-weight: 600;
    letter-spacing: -0.03em;
    line-height: 1.3;
    margin: 2.5rem 0 1rem;
    color: var(--text);
  }

  h1:first-child { margin-top: 0; }

  h2 {
    font-size: 1.1rem;
    font-weight: 600;
    letter-spacing: -0.02em;
    line-height: 1.4;
    margin: 2.5rem 0 0.75rem;
    padding-top: 1.5rem;
    border-top: 1px solid var(--border);
  }

  h3 {
    font-size: 0.95rem;
    font-weight: 600;
    line-height: 1.4;
    margin: 2rem 0 0.5rem;
    color: var(--text);
  }

  h4, h5, h6 {
    font-size: 0.85rem;
    font-weight: 600;
    margin: 1.5rem 0 0.4rem;
    color: var(--text-2);
    text-transform: uppercase;
    letter-spacing: 0.04em;
  }

  p {
    margin: 0.5rem 0;
    color: var(--text);
  }

  strong { font-weight: 600; }

  hr {
    border: none;
    height: 1px;
    background: var(--border);
    margin: 2rem 0;
  }

  /* Lists */
  ul {
    margin: 0.5rem 0;
    padding-left: 1.25rem;
    list-style: none;
  }

  li {
    position: relative;
    margin: 0.25rem 0;
    padding-left: 0.25rem;
  }

  li::before {
    content: '\u00b7';
    position: absolute;
    left: -1rem;
    color: var(--text-3);
    font-weight: 700;
  }

  /* Code */
  code.inline {
    font-family: var(--font);
    font-size: 0.92em;
    background: var(--code-bg);
    padding: 0.1rem 0.35rem;
    border-radius: 3px;
    color: #b45309;
  }

  .code-block {
    position: relative;
    margin: 1rem 0;
    background: var(--code-bg);
    border-radius: 6px;
    border: 1px solid var(--border);
  }

  .code-block .code-lang {
    position: absolute;
    top: 0;
    right: 0;
    font-size: 10px;
    color: var(--text-3);
    padding: 0.35rem 0.6rem;
    letter-spacing: 0.03em;
    text-transform: uppercase;
  }

  .code-block pre {
    padding: 1rem 1.25rem;
    overflow-x: auto;
    font-size: 12px;
    line-height: 1.6;
  }

  .code-block code {
    font-family: var(--font);
  }

  /* Tables */
  table {
    width: 100%;
    border-collapse: collapse;
    margin: 1rem 0;
    font-size: 12px;
  }

  th {
    text-align: left;
    font-weight: 600;
    padding: 0.5rem 0.75rem;
    border-bottom: 2px solid var(--border);
    color: var(--text-2);
    font-size: 11px;
    text-transform: uppercase;
    letter-spacing: 0.04em;
  }

  td {
    padding: 0.45rem 0.75rem;
    border-bottom: 1px solid var(--border);
    vertical-align: top;
  }

  tr:last-child td { border-bottom: none; }

  /* Blockquote */
  blockquote {
    margin: 1rem 0;
    padding: 0.5rem 1rem;
    border-left: 3px solid var(--accent);
    color: var(--text-2);
    background: #f8fafc;
    border-radius: 0 4px 4px 0;
  }
</style>
</head>
<body>
<div class="viewer">
  <div class="breadcrumb">${relPath.split('/').slice(0, -1).join(' / ')} / <span>${fileName}</span></div>
  ${content}
</div>
</body>
</html>`
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
      const raw = readFileSync(filePath, 'utf8')
      const fileName = relPath.split('/').pop()
      const rendered = renderMarkdown(raw)
      res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' })
      res.end(fileViewerHtml(fileName, relPath, rendered))
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
