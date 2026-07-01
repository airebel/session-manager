# Session Resume Prompt

## Quick Resume

Paste this into a new Claude conversation, replacing `[project-path]` with the full path to your project:

```
Read [project-path]/CLAUDE.md and [project-path]/SESSION_STATE.md and pick up where I left off.
```

(Also point Claude at your branch's `docs/notes/<branch>.md` for the latest working detail, and have it
run `git status` / `git log` for live git state.)

## During a session

- Claude will offer to save progress every ~5 messages
- You can also say **"save session"** anytime — this updates `docs/notes/<branch>.md` and the
  `SESSION_STATE.md` index, **committed on your branch**
- Before stepping away, say **"save session"** so the next conversation has full context

## Where state lives

| Read live from git (on demand) | Saved when you say "save session" → branch notes + index (committed) |
|------------------------------|-----------------------------------|
| Branch name (`git branch`)   | Current goal / task               |
| Changed files (`git status`) | What's been done                  |
| Recent commits (`git log`)   | What's left to do                 |
| Last commit info             | Key decisions made                |
|                              | Blockers / open questions         |

_(The old 10-min auto-save cron that cached git state in `SESSION_STATUS.md` was retired 2026-07-01.)_
