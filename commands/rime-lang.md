---
description: Install the recommended writing-language rules (Japanese / Chinese, no cross-contamination) into CLAUDE.md. Idempotent — re-run to update.
argument-hint: [global | project]
---

Write the block below into a CLAUDE.md so every session carries the same writing-language rules. No scripts, no hooks — the rules live in CLAUDE.md and nothing else.

## Target

- `$ARGUMENTS` empty or `global` → `~/.claude/CLAUDE.md`
- `project` → `./CLAUDE.md` in the current working directory

Create the file if it does not exist.

## Procedure

1. Read the target file.
2. If it already contains `<!-- rime-lang:start -->` … `<!-- rime-lang:end -->`, replace everything between and including the markers with the block below. Otherwise append the block to the end of the file, preceded by one blank line.
3. Write the block **verbatim** — do not paraphrase, reorder, translate, or drop examples. To pin a language for one project, add a line to that project's CLAUDE.md instead of editing this block.
4. Report the target path and whether the block was added or updated, in the user's conversation language.

## Block

````markdown
<!-- rime-lang:start -->
## Writing Language

Match the project: write code comments, commit messages, and docs in the language the project already uses (look at existing comments, commits, README). A project-level CLAUDE.md may fix the language explicitly and wins. If the project has no established language, use the user's conversation language.

Japanese — do not let Chinese leak in:

- Chinese words are not Japanese: 専有名詞 → 固有名詞, 語法 → 文法, 過剰使用 → 使いすぎ, 〜を行う → plain verb (調整する).
- Keep the file's existing style (常体 / 敬体); do not unify a mixed file.
- Avoid chains of 「〜を行う」「〜について」, redundant 「また」「そして」「なお」; one short sentence per idea.

Chinese — do not let Japanese leak in:

- Japanese kanji words are not Chinese: 最適化 → 优化, 候補 → 候选, 一覧 → 列表, 成果物 → 交付物, 組版 → 排版, 明文化 → 明确写出, 決定事項 → 决定事项, 反映する → 体现 / 落实.
- No translationese: 「进行一个…的操作」「对…进行…」「…的话」「基于以上」; no piles of 「非常」「比较」「一定程度上」.

Both: terms, identifiers, numbers, paths stay verbatim. In comments and docs describe only the current approach — never what was rejected or how it evolved ("didn't use X because…", "instead of", "以前は…").
<!-- rime-lang:end -->
````
