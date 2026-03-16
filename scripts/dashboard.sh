#!/bin/bash
# .rime/ dashboard — 生成本地 HTML 并在浏览器打开
# Usage:
#   bash dashboard.sh              一次性生成并打开
#   bash dashboard.sh --watch      监听文件变化，自动刷新
set -euo pipefail

RIME_DIR=".rime"
OUT="/tmp/rime-dashboard.html"
WATCH=false

for arg in "$@"; do
  case "$arg" in
    --watch|-w) WATCH=true ;;
    *) RIME_DIR="$arg" ;;
  esac
done

if [ ! -d "$RIME_DIR" ]; then
  echo "Error: $RIME_DIR not found" >&2
  exit 1
fi

generate() {
cat > "$OUT" <<'HTMLEOF'
<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Rime Dashboard</title>
<style>
  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

  :root {
    --bg: #f5f6f8;
    --surface: #fff;
    --border: #e2e6ea;
    --text: #1a1d21;
    --text-secondary: #6b7280;
    --accent: #3b82f6;
    --done: #10b981;
    --doing: #f59e0b;
    --todo: #94a3b8;
    --high: #ef4444;
    --medium: #d97706;
    --low: #6b7280;
    --radius: 8px;
    --font-sans: "Inter", "PingFang SC", "Hiragino Sans", system-ui, sans-serif;
    --font-mono: "SF Mono", "Cascadia Code", ui-monospace, monospace;
  }

  body {
    font-family: var(--font-sans);
    font-feature-settings: "cv02", "cv03", "cv04", "cv11";
    -webkit-font-smoothing: antialiased;
    background: var(--bg);
    color: var(--text);
    line-height: 1.6;
    padding: 2rem;
    max-width: 1280px;
    margin: 0 auto;
  }

  /* Header */
  header {
    display: flex;
    align-items: center;
    gap: 0.75rem;
    margin-bottom: 1.5rem;
  }

  header h1 {
    font-size: 1.15rem;
    font-weight: 650;
    letter-spacing: -0.02em;
  }

  header .meta {
    font-size: 0.75rem;
    color: var(--text-secondary);
    margin-left: auto;
  }

  .live-badge {
    font-size: 0.65rem;
    padding: 0.2rem 0.55rem;
    border-radius: 999px;
    background: #ecfdf5;
    color: var(--done);
    font-weight: 550;
    display: none;
  }

  .live-badge.active {
    display: inline-flex;
    align-items: center;
    gap: 0.35rem;
  }

  .live-badge .pulse {
    width: 6px;
    height: 6px;
    border-radius: 50%;
    background: var(--done);
    animation: pulse 2s ease-in-out infinite;
  }

  @keyframes pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.3; }
  }

  /* Tabs */
  .tabs {
    display: flex;
    gap: 0;
    margin-bottom: 1.5rem;
    border-bottom: 1px solid var(--border);
  }

  .tab {
    padding: 0.5rem 1rem;
    font-size: 0.8rem;
    font-weight: 550;
    color: var(--text-secondary);
    cursor: pointer;
    border-bottom: 2px solid transparent;
    margin-bottom: -1px;
    transition: color 0.15s, border-color 0.15s;
    user-select: none;
  }

  .tab:hover {
    color: var(--text);
  }

  .tab.active {
    color: var(--text);
    border-bottom-color: var(--text);
  }

  .tab .tab-count {
    font-size: 0.7rem;
    font-weight: 500;
    color: var(--text-secondary);
    margin-left: 0.35rem;
  }

  .tab-panel {
    display: none;
  }

  .tab-panel.active {
    display: block;
  }

  /* Phase badge in header */
  .phase-badge {
    display: inline-flex;
    align-items: center;
    gap: 0.35rem;
    padding: 0.2rem 0.6rem;
    background: #eff6ff;
    border: 1px solid var(--accent);
    border-radius: 5px;
    font-size: 0.75rem;
    cursor: pointer;
    transition: box-shadow 0.12s;
  }

  .phase-badge:hover {
    box-shadow: 0 1px 4px rgba(59,130,246,0.15);
  }

  .phase-badge .dot {
    width: 7px;
    height: 7px;
    border-radius: 50%;
    background: var(--accent);
    flex-shrink: 0;
  }

  .phase-badge .id {
    font-weight: 600;
    font-family: var(--font-mono);
    font-size: 0.7rem;
    color: var(--accent);
  }

  .phase-badge .name {
    color: var(--text);
  }

  /* Phase modal */
  .modal-overlay {
    display: none;
    position: fixed;
    inset: 0;
    background: rgba(0,0,0,0.3);
    z-index: 100;
    justify-content: center;
    align-items: center;
  }

  .modal-overlay.open {
    display: flex;
  }

  .modal {
    background: var(--surface);
    border-radius: 10px;
    padding: 1.25rem 1.5rem;
    min-width: 320px;
    max-width: 480px;
    box-shadow: 0 8px 30px rgba(0,0,0,0.12);
  }

  .modal h2 {
    font-size: 0.9rem;
    font-weight: 600;
    margin-bottom: 0.85rem;
  }

  .modal-phase {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.5rem 0;
    border-bottom: 1px solid var(--border);
    font-size: 0.8rem;
  }

  .modal-phase:last-child {
    border-bottom: none;
  }

  .modal-phase .dot {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    flex-shrink: 0;
  }

  .modal-phase[data-status="active"] .dot { background: var(--accent); }
  .modal-phase[data-status="done"] .dot { background: var(--done); }

  .modal-phase .id {
    font-weight: 600;
    font-family: var(--font-mono);
    font-size: 0.7rem;
    color: var(--text-secondary);
  }

  .modal-phase .date {
    font-size: 0.7rem;
    color: var(--text-secondary);
    margin-left: auto;
  }

  .modal-phase[data-status="done"] {
    opacity: 0.6;
  }

  /* Board */
  .board {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 1rem;
  }

  .column {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    overflow: hidden;
  }

  .column-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0.6rem 0.85rem;
    border-bottom: 1px solid var(--border);
    font-size: 0.75rem;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.04em;
    color: var(--text-secondary);
  }

  .column-header .count {
    background: var(--bg);
    padding: 0.1rem 0.45rem;
    border-radius: 999px;
    font-size: 0.7rem;
    font-weight: 550;
  }

  .column-body {
    padding: 0.5rem;
    min-height: 60px;
    max-height: 70vh;
    overflow-y: auto;
  }

  /* Task card */
  .task {
    padding: 0.65rem 0.75rem;
    border-radius: 6px;
    border: 1px solid var(--border);
    margin-bottom: 0.4rem;
    background: var(--surface);
    transition: box-shadow 0.15s;
  }

  .column[data-status="done"] .task {
    background: var(--bg);
    opacity: 0.7;
  }

  .task:hover {
    box-shadow: 0 1px 4px rgba(0,0,0,0.06);
  }

  .task:last-child {
    margin-bottom: 0;
  }

  .task-header {
    display: flex;
    align-items: center;
    gap: 0.4rem;
    margin-bottom: 0.2rem;
    flex-wrap: wrap;
  }

  .task-id {
    font-size: 0.65rem;
    font-weight: 600;
    color: var(--text-secondary);
    font-family: var(--font-mono);
  }

  .task-module {
    font-size: 0.6rem;
    padding: 0.1rem 0.35rem;
    border-radius: 3px;
    background: #e0e7ff;
    color: #4338ca;
    font-weight: 550;
  }

  .task-phase {
    font-size: 0.6rem;
    padding: 0.1rem 0.3rem;
    border-radius: 3px;
    background: var(--border);
    color: var(--text-secondary);
    font-family: var(--font-mono);
  }

  .task-title {
    font-size: 0.85rem;
    font-weight: 550;
    line-height: 1.4;
    margin-bottom: 0.15rem;
  }

  .task-description {
    font-size: 0.75rem;
    color: var(--text-secondary);
    line-height: 1.45;
    margin-bottom: 0.3rem;
  }

  .task-meta {
    display: flex;
    align-items: center;
    gap: 0.4rem;
    flex-wrap: wrap;
  }

  .badge {
    display: inline-flex;
    align-items: center;
    gap: 0.25rem;
    padding: 0.1rem 0.4rem;
    border-radius: 3px;
    font-size: 0.65rem;
    font-weight: 550;
    line-height: 1.4;
  }

  .badge .dot {
    width: 6px;
    height: 6px;
    border-radius: 50%;
    flex-shrink: 0;
  }

  .badge.high { background: #fef2f2; color: var(--high); }
  .badge.high .dot { background: var(--high); }
  .badge.medium { background: #fffbeb; color: var(--medium); }
  .badge.medium .dot { background: var(--medium); }
  .badge.low { background: #f3f4f6; color: var(--low); }
  .badge.low .dot { background: var(--low); }

  .difficulty {
    font-size: 0.65rem;
    font-weight: 550;
    padding: 0.1rem 0.4rem;
    border-radius: 3px;
    line-height: 1.4;
  }

  .difficulty.small { background: #ecfdf5; color: #059669; }
  .difficulty.medium { background: #fffbeb; color: #d97706; }
  .difficulty.large { background: #fef2f2; color: #dc2626; }

  .task-date {
    font-size: 0.65rem;
    color: var(--text-secondary);
    margin-left: auto;
  }

  /* Filters */
  .filters {
    display: flex;
    gap: 0.5rem;
    margin-bottom: 1rem;
    flex-wrap: wrap;
    align-items: center;
  }

  .filter-group {
    display: flex;
    align-items: center;
    gap: 0.25rem;
  }

  .filter-label {
    font-size: 0.7rem;
    color: var(--text-secondary);
    font-weight: 550;
    margin-right: 0.15rem;
  }

  .filter-btn {
    font-size: 0.65rem;
    padding: 0.2rem 0.45rem;
    border-radius: 4px;
    border: 1px solid var(--border);
    background: var(--surface);
    color: var(--text-secondary);
    cursor: pointer;
    font-weight: 500;
    font-family: var(--font-sans);
    transition: all 0.12s;
  }

  .filter-btn:hover {
    border-color: var(--text-secondary);
  }

  .filter-btn.active {
    background: var(--text);
    color: var(--surface);
    border-color: var(--text);
  }

  .filter-sep {
    width: 1px;
    height: 16px;
    background: var(--border);
    margin: 0 0.15rem;
  }

  /* Subtasks */
  .subtasks {
    margin-top: 0.4rem;
    padding-top: 0.4rem;
    border-top: 1px dashed var(--border);
  }

  .subtask {
    display: flex;
    align-items: center;
    gap: 0.35rem;
    font-size: 0.7rem;
    color: var(--text-secondary);
    padding: 0.12rem 0;
  }

  .subtask .check {
    width: 13px;
    height: 13px;
    border-radius: 3px;
    border: 1.5px solid var(--border);
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
    font-size: 0.55rem;
  }

  .subtask[data-done="true"] .check {
    background: var(--done);
    border-color: var(--done);
    color: #fff;
  }

  .subtask[data-done="true"] span {
    text-decoration: line-through;
    opacity: 0.55;
  }

  /* Cautions */
  .caution-list {
    display: grid;
    gap: 0.75rem;
  }

  .caution-card {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    padding: 0.85rem 1rem;
  }

  .caution-card:hover {
    box-shadow: 0 1px 4px rgba(0,0,0,0.06);
  }

  .caution-header {
    display: flex;
    align-items: center;
    gap: 0.4rem;
    margin-bottom: 0.3rem;
    flex-wrap: wrap;
  }

  .caution-id {
    font-size: 0.65rem;
    font-weight: 600;
    color: var(--text-secondary);
    font-family: var(--font-mono);
  }

  .caution-title {
    font-size: 0.85rem;
    font-weight: 550;
    line-height: 1.4;
    margin-bottom: 0.3rem;
  }

  .caution-field {
    font-size: 0.75rem;
    line-height: 1.5;
    color: var(--text-secondary);
    margin-bottom: 0.25rem;
  }

  .caution-field strong {
    color: var(--text);
    font-weight: 550;
    margin-right: 0.25rem;
  }

  .caution-tags {
    display: flex;
    gap: 0.3rem;
    flex-wrap: wrap;
    margin-top: 0.35rem;
  }

  .caution-tag {
    font-size: 0.6rem;
    padding: 0.1rem 0.35rem;
    border-radius: 3px;
    background: #fef3c7;
    color: #92400e;
    font-weight: 500;
  }

  .caution-meta {
    display: flex;
    gap: 0.5rem;
    margin-top: 0.35rem;
    font-size: 0.65rem;
    color: var(--text-secondary);
  }

  .empty {
    text-align: center;
    padding: 2rem;
    color: var(--text-secondary);
    font-size: 0.8rem;
  }

  @media (max-width: 768px) {
    body { padding: 1rem; }
    .board { grid-template-columns: 1fr; }
  }
</style>
</head>
<body>

<header>
  <h1>Rime Dashboard</h1>
  <span class="live-badge __LIVE_CLASS__"><span class="pulse"></span>Live</span>
  <span class="phase-badge" id="phase-badge" title="Click to view all phases"></span>
  <span class="meta" id="timestamp"></span>
</header>

<div class="modal-overlay" id="phase-modal">
  <div class="modal">
    <h2>Phases</h2>
    <div id="phase-list"></div>
  </div>
</div>

<nav class="tabs" id="tabs">
  <div class="tab active" data-tab="tasks">Tasks<span class="tab-count" id="tab-count-tasks"></span></div>
  <div class="tab" data-tab="cautions">Cautions<span class="tab-count" id="tab-count-cautions"></span></div>
</nav>

<div class="tab-panel active" data-panel="tasks">
  <div class="filters" id="filters"></div>
  <section class="board" id="board">
    <div class="column" data-status="todo">
      <div class="column-header">Todo <span class="count" id="count-todo">0</span></div>
      <div class="column-body" id="col-todo"></div>
    </div>
    <div class="column" data-status="doing">
      <div class="column-header">Doing <span class="count" id="count-doing">0</span></div>
      <div class="column-body" id="col-doing"></div>
    </div>
    <div class="column" data-status="done">
      <div class="column-header">Done <span class="count" id="count-done">0</span></div>
      <div class="column-body" id="col-done"></div>
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

// Timestamp
document.getElementById('timestamp').textContent =
  'Updated: ' + new Date().toLocaleString('ja-JP');

// Auto-reload in watch mode
if (__WATCH_MODE__) {
  let lastModified = '';
  setInterval(async () => {
    try {
      const res = await fetch(location.href, { method: 'HEAD' });
      const mod = res.headers.get('last-modified') || '';
      if (lastModified && mod !== lastModified) location.reload();
      lastModified = mod;
    } catch {}
  }, 1000);
}

// Tabs
document.querySelectorAll('.tab').forEach(tab => {
  tab.addEventListener('click', () => {
    document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
    document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
    tab.classList.add('active');
    document.querySelector(`[data-panel="${tab.dataset.tab}"]`).classList.add('active');
  });
});

// Phase badge + modal
const phases = PHASE.phases || [];
const current = phases.find(p => p.status === 'active') || phases[phases.length - 1];
const badge = document.getElementById('phase-badge');
if (current) {
  badge.innerHTML = `<span class="dot"></span><span class="id">${current.id}</span><span class="name">${current.name}</span>`;
} else {
  badge.style.display = 'none';
}

const phaseList = document.getElementById('phase-list');
phases.forEach(p => {
  const date = p.completedAt || p.startedAt || '';
  phaseList.innerHTML += `
    <div class="modal-phase" data-status="${p.status}">
      <span class="dot"></span>
      <span class="id">${p.id}</span>
      <span>${p.name}</span>
      ${date ? `<span class="date">${date}</span>` : ''}
    </div>`;
});

const modal = document.getElementById('phase-modal');
badge.addEventListener('click', () => modal.classList.add('open'));
modal.addEventListener('click', e => {
  if (e.target === modal) modal.classList.remove('open');
});

// Labels
const diffLabels = { small: 'S', medium: 'M', large: 'L' };
const prioLabels = { high: 'High', medium: 'Med', low: 'Low' };

// Tasks
const items = TASKS.items || [];

// Collect unique filter values
const allPhases = [...new Set(items.map(t => t.phase).filter(Boolean))].sort();
const allPriorities = ['high', 'medium', 'low'].filter(p => items.some(t => t.priority === p));
const allDifficulties = ['small', 'medium', 'large'].filter(d => items.some(t => t.difficulty === d));
const allModules = [...new Set(items.map(t => t.module).filter(Boolean))].sort();

// Active filters
const filters = { phase: null, priority: null, difficulty: null, module: null };

// Build filter bar
function buildFilters() {
  const el = document.getElementById('filters');
  let html = '';

  const group = (label, key, values, labelFn) => {
    if (values.length === 0) return '';
    let s = `<div class="filter-group"><span class="filter-label">${label}</span>`;
    s += values.map(v =>
      `<button class="filter-btn" data-key="${key}" data-value="${v}">${labelFn ? labelFn(v) : v}</button>`
    ).join('');
    s += '</div><div class="filter-sep"></div>';
    return s;
  };

  html += group('Phase', 'phase', allPhases);
  html += group('Module', 'module', allModules);
  html += group('Priority', 'priority', allPriorities, v => prioLabels[v] || v);
  html += group('Difficulty', 'difficulty', allDifficulties, v => diffLabels[v] || v);

  // Remove trailing separator
  html = html.replace(/<div class="filter-sep"><\/div>$/, '');
  el.innerHTML = html;

  el.querySelectorAll('.filter-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const key = btn.dataset.key;
      const val = btn.dataset.value;
      if (filters[key] === val) {
        filters[key] = null;
        btn.classList.remove('active');
      } else {
        el.querySelectorAll(`[data-key="${key}"]`).forEach(b => b.classList.remove('active'));
        filters[key] = val;
        btn.classList.add('active');
      }
      renderTasks();
    });
  });
}

function renderTasks() {
  const filtered = items.filter(t => {
    if (filters.phase && t.phase !== filters.phase) return false;
    if (filters.priority && t.priority !== filters.priority) return false;
    if (filters.difficulty && t.difficulty !== filters.difficulty) return false;
    if (filters.module && t.module !== filters.module) return false;
    return true;
  });

  const groups = { todo: [], doing: [], done: [] };
  filtered.forEach(t => {
    const s = t.status || 'todo';
    if (groups[s]) groups[s].push(t);
  });

  document.getElementById('tab-count-tasks').textContent = filtered.length;

  Object.entries(groups).forEach(([status, tasks]) => {
    document.getElementById(`count-${status}`).textContent = tasks.length;
    const col = document.getElementById(`col-${status}`);

    if (tasks.length === 0) {
      col.innerHTML = '<div class="empty">No tasks</div>';
      return;
    }

    col.innerHTML = tasks.map(t => {
      const subtasksHtml = (t.subtasks && t.subtasks.length > 0)
        ? `<div class="subtasks">${t.subtasks.map(s =>
            `<div class="subtask" data-done="${s.status === 'done'}">
              <span class="check">${s.status === 'done' ? '✓' : ''}</span>
              <span>${s.title}</span>
            </div>`
          ).join('')}</div>`
        : '';

      return `
        <div class="task">
          <div class="task-header">
            <span class="task-id">${t.id}</span>
            ${t.module ? `<span class="task-module">${t.module}</span>` : ''}
            ${t.phase ? `<span class="task-phase">${t.phase}</span>` : ''}
          </div>
          <div class="task-title">${t.title}</div>
          ${t.description ? `<div class="task-description">${t.description}</div>` : ''}
          <div class="task-meta">
            ${t.priority ? `<span class="badge ${t.priority}"><span class="dot"></span>${prioLabels[t.priority] || t.priority}</span>` : ''}
            ${t.difficulty ? `<span class="difficulty ${t.difficulty}">${diffLabels[t.difficulty] || t.difficulty}</span>` : ''}
            ${t.createdAt ? `<span class="task-date">${t.createdAt}</span>` : ''}
          </div>
          ${subtasksHtml}
        </div>`;
    }).join('');
  });
}

buildFilters();
renderTasks();

// Cautions
document.getElementById('tab-count-cautions').textContent = CAUTIONS.length || 0;
const cautionList = document.getElementById('caution-list');

if (CAUTIONS.length === 0) {
  cautionList.innerHTML = '<div class="empty">No cautions</div>';
} else {
  CAUTIONS.forEach(c => {
    const title = c.title || c.summary || '';
    const summary = c.title ? (c.summary || '') : '';

    cautionList.innerHTML += `
      <div class="caution-card">
        <div class="caution-header">
          <span class="caution-id">${c.id || ''}</span>
          ${c.module ? `<span class="task-module">${c.module}</span>` : ''}
        </div>
        <div class="caution-title">${title}</div>
        ${summary ? `<div class="caution-field"><strong>Summary</strong>${summary}</div>` : ''}
        ${c.solution ? `<div class="caution-field"><strong>Solution</strong>${c.solution}</div>` : ''}
        ${c.reference ? `<div class="caution-field"><strong>Ref</strong>${c.reference}</div>` : ''}
        ${(c.tags && c.tags.length) ? `<div class="caution-tags">${c.tags.map(t => `<span class="caution-tag">${t}</span>`).join('')}</div>` : ''}
        <div class="caution-meta">
          ${c.createdAt || c.discoveredAt ? `<span>${c.createdAt || c.discoveredAt}</span>` : ''}
          ${c.source ? `<span>${c.source}</span>` : ''}
        </div>
      </div>`;
  });
}
</script>
</body>
</html>
HTMLEOF

  # Inject JSON data and mode flags
  local live_class="active"
  local watch_mode="true"
  if [ "$WATCH" = false ]; then
    live_class=""
    watch_mode="false"
  fi

  python3 -c "
import sys
with open('$RIME_DIR/tasks.json') as f: tasks = f.read().strip()
with open('$RIME_DIR/phase.json') as f: phase = f.read().strip()
with open('$RIME_DIR/cautions.json') as f: cautions = f.read().strip()
with open('$OUT', 'r') as f: html = f.read()
html = html.replace('__TASKS_DATA__', tasks)
html = html.replace('__PHASE_DATA__', phase)
html = html.replace('__CAUTIONS_DATA__', cautions)
html = html.replace('__WATCH_MODE__', '$watch_mode')
html = html.replace('__LIVE_CLASS__', '$live_class')
with open('$OUT', 'w') as f: f.write(html)
"
}

# Generate and open
generate
open "$OUT"

if [ "$WATCH" = true ]; then
  # Watch loop in background
  (
    HASH=$(cat "$RIME_DIR"/*.json 2>/dev/null | shasum)
    while true; do
      sleep 2
      NEW_HASH=$(cat "$RIME_DIR"/*.json 2>/dev/null | shasum)
      if [ "$NEW_HASH" != "$HASH" ]; then
        generate
        HASH="$NEW_HASH"
      fi
    done
  ) &
  WATCH_PID=$!
  echo "Dashboard watching $RIME_DIR/ (pid: $WATCH_PID)"
  echo "Stop: kill $WATCH_PID"
else
  echo "Dashboard opened: $OUT"
  echo "Tip: use --watch for live reload"
fi
