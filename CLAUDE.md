# Session Continuity System

## What This Is
A session persistence system for Claude coding sessions. Automatically tracks project state and provides quick-resume prompts so interrupted sessions can be picked up in seconds across any device.

Built because Claude sessions time out and there's no built-in session recovery. It gives Claude the context to resume where the last session left off — and (since the 2026-06-30 redesign) does so safely even when **concurrent sessions** work the same repo (e.g. a worktree + a live checkout).

## The three-file model
The single shared `SESSION_STATE.md` was built for ONE session resuming itself. With concurrent writers
(each session + the cron) its in-file auto-block raced and clobbered. The fix splits responsibilities so
no two writers ever touch the same file:

| File | Owner | Committed? | Purpose |
|------|-------|-----------|---------|
| `SESSION_STATE.md` | humans/Claude | **yes** | Thin, durable index: Current Focus, Active Workstreams table (one row per branch), `## From Prime`, decisions. **Edited on a branch and committed.** |
| `docs/notes/<branch>.md` | the session on that branch | **yes** | Per-stream working detail. Filename = branch → streams never collide. The PR is also a record. |
| `SESSION_STATUS.md` | the cron | **no** (gitignored) | Live git-derived status: branch, changed files, recent commits, timestamp. |

## How It Works
1. A cron job runs every 10 minutes, scanning all projects under the configured `PROJECTS_DIR`.
2. For any project with git activity, it writes that project's **`SESSION_STATUS.md`** sidecar (whole
   file, atomic) — and ensures the sidecar is excluded via `.git/info/exclude` so it's never committed.
   The cron **does not** write `SESSION_STATE.md` (one exception: the one-shot legacy cleanup below).
3. During a session, Claude saves richer context to `docs/notes/<branch>.md` and keeps the
   `SESSION_STATE.md` index current — **on its branch, committed**.
4. To resume, tell Claude to read the project's `CLAUDE.md` + `SESSION_STATE.md` (plus the branch notes
   and `SESSION_STATUS.md` for live git state).

### Why the sidecar (the concurrency fix)
`SESSION_STATUS.md` content is 100% derived from git, so it doesn't need to be durable or committed. By
living in a gitignored, per-working-tree file the cron owns alone, it can never clobber human content or
collide between concurrent sessions/worktrees. This removes the cron as a writer to any shared/committed
file — which is what dissolved the old contention.

### Edit-on-branch-and-commit (the human-side rule)
The silent-clobber risk existed only because edits sat **uncommitted** in one working tree, invisible to
others. So sessions edit `SESSION_STATE.md` / branch notes on their OWN branch and commit. Git then merges
different rows/sections automatically; genuine overlaps become normal, resolvable conflicts.

### Legacy cleanup (one-shot)
The first time the new cron sees a `SESSION_STATE.md` that still contains the old
`AUTO-GEN-START`/`AUTO-GEN-END` markers, it replaces that marker-bounded block (inclusive) with a single
pointer line and never touches the file again. Only content between the markers is removed; every human
section is preserved. Atomic + sanity-checked (aborts unless the result is non-empty and the markers are
gone).

**Atomicity:** writes go through `*.tmp.$$` + `mv` to avoid half-written files.

### What the cron does NOT do
- Write `SESSION_STATE.md` on an ongoing basis (only the one-shot legacy cleanup), or parse/rewrite any
  human-written section.
- Commit, push, or modify tracked files (the sidecar is excluded via `.git/info/exclude`, not `.gitignore`).
- Lock against concurrent writers — but it no longer needs to, since it owns `SESSION_STATUS.md` alone and
  humans coordinate `SESSION_STATE.md` via branches + commits.

## Components

| File | Purpose |
|------|---------|
| `auto-save-sessions.sh` | Cron script — scans projects, writes each `SESSION_STATUS.md` sidecar (one-shot legacy SESSION_STATE cleanup) |
| `save-session.sh` | Manual snapshot — inits the thin `SESSION_STATE.md`, `docs/notes/`, and the sidecar exclude; shows git state |
| `install.sh` | Interactive setup — creates config, installs cron |
| `config.example` | Template config — copy to `config` and customize |
| `config` | Your local config (gitignored) |
| `templates/SESSION_STATE.md` | Thin-index template for new projects |
| `templates/notes.md` | Per-stream notes template (`docs/notes/<branch>.md`) |
| `templates/CLAUDE_MD_SNIPPET.md` | Session continuity section to paste into project CLAUDE.md files |
| `RESUME_PROMPT.md` | Instructions for resuming sessions |

## Configuration
All user-specific settings live in `config` (gitignored). See `config.example` for the format.
- `PROJECTS_DIR` — path to your projects directory
- `SKIP_DIRS` — space-separated list of directories to skip
- `ACTIVITY_WINDOW` — minutes of inactivity before skipping (default: 30)

You can also override the config path via the `SESSION_CONTINUITY_CONFIG` environment variable.

## Adding a New Project
1. Run `./save-session.sh [project-name]` to initialize the thin `SESSION_STATE.md`, create
   `docs/notes/`, and exclude the `SESSION_STATUS.md` sidecar via `.git/info/exclude`
2. Copy the content from `templates/CLAUDE_MD_SNIPPET.md` into the project's CLAUDE.md
3. The cron will auto-detect it on the next run (if it has a `.git` directory and a `SESSION_STATE.md`)

## Tech Stack
- Shell scripts (bash)
- cron (macOS/Linux)
- Git (reads status, does not write)

## Rules & Preferences
- Scripts are read-only against git — they never commit, push, or modify code
- Keep it lightweight — no dependencies beyond bash and git
- SESSION_STATE.md files live in each project, not here
