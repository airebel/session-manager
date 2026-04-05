#!/bin/bash
# auto-save-sessions.sh — Cron job that auto-updates SESSION_STATE.md for active projects
# Runs every 10 minutes. Only updates projects with recent git activity (last 30 min).

# Resolve script's own directory (works with symlinks and cron)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load config
CONFIG_FILE="${SESSION_CONTINUITY_CONFIG:-$SCRIPT_DIR/config}"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file not found: $CONFIG_FILE"
    echo "Run ./install.sh or copy config.example to config and edit it."
    exit 1
fi
source "$CONFIG_FILE"

# Defaults for optional values
ACTIVITY_WINDOW="${ACTIVITY_WINDOW:-30}"
SKIP_DIRS="${SKIP_DIRS:-}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

for project_dir in "$PROJECTS_DIR"/*/; do
    project_name=$(basename "$project_dir")

    # Skip non-project directories and inactive projects
    if echo "$SKIP_DIRS" | grep -qw "$project_name"; then
        continue
    fi

    # Skip if not a git repo
    if [ ! -d "$project_dir/.git" ]; then
        continue
    fi

    state_file="$project_dir/SESSION_STATE.md"

    # Skip if no SESSION_STATE.md
    if [ ! -f "$state_file" ]; then
        continue
    fi

    cd "$project_dir" || continue

    # Check for recent activity: any file modified in the last ACTIVITY_WINDOW minutes
    recent_changes=$(find . -not -path './.git/*' -not -name 'SESSION_STATE.md' -newer "$state_file" -type f 2>/dev/null | head -1)

    # Also check for uncommitted changes
    has_uncommitted=$(git status --porcelain 2>/dev/null | head -1)

    # Skip if no recent activity and no uncommitted changes
    if [ -z "$recent_changes" ] && [ -z "$has_uncommitted" ]; then
        continue
    fi

    log "Updating: $project_name"

    # Gather git info
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    last_commit=$(git log --oneline -1 2>/dev/null || echo "no commits")
    last_commit_time=$(git log -1 --format='%ci' 2>/dev/null || echo "unknown")

    # Get changed files (both staged and unstaged)
    changed_files=""
    unstaged=$(git diff --name-only 2>/dev/null)
    staged=$(git diff --cached --name-only 2>/dev/null)
    untracked=$(git ls-files --others --exclude-standard 2>/dev/null)

    if [ -n "$unstaged" ]; then
        changed_files="$changed_files
### Modified (unstaged)
$(echo "$unstaged" | sed 's/^/- /')"
    fi
    if [ -n "$staged" ]; then
        changed_files="$changed_files
### Staged
$(echo "$staged" | sed 's/^/- /')"
    fi
    if [ -n "$untracked" ]; then
        changed_files="$changed_files
### Untracked
$(echo "$untracked" | head -10 | sed 's/^/- /')"
    fi

    if [ -z "$changed_files" ]; then
        changed_files="- (working tree clean)"
    fi

    # Get recent commits (last 5)
    recent_commits=$(git log --oneline -5 2>/dev/null | sed 's/^/- /')

    # Read existing state to preserve human/Claude-written sections
    existing_goal="(none)"
    existing_status="not started"
    existing_done="- (nothing yet)"
    existing_todo="- (nothing yet)"
    existing_decisions="- (none)"
    existing_blockers="- (none)"

    if [ -f "$state_file" ]; then
        # Preserve manually written sections by extracting them
        # Only overwrite auto-generated sections (branch, files, timestamp)
        goal_line=$(grep '^\*\*Goal:\*\*' "$state_file" | head -1)
        if [ -n "$goal_line" ] && ! echo "$goal_line" | grep -q '(none)'; then
            existing_goal=$(echo "$goal_line" | sed 's/\*\*Goal:\*\* //')
        fi

        status_line=$(grep '^\*\*Status:\*\*' "$state_file" | head -1)
        if [ -n "$status_line" ] && ! echo "$status_line" | grep -q 'not started'; then
            existing_status=$(echo "$status_line" | sed 's/\*\*Status:\*\* //')
        fi

        # Extract multi-line sections (macOS-compatible)
        extract_section() {
            local file="$1" header="$2" next_header="$3"
            awk "/^## ${header}$/,/^## ${next_header}$/" "$file" | tail -n +2 | sed '$d' | grep -v '^$'
        }

        done_section=$(extract_section "$state_file" "What's Been Done This Session" "What's Left To Do")
        if [ -n "$done_section" ] && ! echo "$done_section" | grep -q '(nothing yet)'; then
            existing_done="$done_section"
        fi

        todo_section=$(extract_section "$state_file" "What's Left To Do" "Key Decisions Made")
        if [ -n "$todo_section" ] && ! echo "$todo_section" | grep -q '(nothing yet)'; then
            existing_todo="$todo_section"
        fi

        decisions_section=$(awk 'BEGIN{p=0} /^## Key Decisions Made$/{p=1;next} /^## Open Questions/{p=0} p' "$state_file" | grep -v '^$')
        if [ -n "$decisions_section" ] && ! echo "$decisions_section" | grep -q '(none)'; then
            existing_decisions="$decisions_section"
        fi

        blockers_section=$(awk 'BEGIN{p=0} /^## Open Questions/{p=1;next} /^## Files Changed$/{p=0} p' "$state_file" | grep -v '^$')
        if [ -n "$blockers_section" ] && ! echo "$blockers_section" | grep -q '(none)'; then
            existing_blockers="$blockers_section"
        fi
    fi

    # Write updated state
    cat > "$state_file" << STATEEOF
# Session State — $project_name

## Active Project
**Project:** $project_name
**Branch:** $branch
**Last commit:** $last_commit
**Last commit time:** $last_commit_time

## Current Task
**Goal:** $existing_goal
**Status:** $existing_status

## What's Been Done This Session
$existing_done

## What's Left To Do
$existing_todo

## Key Decisions Made
$existing_decisions

## Open Questions / Blockers
$existing_blockers

## Files Changed
$changed_files

## Recent Commits
$recent_commits

## Last Updated
$(date '+%Y-%m-%d %H:%M:%S') (auto-saved by cron)
STATEEOF

    log "  -> Branch: $branch | Changed files: $(echo "$unstaged $staged $untracked" | wc -w | tr -d ' ')"
done

log "Session auto-save complete."
