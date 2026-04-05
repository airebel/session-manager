# Session Continuity System

## What This Is
A session persistence system for Claude coding sessions. Automatically tracks project state and provides quick-resume prompts so interrupted sessions can be picked up in seconds across any device.

Built because Claude sessions time out and there's no built-in session recovery. This system keeps SESSION_STATE.md files fresh via cron and gives Claude the context to resume where the last session left off.

## How It Works
1. A cron job runs every 10 minutes, scanning all projects under the configured `PROJECTS_DIR`
2. For any project with recent git activity, it updates that project's `SESSION_STATE.md` with branch, changed files, recent commits
3. During a Claude session, Claude proactively offers to save richer context (goals, decisions, what's left) to the same file
4. To resume, you tell Claude to read the project's `CLAUDE.md` + `SESSION_STATE.md`

## Components

| File | Purpose |
|------|---------|
| `auto-save-sessions.sh` | Cron script — scans projects, updates SESSION_STATE.md files |
| `save-session.sh` | Manual snapshot — shows git state for a given project |
| `install.sh` | Interactive setup — creates config, installs cron |
| `config.example` | Template config — copy to `config` and customize |
| `config` | Your local config (gitignored) |
| `templates/SESSION_STATE.md` | Template for new projects |
| `templates/CLAUDE_MD_SNIPPET.md` | Session continuity section to paste into project CLAUDE.md files |
| `RESUME_PROMPT.md` | Instructions for resuming sessions |

## Configuration
All user-specific settings live in `config` (gitignored). See `config.example` for the format.
- `PROJECTS_DIR` — path to your projects directory
- `SKIP_DIRS` — space-separated list of directories to skip
- `ACTIVITY_WINDOW` — minutes of inactivity before skipping (default: 30)

You can also override the config path via the `SESSION_CONTINUITY_CONFIG` environment variable.

## Adding a New Project
1. Run `./save-session.sh [project-name]` to initialize SESSION_STATE.md
2. Copy the content from `templates/CLAUDE_MD_SNIPPET.md` into the project's CLAUDE.md
3. The cron will auto-detect it on the next run (if it has a `.git` directory)

## Tech Stack
- Shell scripts (bash)
- cron (macOS/Linux)
- Git (reads status, does not write)

## Rules & Preferences
- Scripts are read-only against git — they never commit, push, or modify code
- Keep it lightweight — no dependencies beyond bash and git
- SESSION_STATE.md files live in each project, not here
