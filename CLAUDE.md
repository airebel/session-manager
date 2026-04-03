# Session Continuity System

## What This Is
A session persistence system for Claude app coding sessions. Automatically tracks project state and provides quick-resume prompts so interrupted sessions can be picked up in seconds across any device.

Built because Claude app sessions time out and there's no built-in session recovery. This system keeps SESSION_STATE.md files fresh via cron and gives Claude the context to resume where the last session left off.

## How It Works
1. A cron job runs every 10 minutes, scanning all projects under `/Users/openclaw/Projects/`
2. For any project with recent git activity, it updates that project's `SESSION_STATE.md` with branch, changed files, recent commits
3. During a Claude session, Claude proactively offers to save richer context (goals, decisions, what's left) to the same file
4. To resume, you tell Claude to read the project's `CLAUDE.md` + `SESSION_STATE.md`

## Components

| File | Purpose |
|------|---------|
| `auto-save-sessions.sh` | Cron script — scans projects, updates SESSION_STATE.md files every 10 min |
| `save-session.sh` | Manual snapshot — shows git state for a given project |
| `RESUME_PROMPT.md` | Copy-paste resume prompts for every project |
| `SESSION_STATE.md` | Master template — copied into new projects |

## Cron Job
```
*/10 * * * * /Users/openclaw/Projects/session-continuity/auto-save-sessions.sh >> /Users/openclaw/Projects/session-continuity/session-autosave.log 2>&1
```
- Log file: `session-autosave.log`
- Only updates projects with recent file changes or uncommitted git work
- Preserves Claude-written sections (goals, decisions, todos) between runs
- Skips `ai-task-manager_RETIRED` and `scratch`

## Per-Project Setup
Each active project has:
- `CLAUDE.md` — project context, architecture, key files
- `SESSION_STATE.md` — auto-updated by cron + enriched by Claude during sessions
- "Session Continuity" section in CLAUDE.md — tells Claude to check state on start and offer saves during work

## Adding a New Project
1. Copy `SESSION_STATE.md` template into the new project folder
2. Create a `CLAUDE.md` for the project (or ask Claude to generate one)
3. The cron will auto-detect it on the next run (if it has a `.git` directory)

## Tech Stack
- Shell scripts (bash)
- macOS cron
- Git (reads status, does not write)

## Rules & Preferences
- Scripts are read-only against git — they never commit, push, or modify code
- Keep it lightweight — no dependencies beyond bash and git
- SESSION_STATE.md files live in each project, not here

## Session Continuity
This project uses SESSION_STATE.md for session persistence across conversations and devices.
- A cron job auto-saves git state (branch, changed files, recent commits) every 10 minutes
- The "Current Task", "Decisions", and "What's Left" sections are only updated when Claude writes them
- **Every ~5 messages during active work, proactively ask:** "Want me to save progress to SESSION_STATE.md?"
- **Before any response that feels like a natural stopping point, offer to save**
- When asked to save, update SESSION_STATE.md with: current goal, what's done, what's left, key decisions, and blockers
- When starting a session, check SESSION_STATE.md first to understand where the last session left off
