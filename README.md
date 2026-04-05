# Session Continuity for Claude

Automatic session state tracking for Claude coding sessions. Picks up where you left off after session timeouts, across devices.

## The Problem

Claude sessions time out. When you start a new conversation, Claude has no memory of what you were working on — your current task, decisions made, files changed, or what's left to do.

## The Solution

A lightweight cron job snapshots your git project state every 10 minutes into a `SESSION_STATE.md` file. When resuming, you tell Claude to read that file and it picks up with full context.

**What gets tracked automatically:** branch, changed files, recent commits, last commit info.

**What Claude adds when you say "save session":** current goal, what's done, what's left, key decisions, blockers.

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
┌─────────────────┐     every 10 min      ┌─────────────────────┐
│  Your Projects   │ ◄──── cron job ─────► │  SESSION_STATE.md   │
│  (git repos)     │     reads git state   │  (in each project)  │
└─────────────────┘                        └─────────────────────┘
                                                     │
                                                     ▼
                                           ┌─────────────────────┐
                                           │  New Claude Session  │
                                           │  reads state file    │
                                           │  and resumes work    │
                                           └─────────────────────┘
```

## File Structure

```
session-continuity/
├── install.sh              # Interactive setup
├── auto-save-sessions.sh   # Cron script (scans projects, updates state)
├── save-session.sh         # Manual snapshot for a single project
├── config.example          # Template config (copy to 'config')
├── templates/
│   ├── SESSION_STATE.md    # Template for new projects
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
