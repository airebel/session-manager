#!/bin/bash
# auto-save-sessions.sh — Cron job that auto-updates SESSION_STATE.md for active projects.
#
# Strategy: marker-bounded auto-section.
#
#   <!-- AUTO-GEN-START — managed by session-continuity cron, do not edit -->
#   ... auto-generated content (branch, files changed, recent commits, timestamp) ...
#   <!-- AUTO-GEN-END -->
#
# The cron ONLY writes between those markers. Every human/Claude-written section
# (## Current Task, ## From Prime, ## What's Been Done, ## Open Questions, etc.)
# is left completely untouched.
#
# On first run against a legacy SESSION_STATE.md that has no markers, the script
# strips the legacy auto-generated sections (## Active Project, ## Files Changed,
# ## Recent Commits, ## Last Updated) and appends a marker block at end of file.
# Anything else in the legacy file — including sections users/Claude added like
# ## Open PRs or ## Open Issues — is preserved verbatim.

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

CONFIG_FILE="${SESSION_CONTINUITY_CONFIG:-$SCRIPT_DIR/config}"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file not found: $CONFIG_FILE"
    echo "Run ./install.sh or copy config.example to config and edit it."
    exit 1
fi
# shellcheck disable=SC1090
source "$CONFIG_FILE"

ACTIVITY_WINDOW="${ACTIVITY_WINDOW:-30}"
SKIP_DIRS="${SKIP_DIRS:-}"

MARKER_START="<!-- AUTO-GEN-START — managed by session-continuity cron, do not edit -->"
MARKER_END="<!-- AUTO-GEN-END -->"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Build the auto-gen block (markers + content) for a project's current git state.
# Args: branch, last_commit, last_commit_time, changed_files, recent_commits
build_block() {
    local branch="$1" last_commit="$2" last_commit_time="$3" changed="$4" recent="$5"
    cat <<EOF
$MARKER_START
## Status (auto-saved)
**Branch:** $branch
**Last commit:** $last_commit
**Last commit time:** $last_commit_time

### Files Changed
$changed

### Recent Commits
$recent

_Auto-saved: $(date '+%Y-%m-%d %H:%M:%S')_
$MARKER_END
EOF
}

# Replace the existing AUTO-GEN block in $1 with $2.
# Atomic: writes to tmp file, validates, then renames.
# Returns 0 on success, 1 on failure (caller logs).
replace_block() {
    local file="$1"
    local block_content="$2"
    local tmp="${file}.tmp.$$"
    local block_tmp="${file}.block.$$"

    # awk's -v can't accept multi-line strings, so write the block to a tmp file
    # and have awk read it on first match.
    printf '%s\n' "$block_content" > "$block_tmp"

    awk -v start="$MARKER_START" -v end="$MARKER_END" -v blockfile="$block_tmp" '
        BEGIN { inblock = 0; replaced = 0 }
        $0 == start {
            inblock = 1
            while ((getline line < blockfile) > 0) print line
            close(blockfile)
            replaced = 1
            next
        }
        $0 == end { inblock = 0; next }
        !inblock { print }
        END { exit (replaced ? 0 : 2) }
    ' "$file" > "$tmp"
    local rc=$?
    rm -f "$block_tmp"

    if [ $rc -ne 0 ] || [ ! -s "$tmp" ]; then
        rm -f "$tmp"
        return 1
    fi

    # Sanity: both markers must appear in the new file.
    if ! grep -qF "$MARKER_START" "$tmp" || ! grep -qF "$MARKER_END" "$tmp"; then
        rm -f "$tmp"
        return 1
    fi

    mv "$tmp" "$file"
    return 0
}

# Legacy migration: strip pre-marker auto-gen sections, then append the new
# marker block at end of file. Preserves any user-added sections (e.g. ## Open PRs)
# even if they were tangled up with legacy sections.
append_block_with_migration() {
    local file="$1"
    local block_content="$2"
    local tmp="${file}.tmp.$$"

    # Drop the legacy auto-gen sections wherever they appear:
    #   ## Active Project   ## Files Changed   ## Recent Commits   ## Last Updated
    # A section is "from header line until the next ## that isn't also a legacy header."
    awk '
        BEGIN {
            skip_headers["## Active Project"] = 1
            skip_headers["## Files Changed"] = 1
            skip_headers["## Recent Commits"] = 1
            skip_headers["## Last Updated"] = 1
            skip = 0
        }
        {
            if ($0 in skip_headers) { skip = 1; next }
            if (skip && $0 ~ /^## / && !($0 in skip_headers)) { skip = 0 }
            if (!skip) print
        }
    ' "$file" > "$tmp"

    # Trim trailing blank lines so the appended block has clean spacing.
    awk '
        { lines[NR] = $0 }
        END {
            last = NR
            while (last > 0 && lines[last] ~ /^[[:space:]]*$/) last--
            for (i = 1; i <= last; i++) print lines[i]
        }
    ' "$tmp" > "${tmp}.2" && mv "${tmp}.2" "$tmp"

    # Append marker block, separated by one blank line.
    printf '\n%s\n' "$block_content" >> "$tmp"

    if [ ! -s "$tmp" ]; then
        rm -f "$tmp"
        return 1
    fi

    # Sanity check before swap.
    if ! grep -qF "$MARKER_START" "$tmp" || ! grep -qF "$MARKER_END" "$tmp"; then
        rm -f "$tmp"
        return 1
    fi

    mv "$tmp" "$file"
    return 0
}

for project_dir in "$PROJECTS_DIR"/*/; do
    project_name=$(basename "$project_dir")

    if echo "$SKIP_DIRS" | grep -qw "$project_name"; then
        continue
    fi

    if [ ! -d "$project_dir/.git" ]; then
        continue
    fi

    state_file="$project_dir/SESSION_STATE.md"
    if [ ! -f "$state_file" ]; then
        continue
    fi

    cd "$project_dir" || continue

    recent_changes=$(find . -not -path './.git/*' -not -name 'SESSION_STATE.md' -newer "$state_file" -type f 2>/dev/null | head -1)
    has_uncommitted=$(git status --porcelain 2>/dev/null | head -1)

    if [ -z "$recent_changes" ] && [ -z "$has_uncommitted" ]; then
        continue
    fi

    log "Updating: $project_name"

    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    last_commit=$(git log --oneline -1 2>/dev/null || echo "no commits")
    last_commit_time=$(git log -1 --format='%ci' 2>/dev/null || echo "unknown")

    unstaged=$(git diff --name-only 2>/dev/null)
    staged=$(git diff --cached --name-only 2>/dev/null)
    untracked=$(git ls-files --others --exclude-standard 2>/dev/null)

    changed_files=""
    if [ -n "$unstaged" ]; then
        changed_files="$changed_files
**Modified (unstaged):**
$(echo "$unstaged" | sed 's/^/- /')"
    fi
    if [ -n "$staged" ]; then
        changed_files="$changed_files
**Staged:**
$(echo "$staged" | sed 's/^/- /')"
    fi
    if [ -n "$untracked" ]; then
        changed_files="$changed_files
**Untracked:**
$(echo "$untracked" | head -10 | sed 's/^/- /')"
    fi
    if [ -z "$changed_files" ]; then
        changed_files="- (working tree clean)"
    fi

    recent_commits=$(git log --oneline -5 2>/dev/null | sed 's/^/- /')

    block=$(build_block "$branch" "$last_commit" "$last_commit_time" "$changed_files" "$recent_commits")

    if grep -qF "$MARKER_START" "$state_file"; then
        if replace_block "$state_file" "$block"; then
            log "  -> Branch: $branch | Files: $(echo "$unstaged $staged $untracked" | wc -w | tr -d ' ')"
        else
            log "  -> WARN: marker replace failed for $project_name (markers malformed?). Skipping."
        fi
    else
        if append_block_with_migration "$state_file" "$block"; then
            log "  -> Branch: $branch | MIGRATED to marker-based layout"
        else
            log "  -> WARN: migration failed for $project_name. Skipping."
        fi
    fi
done

log "Session auto-save complete."
