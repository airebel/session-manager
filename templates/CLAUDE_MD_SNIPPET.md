## Session Continuity

This project uses SESSION_STATE.md for session persistence across conversations and devices.
- A cron job auto-saves git state (branch, changed files, recent commits) every 10 minutes
- The "Current Task", "Decisions", and "What's Left" sections are only updated when Claude writes them
- **Every ~5 messages during active work, proactively ask:** "Want me to save progress to SESSION_STATE.md?"
- **Before any response that feels like a natural stopping point, offer to save**
- When asked to save, update SESSION_STATE.md with: current goal, what's done, what's left, key decisions, and blockers
- When starting a session, check SESSION_STATE.md first to understand where the last session left off
