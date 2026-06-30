## Session Continuity

This project uses a three-file model for session persistence across conversations, devices, and
**concurrent sessions** (e.g. a worktree + a live checkout on the same repo).

- **`SESSION_STATE.md`** — a thin, durable, **committed** index: Current Focus, an Active Workstreams
  table (one row per branch), `## From Prime`, key decisions. **Edit it on YOUR branch and commit it.**
  Never leave long-lived uncommitted edits — that's what strands context in one working tree and lets
  concurrent sessions clobber each other. Distinct rows/sections merge cleanly in git.
- **`docs/notes/<branch>.md`** — per-stream working detail, committed on that branch. Filename = the
  branch, so two streams never touch the same file. The PR is also a record.
- **`SESSION_STATUS.md`** — live git status (branch, changed files, recent commits), auto-saved by the
  cron every ~10 min. **Gitignored, read-only, don't edit.** It's regenerable from git at any time.

### Habits during a session
- **Every ~5 messages of active work, proactively ask:** "Want me to save progress to the branch notes
  + SESSION_STATE?"
- Before any natural stopping point, offer to save. When saving: update `docs/notes/<branch>.md` with
  goal / done / left / decisions / blockers, keep `SESSION_STATE.md`'s row + Current Focus current, and
  **commit on the branch**.
- When starting a session, read `CLAUDE.md` + `SESSION_STATE.md` (and your branch's notes, and
  `SESSION_STATUS.md` for live git state) to see where the last session left off.
- **One writer per file:** don't edit a repo's `SESSION_STATE.md` while another live session is open on
  the same repo. Different repos in parallel never conflict; the same repo can.
