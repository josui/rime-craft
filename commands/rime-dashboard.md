---
description: Open the current project's .rime/ kanban dashboard — tasks, phases, and cautions. Project task tracking, NOT AI usage/spend/billing.
---

Open the current project's `.rime/` dashboard in the browser.

## Prerequisites

- Node.js 18+
- The current project already has a `.rime/` directory (with tasks.json)

If `.rime/` does not exist, the server prints the path it resolved and suggests initializing the project with `/rime-init` first.

## Execution

The dashboard server script lives inside the plugin — no need to copy it into the project. The script path resolves via `${CLAUDE_PLUGIN_ROOT}` — Claude Code expands it to an absolute path in place before this command enters context; no guessing or searching needed.

**Start it directly, do not ask the user.** From the project directory, run it in the **foreground** — do not use `run_in_background`:

```
node ${CLAUDE_PLUGIN_ROOT}/dashboard/server.mjs
```

The command finds a stable port for this project, starts the server detached from this Claude session, waits for it to come up, and returns within a few seconds. The server keeps running after this session ends. Re-running this command for the same project reuses the running instance and its URL.

**Do not assemble `--rime-dir` yourself.** The server has a built-in resolver whose resolution order is identical to the hooks' (authoritative definition: "Storage Location & Resolution Order" in rime-flow's data-contract.md), and it handles linked worktrees correctly — when started from a worktree it automatically resolves to the authoritative data on the main checkout side. Assembling the path by hand bypasses that layer and gets a wrong or nonexistent directory under a worktree.

Append `--rime-dir <path>` only when pointing at another project's `.rime/`.

The command opens the page in the browser itself; no extra `open` command is needed.

The command's output includes the server's pid and a `kill <pid>` hint for stopping it. Tell the user (in their conversation language) that the dashboard is running detached in live-reload mode, and give them the URL.
