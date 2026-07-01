# Session Continuity for Claude

> **⚠️ The auto-save cron was retired 2026-07-01.** What remains is the committed `SESSION_STATE.md`
> index + `docs/notes/<branch>.md` notes (edited on a branch and committed); live git state is read on
> demand with `git status`/`git log`. The cron-based flow described below is historical.

Automatic session state tracking for Claude coding sessions. Picks up where you left off after session timeouts, across devices.

## The Problem

Claude sessions time out. When you start a new conversation, Claude has no memory of what you were working on — your current task, decisions made, files changed, or what's left to do.

## The Solution

A three-file model that's safe even when multiple sessions work the same repo at once:

- **`SESSION_STATE.md`** — a thin, durable, committed index (current focus, active workstreams, decisions).
  Edited on a branch and committed.
- **`docs/notes/<branch>.md`** — per-stream working detail, committed on each branch (filename = branch, so
  concurrent streams never collide).
- **`SESSION_STATUS.md`** — live git state (branch, changed files, recent commits) auto-saved by a cron every
  10 minutes. Gitignored and cron-owned.

When resuming, you tell Claude to read `SESSION_STATE.md` (+ the branch notes and `SESSION_STATUS.md`) and it
picks up with full context.

**What gets tracked automatically (`SESSION_STATUS.md`):** branch, changed files, recent commits, last commit info.

**What Claude adds when you say "save session" (committed on your branch):** current goal, what's done, what's
left, key decisions, blockers — in `docs/notes/<branch>.md`, with the `SESSION_STATE.md` index kept current.

## Requirements

- macOS or Linux
- bash
- git
- cron

## Quick Start

```bash
git clone https://github.com/airebel/session-manager.git
cd session-continuity
./install.sh
```

The installer will ask for:
1. Your projects directory path (e.g., `~/Projects`)
2. Any directories to skip
3. Whether to install the cron job

Then for each project you want to track:
1. Run `./save-session.sh [project-name]` to initialize it
2. Copy the content from `templates/CLAUDE_MD_SNIPPET.md` into that project's `CLAUDE.md`

## Resuming a Session

Paste this into a new Claude conversation:

```
Read /path/to/your/project/CLAUDE.md and /path/to/your/project/SESSION_STATE.md and pick up where I left off.
```

Claude will read your saved state and continue where you left off.

## How It Works

```
┌─────────────────┐    every 10 min     ┌─────────────────────────┐
│  Your Projects   │ ─── cron job ─────► │  SESSION_STATUS.md       │
│  (git repos)     │    reads git state  │  (gitignored, cron-owned)│
└─────────────────┘                      └─────────────────────────┘

   sessions edit on their branch + commit:
   SESSION_STATE.md (thin committed index)  +  docs/notes/<branch>.md (per-stream)
                                                     │
                                                     ▼
                                           ┌─────────────────────┐
                                           │  New Claude Session  │
                                           │  reads state files   │
                                           │  and resumes work    │
                                           └─────────────────────┘
```

## File Structure

```
session-continuity/
├── install.sh              # Interactive setup
├── auto-save-sessions.sh   # Cron script (writes each project's SESSION_STATUS.md sidecar)
├── save-session.sh         # Init/snapshot for a single project
├── config.example          # Template config (copy to 'config')
├── templates/
│   ├── SESSION_STATE.md    # Thin-index template for new projects
│   ├── notes.md            # Per-stream notes template (docs/notes/<branch>.md)
│   └── CLAUDE_MD_SNIPPET.md # Paste this into your project's CLAUDE.md
├── RESUME_PROMPT.md        # Resume instructions
└── README.md
```

## Configuration

All settings live in `config` (gitignored). Copy `config.example` to get started:

```bash
cp config.example config
```

| Setting | Description | Default |
|---------|-------------|---------|
| `PROJECTS_DIR` | Path to your projects directory | `$HOME/Projects` |
| `SKIP_DIRS` | Space-separated dirs to skip | (empty) |
| `ACTIVITY_WINDOW` | Minutes before skipping inactive projects | `30` |

## License

MIT
