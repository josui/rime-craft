# Documentation Templates

Templates and writing notes for each document type. Consult the relevant file as needed.

Templates define structure only. The language of generated document content is not governed by this skill — follow the repo's existing conventions and the user's language habits.

## Common Documents

| Template | Description |
|------|------|
| [template-prd.md](template-prd.md) | PRD — current-phase requirements, ID tracking |
| [template-archive.md](template-archive.md) | Archive — archive of completed features |
| [template-cautions.md](template-cautions.md) | Pitfall log, key constraints |

## Additional for Dev Projects

| Template | Description |
|------|------|
| [template-techstack.md](template-techstack.md) | Tech stack choices, project structure, phase plan |
| [template-interaction.md](template-interaction.md) | Interaction design, page states, operation flows |
| [template-schema.md](template-schema.md) | Data structure definitions |
| [DESIGN.md (rime-design skill)](../../rime-design/design-template.md) | Design system tokens + rationale (google-labs/design.md format). Template and generation flow live in the rime-design skill, not in this directory |

## Design Phase (spec)

Medium / large tasks produce a spec after grill convergence, locking down decisions + rationale + boundaries:

| Format | Description |
|------|------|
| Markdown (free-form) | Non-UI spec — decision log + interaction + boundaries, placed in `specs/` alongside Claude Code's `plansDirectory` (default `docs/specs/*.md`) |
| [template-spec.html](template-spec.html) | UI spec — sidebar numbered navigation + decision table + phone/desktop dual mock frames, natively rendered by dashboard `/file` |
