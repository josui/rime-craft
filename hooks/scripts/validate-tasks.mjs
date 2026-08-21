#!/usr/bin/env node
// PostToolUse hook (matcher: Edit|Write, targeting /.rime/tasks.json)
// Mechanically validates that tasks.json conforms to data-contract.md: field whitelist, required fields and formats,
// status consistency, commit gate (a done item with commitFrom must have commits and from ≠ to), dependsOn reference and cycle checking, docs[].type enum.
// Feedback only, does not modify the file — errors are fed back to the model via decision:"block" for self-correction; warnings are surfaced via additionalContext.

import { readFileSync, appendFileSync } from "node:fs";
import { homedir } from "node:os";

const LOG = `${homedir()}/.rime-hook.log`;
const log = (msg) => {
  try {
    const ts = new Date().toTimeString().slice(0, 8);
    appendFileSync(LOG, `[${ts}] validate-tasks: ${msg}\n`);
  } catch {}
};

// ---- Mechanical projection of data-contract.md ----

const ITEM_FIELDS = new Set([
  "id", "module", "title", "description", "status", "phase", "priority",
  "difficulty", "createdAt", "completedAt", "subtasks", "dependsOn",
  "branch", "commitFrom", "commits", "docs",
]);
const REQUIRED_FIELDS = ["id", "title", "status", "priority", "createdAt", "phase"];
const STATUS_ENUM = new Set(["todo", "doing", "done"]);
const PRIORITY_ENUM = new Set(["high", "medium", "low"]);
const DIFFICULTY_ENUM = new Set(["small", "medium", "large"]);
const DOC_TYPE_ENUM = new Set(["spec", "plan", "prototype", "reference", "blueprint", "decision"]);
const ID_RE = /^#\d{4}$/;
const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;

// ---- Validation ----

function validate(data) {
  const errors = [];
  const warnings = [];
  const items = Array.isArray(data?.items) ? data.items : [];
  const ids = new Set(items.map((it) => it?.id).filter(Boolean));

  for (const item of items) {
    if (item === null || typeof item !== "object" || Array.isArray(item)) {
      errors.push(`items contains a non-object element: ${JSON.stringify(item)}`);
      continue;
    }
    const label = typeof item.id === "string" ? item.id : "(item missing id)";

    // Field whitelist — directly blocks invented fields like startedAt
    for (const key of Object.keys(item)) {
      if (!ITEM_FIELDS.has(key)) {
        errors.push(`${label}: unknown field "${key}" (fields outside the contract may not be written; if a new field is genuinely needed, amend data-contract.md first)`);
      }
    }

    // Required fields
    for (const key of REQUIRED_FIELDS) {
      if (item[key] === undefined || item[key] === null || item[key] === "") {
        errors.push(`${label}: missing required field "${key}"`);
      }
    }

    // Format and enums
    if (item.id !== undefined && !ID_RE.test(String(item.id))) {
      errors.push(`${label}: invalid id format (should be # + 4 zero-padded digits, e.g. #0001)`);
    }
    if (item.status !== undefined && !STATUS_ENUM.has(item.status)) {
      errors.push(`${label}: status "${item.status}" is not in the enum todo/doing/done`);
    }
    if (item.priority !== undefined && !PRIORITY_ENUM.has(item.priority)) {
      errors.push(`${label}: priority "${item.priority}" is not in the enum high/medium/low`);
    }
    if (item.difficulty !== undefined && !DIFFICULTY_ENUM.has(item.difficulty)) {
      errors.push(`${label}: difficulty "${item.difficulty}" is not in the enum small/medium/large`);
    }
    for (const key of ["createdAt", "completedAt"]) {
      if (item[key] !== undefined && !DATE_RE.test(String(item[key]))) {
        errors.push(`${label}: ${key} has an invalid format (should be YYYY-MM-DD)`);
      }
    }

    // Status consistency
    if (item.status === "doing" && !item.commitFrom) {
      warnings.push(`${label}: status=doing but missing commitFrom (the contract requires writing git rev-parse HEAD when transitioning to doing)`);
    }

    // commit gate: completedAt / commits must be written in the same commit as status=done
    if (item.status === "done") {
      if (!item.completedAt) {
        errors.push(`${label}: status=done but missing completedAt (must be written in the same write as status)`);
      }
      if (item.commitFrom && !item.commits) {
        errors.push(`${label}: status=done and has commitFrom but is missing commits (commit gate)`);
      }
    } else {
      for (const key of ["completedAt", "commits"]) {
        if (item[key] !== undefined) {
          errors.push(`${label}: status=${item.status} should not have ${key} (only written together with status when done)`);
        }
      }
    }
    if (item.commits !== undefined) {
      const c = item.commits;
      if (!c || typeof c !== "object" || Array.isArray(c) || typeof c.from !== "string" || typeof c.to !== "string") {
        errors.push(`${label}: commits should be { "from": "...", "to": "..." }`);
      } else if (c.from === c.to) {
        errors.push(`${label}: commits.from === commits.to (zero commits may not be marked done)`);
      }
    }

    // dependsOn reference existence
    if (item.dependsOn !== undefined) {
      if (!Array.isArray(item.dependsOn)) {
        errors.push(`${label}: dependsOn should be an array`);
      } else if (item.dependsOn.length === 0) {
        errors.push(`${label}: when dependsOn is empty, the key should be omitted, not written as []`);
      } else {
        for (const dep of item.dependsOn) {
          if (dep === item.id) {
            errors.push(`${label}: dependsOn self-reference`);
          } else if (!ids.has(dep)) {
            errors.push(`${label}: dependsOn references a nonexistent task "${dep}"`);
          }
        }
      }
    }

    // docs[].type enum
    if (item.docs !== undefined) {
      if (!Array.isArray(item.docs)) {
        errors.push(`${label}: docs should be an array`);
      } else {
        for (const doc of item.docs) {
          if (!doc || typeof doc !== "object" || !doc.type || !doc.path) {
            errors.push(`${label}: docs entries should be {type, path}`);
          } else if (!DOC_TYPE_ENUM.has(doc.type)) {
            errors.push(`${label}: docs[].type "${doc.type}" is not in the enum spec/plan/prototype/reference/blueprint/decision`);
          }
        }
      }
    }
  }

  // dependsOn DFS cycle detection (the graph must always be a DAG)
  const graph = new Map(
    items
      .filter((it) => it && typeof it === "object" && typeof it.id === "string")
      .map((it) => [it.id, Array.isArray(it.dependsOn) ? it.dependsOn.filter((d) => ids.has(d)) : []]),
  );
  const state = new Map(); // 0=unvisited 1=on stack 2=done
  const stack = [];
  const dfs = (node) => {
    state.set(node, 1);
    stack.push(node);
    for (const dep of graph.get(node) ?? []) {
      const s = state.get(dep) ?? 0;
      if (s === 1) {
        const cycle = [...stack.slice(stack.indexOf(dep)), dep].join(" → ");
        errors.push(`dependsOn has a cycle: ${cycle}`);
      } else if (s === 0) {
        dfs(dep);
      }
    }
    stack.pop();
    state.set(node, 2);
  };
  for (const node of graph.keys()) {
    if ((state.get(node) ?? 0) === 0) dfs(node);
  }

  return { errors, warnings };
}

// ---- Hook entry point ----

function readStdin() {
  try {
    return readFileSync(0, "utf8");
  } catch {
    return "";
  }
}

function main() {
  let input;
  try {
    input = JSON.parse(readStdin());
  } catch {
    return; // non-JSON input, silently allow
  }

  const filePath = input?.tool_input?.file_path ?? "";
  if (!/(^|\/)\.rime\/tasks\.json$/.test(filePath)) return; // the matcher only filters on tool name; the path is filtered again here

  let data;
  try {
    data = JSON.parse(readFileSync(filePath, "utf8"));
  } catch (e) {
    // If the file can't be read after being written, or isn't valid JSON, that itself is an error that must be fed back
    emit([`tasks.json is not valid JSON or could not be read: ${e.message}`], []);
    return;
  }

  const { errors, warnings } = validate(data);
  log(`${filePath}: ${errors.length} errors, ${warnings.length} warnings`);
  if (errors.length || warnings.length) emit(errors, warnings);
}

// Output protocol (Claude Code PostToolUse):
// - errors → JSON {decision:"block", reason} written to stdout; reason is fed back to the model automatically for self-correction
//   (by PostToolUse time the write has already happened; block does not undo the write, it only feeds back the violation info)
// - warnings only → hookSpecificOutput.additionalContext, surfaced as a non-blocking context hint
function emit(errors, warnings) {
  const lines = [
    ...errors.map((e) => `❌ ${e}`),
    ...warnings.map((w) => `⚠️ ${w}`),
  ];
  if (errors.length) {
    const reason =
      `tasks.json violates data-contract.md (the write has already happened — fix the file immediately):\n${lines.join("\n")}\n` +
      `For pre-existing done entries, backfill commits / completedAt according to real git history — this is a data repair, not subject to the done terminal-state restriction.\n` +
      `Field contract: see skills/rime-flow/data-contract.md in the rime-craft plugin; when unsure, load the rime-flow skill first.`;
    process.stdout.write(JSON.stringify({ decision: "block", reason }) + "\n");
  } else {
    process.stdout.write(
      JSON.stringify({
        hookSpecificOutput: {
          hookEventName: "PostToolUse",
          additionalContext: `tasks.json contract warnings:\n${lines.join("\n")}`,
        },
      }) + "\n",
    );
  }
}

main();
