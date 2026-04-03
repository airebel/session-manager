# Session Resume Prompt Template

> Claude has file access to the Mac mini (macmini.local) where all projects live. No need to attach files — just tell Claude to read them.

---

## Quick Resume (just paste this)

```
Read /Users/openclaw/Projects/[project-name]/CLAUDE.md and /Users/openclaw/Projects/[project-name]/SESSION_STATE.md and pick up where I left off.
```

## Project shortcuts (copy the one you need)

```
Read /Users/openclaw/Projects/aria-intelligence/CLAUDE.md and /Users/openclaw/Projects/aria-intelligence/SESSION_STATE.md and pick up where I left off.
```

```
Read /Users/openclaw/Projects/case-manager/CLAUDE.md and /Users/openclaw/Projects/case-manager/SESSION_STATE.md and pick up where I left off.
```

```
Read /Users/openclaw/Projects/comserv-website/CLAUDE.md and /Users/openclaw/Projects/comserv-website/SESSION_STATE.md and pick up where I left off.
```

```
Read /Users/openclaw/Projects/qualiflai-landing/CLAUDE.md and /Users/openclaw/Projects/qualiflai-landing/SESSION_STATE.md and pick up where I left off.
```

```
Read /Users/openclaw/Projects/AI_usecase/CLAUDE.md and /Users/openclaw/Projects/AI_usecase/SESSION_STATE.md and pick up where I left off.
```

```
Read /Users/openclaw/Projects/uptime-monitor/CLAUDE.md and /Users/openclaw/Projects/uptime-monitor/SESSION_STATE.md and pick up where I left off.
```

```
Read /Users/openclaw/Projects/ghl-crm-dashboard/CLAUDE.md and /Users/openclaw/Projects/ghl-crm-dashboard/SESSION_STATE.md and pick up where I left off.
```

```
Read /Users/openclaw/Projects/Nonprofit_donor/CLAUDE.md and /Users/openclaw/Projects/Nonprofit_donor/SESSION_STATE.md and pick up where I left off.
```

---

## During a session

- Claude will offer to save progress every ~5 messages
- You can also say **"save session"** anytime
- Before stepping away, say **"save session"** so the next conversation has full context

## What gets saved automatically vs. manually

| Saved by cron (every 10 min) | Saved when you say "save session" |
|------------------------------|-----------------------------------|
| Branch name | Current goal / task |
| Changed files | What's been done |
| Recent commits | What's left to do |
| Last commit info | Key decisions made |
| | Blockers / open questions |
