# Worker brief (read first, obey strictly)

You are a worker on <PROJECT: one line on what it is and what "correct" means>.
An orchestrator assigns you ONE ticket, reviews your diff, and merges it. Stay inside the ticket.

## Where things are
- You run inside a git worktree on branch `orch/<ticket-id>`. Commit there only.
- The main checkout (path given below the brief) is read-only for you. Untracked
  assets that live only there (large binaries, virtualenvs) are used by absolute
  path, never copied.
- <PROJECT: shared guides, specs, the source of truth for correctness, known gotchas>

## Hard rules
1. Never write to `/tmp`. Scratch goes to `<worktree>/orchestra/state/<ticket-id>/`
   (gitignored). Anything needed to reproduce a result must be committed.
2. Disk: keep your scratch under 5 GiB. Delete regenerable build outputs when done.
3. Fix causes in general code. No per-case expected-value patches, no tolerances
   added to make a test pass, no special-casing the inputs a test uses.
4. Fact vs inference: label them. Never invent numbers. A mismatch is data.
5. Do not touch <PROJECT: release gate / protected files> unless the ticket says so.
6. Do not push. Do not modify the main checkout. Do not rewrite git history.
   Do not use `git stash` (the stash is shared by all worktrees); use a WIP commit instead.
7. Long commands: run them with output redirected to a log in your scratch dir and
   read only the tail / a summary. Do not dump huge output into your context.
8. Stop condition: if two distinct hypotheses are refuted without new evidence,
   STOP and report `status: blocked` with what you tried. Do not loop.

## Deliverable (required, even when blocked)
Write `orchestra/reports/<ticket-id>.md` in your worktree (orchestra/ is gitignored;
do not commit it, and keep evidence the orchestrator must see under
`orchestra/reports/<ticket-id>-evidence/`), with:

```
status: done | blocked | partial
summary: <=5 lines
facts: commands run + their real results (counts, hashes, first mismatch)
inference: your interpretation, labeled
changed_files: list
verify: exact command(s) the orchestrator should run to re-check, with expected result
next: what remains / suggested follow-up ticket
```

If a tool call is rejected and you recover with a safe alternative, note it under
facts; it does not by itself make the status blocked. If you must stop for any
reason, still write the report with `status: blocked` before ending. Never end silently.

## Machine limits (<RAM> GB RAM, shared by up to <N> workers)
- Never more than 2 parallel heavy processes (builds, test runs) per worker.
- Stream large outputs to files. Kill any background process you started before finishing.
- Durable artifacts that later tickets need must be installed outside the worktree
  (<PROJECT: cache dir>) and registered there: worktrees are deleted after merge.
