# Session Continuity System

## What This Is
A session persistence system for Claude coding sessions. Automatically tracks project state and provides quick-resume prompts so interrupted sessions can be picked up in seconds across any device.

Built because Claude sessions time out and there's no built-in session recovery. This system keeps SESSION_STATE.md files fresh via cron and gives Claude the context to resume where the last session left off.

## How It Works
1. A cron job runs every 10 minutes, scanning all projects under the configured `PROJECTS_DIR`
2. For any project with recent git activity, it updates the auto-generated block of that project's `SESSION_STATE.md` — branch, changed files, recent commits, timestamp
3. During a Claude session, Claude proactively offers to save richer context (goals, decisions, what's left) to the same file
4. To resume, you tell Claude to read the project's `CLAUDE.md` + `SESSION_STATE.md`

### Marker-bounded auto-section (the safety contract)
The cron writes ONLY between two HTML-comment markers:

```
<!-- AUTO-GEN-START — managed by session-continuity cron, do not edit -->
... auto-generated content ...
<!-- AUTO-GEN-END -->
```

Everything outside those markers is human/Claude content and is never touched. You can rename sections, add new sections (`## Open PRs`, `## Inbox`, etc.), or reorder freely — the cron doesn't care. The only rule: don't put content inside the marker block; it gets overwritten every 10 minutes.

**Legacy migration:** the first time the cron sees an old-format `SESSION_STATE.md` (no markers), it strips the legacy `## Active Project`, `## Files Changed`, `## Recent Commits`, and `## Last Updated` sections, then appends the marker block at the end. Any other sections in the legacy file — including ones a Claude session added like `## Open PRs` — are preserved verbatim. One-shot migration; subsequent runs use the fast in-place marker swap.

**Atomicity:** writes go through `*.tmp.$$` + `mv` to avoid half-written files. If the marker block is missing or malformed, the cron logs a `WARN` and skips the project rather than risk corruption.

### What the cron does NOT do
- Parse, extract, or rewrite human-written sections
- Resolve placeholders, validate content, or "clean up"
- Lock the file against concurrent writers — if a Claude session writes to the file at the exact moment the cron is mid-update, the later write wins on standard last-writer-wins semantics. In practice this is rare since the cron's read-to-write window is sub-second.

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
