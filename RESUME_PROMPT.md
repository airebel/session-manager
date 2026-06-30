# Session Resume Prompt

## Quick Resume

Paste this into a new Claude conversation, replacing `[project-path]` with the full path to your project:

```
Read [project-path]/CLAUDE.md and [project-path]/SESSION_STATE.md and pick up where I left off.
```

(Also point Claude at your branch's `docs/notes/<branch>.md` and `SESSION_STATUS.md` for the latest
working detail and live git state.)

## During a session

- Claude will offer to save progress every ~5 messages
- You can also say **"save session"** anytime — this updates `docs/notes/<branch>.md` and the
  `SESSION_STATE.md` index, **committed on your branch**
- Before stepping away, say **"save session"** so the next conversation has full context

## What gets saved automatically vs. manually

| Saved by cron → `SESSION_STATUS.md` (gitignored, every 10 min) | Saved when you say "save session" → branch notes + index (committed) |
|------------------------------|-----------------------------------|
| Branch name                  | Current goal / task               |
| Changed files                | What's been done                  |
| Recent commits               | What's left to do                 |
| Last commit info             | Key decisions made                |
|                              | Blockers / open questions         |
