# Archive Template

Narrative archive of completed phases. Moved in from the PRD when a phase closes.

## Template

```markdown
# {Project Name} Archive — Completed Phases

> Completed phases archived from the PRD. Narrative record, no longer actively managed.
> Detailed status for each item can be viewed in `.rime/tasks.json` (done items are reclaimed when a phase closes).

## P0 — MVP (completed YYYY-MM-DD)

> Optional: record this phase's scope decisions
> Example: given the time constraint of a "usable in one month" version, i18n was deferred...

Completed items: #001 Feature A, #002 Feature B, #003 Feature C

### Summary

A paragraph describing what this phase did, what was learned, and any experience worth recording.
```

## Writing Notes

- Section by phase (P0, P1, ...), recording the completion date
- **Narrative-first**, no status tables
- Reference completed items in `#ID Title` format, listed on one line
- May include a blockquote with that phase's scope decisions
- The summary records lessons learned, for future reference
- Only archive once the entire phase is complete — never archive a single item on its own
