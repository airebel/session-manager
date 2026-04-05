# Session Resume Prompt

## Quick Resume

Paste this into a new Claude conversation, replacing `[project-path]` with the full path to your project:

```
Read [project-path]/CLAUDE.md and [project-path]/SESSION_STATE.md and pick up where I left off.
```

## During a session

- Claude will offer to save progress every ~5 messages
- You can also say **"save session"** anytime
- Before stepping away, say **"save session"** so the next conversation has full context

## What gets saved automatically vs. manually

| Saved by cron (every 10 min) | Saved when you say "save session" |
|------------------------------|-----------------------------------|
| Branch name                  | Current goal / task               |
| Changed files                | What's been done                  |
| Recent commits               | What's left to do                 |
| Last commit info             | Key decisions made                |
|                              | Blockers / open questions         |
