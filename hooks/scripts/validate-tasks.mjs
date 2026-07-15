#!/usr/bin/env node
// PostToolUse hook（matcher: Edit|Write，目标 /.rime/tasks.json）
// 机械校验 tasks.json 是否符合 data-contract.md：字段白名单、必填与格式、
// 状态一致性、dependsOn 引用与检环、docs[].type 枚举。
// 只反馈不修改文件——错误经 decision:"block" 回注给模型自纠，警告经 additionalContext 提示。

import { readFileSync, appendFileSync } from "node:fs";
import { homedir } from "node:os";

const LOG = `${homedir()}/.rime-hook.log`;
const log = (msg) => {
  try {
    const ts = new Date().toTimeString().slice(0, 8);
    appendFileSync(LOG, `[${ts}] validate-tasks: ${msg}\n`);
  } catch {}
};

// ---- data-contract.md 的机械投影 ----

const ITEM_FIELDS = new Set([
  "id", "module", "title", "description", "status", "phase", "priority",
  "difficulty", "createdAt", "completedAt", "subtasks", "dependsOn",
  "branch", "commitFrom", "commits", "docs",
]);
const REQUIRED_FIELDS = ["id", "title", "status", "priority", "createdAt", "phase"];
const STATUS_ENUM = new Set(["todo", "doing", "done"]);
const PRIORITY_ENUM = new Set(["high", "medium", "low"]);
const DIFFICULTY_ENUM = new Set(["small", "medium", "large"]);
const DOC_TYPE_ENUM = new Set(["spec", "plan", "prototype", "reference", "blueprint"]);
const ID_RE = /^#\d{4}$/;
const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;

// ---- 校验 ----

function validate(data) {
  const errors = [];
  const warnings = [];
  const items = Array.isArray(data?.items) ? data.items : [];
  const ids = new Set(items.map((it) => it?.id).filter(Boolean));

  for (const item of items) {
    if (item === null || typeof item !== "object" || Array.isArray(item)) {
      errors.push(`items 中存在非对象元素: ${JSON.stringify(item)}`);
      continue;
    }
    const label = typeof item.id === "string" ? item.id : "(缺 id 的 item)";

    // 字段白名单——直接拦 startedAt 这类发明字段
    for (const key of Object.keys(item)) {
      if (!ITEM_FIELDS.has(key)) {
        errors.push(`${label}: 未知字段 "${key}"（契约外字段禁止写入；如确需新字段，先修订 data-contract.md）`);
      }
    }

    // 必填字段
    for (const key of REQUIRED_FIELDS) {
      if (item[key] === undefined || item[key] === null || item[key] === "") {
        errors.push(`${label}: 缺少必填字段 "${key}"`);
      }
    }

    // 格式与枚举
    if (item.id !== undefined && !ID_RE.test(String(item.id))) {
      errors.push(`${label}: id 格式错误（应为 # + 4 位补零，如 #0001）`);
    }
    if (item.status !== undefined && !STATUS_ENUM.has(item.status)) {
      errors.push(`${label}: status "${item.status}" 不在枚举 todo/doing/done 内`);
    }
    if (item.priority !== undefined && !PRIORITY_ENUM.has(item.priority)) {
      errors.push(`${label}: priority "${item.priority}" 不在枚举 high/medium/low 内`);
    }
    if (item.difficulty !== undefined && !DIFFICULTY_ENUM.has(item.difficulty)) {
      errors.push(`${label}: difficulty "${item.difficulty}" 不在枚举 small/medium/large 内`);
    }
    for (const key of ["createdAt", "completedAt"]) {
      if (item[key] !== undefined && !DATE_RE.test(String(item[key]))) {
        errors.push(`${label}: ${key} 格式错误（应为 YYYY-MM-DD）`);
      }
    }

    // 状态一致性（契约要求但可事后补，降级为警告）
    if (item.status === "doing" && !item.commitFrom) {
      warnings.push(`${label}: status=doing 但缺 commitFrom（契约要求转 doing 时写入 git rev-parse HEAD）`);
    }
    if (item.status === "done" && !item.completedAt) {
      warnings.push(`${label}: status=done 但缺 completedAt`);
    }

    // dependsOn 引用存在性
    if (item.dependsOn !== undefined) {
      if (!Array.isArray(item.dependsOn)) {
        errors.push(`${label}: dependsOn 应为数组`);
      } else if (item.dependsOn.length === 0) {
        errors.push(`${label}: dependsOn 为空时应省略该 key，不写 []`);
      } else {
        for (const dep of item.dependsOn) {
          if (dep === item.id) {
            errors.push(`${label}: dependsOn 自依赖`);
          } else if (!ids.has(dep)) {
            errors.push(`${label}: dependsOn 引用不存在的 task "${dep}"`);
          }
        }
      }
    }

    // docs[].type 枚举
    if (item.docs !== undefined) {
      if (!Array.isArray(item.docs)) {
        errors.push(`${label}: docs 应为数组`);
      } else {
        for (const doc of item.docs) {
          if (!doc || typeof doc !== "object" || !doc.type || !doc.path) {
            errors.push(`${label}: docs 条目应为 {type, path}`);
          } else if (!DOC_TYPE_ENUM.has(doc.type)) {
            errors.push(`${label}: docs[].type "${doc.type}" 不在枚举 spec/plan/prototype/reference/blueprint 内`);
          }
        }
      }
    }
  }

  // dependsOn DFS 检环（图恒为 DAG）
  const graph = new Map(
    items
      .filter((it) => it && typeof it === "object" && typeof it.id === "string")
      .map((it) => [it.id, Array.isArray(it.dependsOn) ? it.dependsOn.filter((d) => ids.has(d)) : []]),
  );
  const state = new Map(); // 0=未访问 1=在栈 2=已完成
  const stack = [];
  const dfs = (node) => {
    state.set(node, 1);
    stack.push(node);
    for (const dep of graph.get(node) ?? []) {
      const s = state.get(dep) ?? 0;
      if (s === 1) {
        const cycle = [...stack.slice(stack.indexOf(dep)), dep].join(" → ");
        errors.push(`dependsOn 存在环: ${cycle}`);
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

// ---- hook 入口 ----

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
    return; // 非 JSON 输入，静默放行
  }

  const filePath = input?.tool_input?.file_path ?? "";
  if (!/(^|\/)\.rime\/tasks\.json$/.test(filePath)) return; // matcher 只滤 tool name，路径在此二次过滤

  let data;
  try {
    data = JSON.parse(readFileSync(filePath, "utf8"));
  } catch (e) {
    // 写入后的文件读不了/不是合法 JSON，本身就是必须回注的错误
    emit([`tasks.json 不是合法 JSON 或无法读取: ${e.message}`], []);
    return;
  }

  const { errors, warnings } = validate(data);
  log(`${filePath}: ${errors.length} errors, ${warnings.length} warnings`);
  if (errors.length || warnings.length) emit(errors, warnings);
}

// 输出协议（Claude Code PostToolUse）：
// - errors → JSON {decision:"block", reason} 输出到 stdout，reason 自动回注给模型自纠
//   （PostToolUse 时写入已发生，block 不撤销写入，只把违规信息喂回去）
// - 仅 warnings → hookSpecificOutput.additionalContext，作为上下文提示不打断
function emit(errors, warnings) {
  const lines = [
    ...errors.map((e) => `❌ ${e}`),
    ...warnings.map((w) => `⚠️ ${w}`),
  ];
  if (errors.length) {
    const reason =
      `tasks.json 违反 data-contract.md（写入已发生，请立即修正文件）：\n${lines.join("\n")}\n` +
      `字段契约见 rime-craft plugin 的 skills/rime-flow/data-contract.md；拿不准先加载 rime-flow skill。`;
    process.stdout.write(JSON.stringify({ decision: "block", reason }) + "\n");
  } else {
    process.stdout.write(
      JSON.stringify({
        hookSpecificOutput: {
          hookEventName: "PostToolUse",
          additionalContext: `tasks.json 契约警告：\n${lines.join("\n")}`,
        },
      }) + "\n",
    );
  }
}

main();
