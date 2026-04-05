#!/bin/bash
# save-session.sh — Quick session state snapshot
# Usage: ./save-session.sh [project-name]
# Creates/updates SESSION_STATE.md in the project directory

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Load config
CONFIG_FILE="${SESSION_CONTINUITY_CONFIG:-$SCRIPT_DIR/config}"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file not found: $CONFIG_FILE"
    echo "Run ./install.sh or copy config.example to config and edit it."
    exit 1
fi
source "$CONFIG_FILE"

PROJECT=${1:-$(basename "$(pwd)")}
PROJECT_DIR="$PROJECTS_DIR/$PROJECT"
STATE_FILE="$PROJECT_DIR/SESSION_STATE.md"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "Project directory not found: $PROJECT_DIR"
    echo "Usage: ./save-session.sh [project-name]"
    echo "Available projects:"
    ls -d "$PROJECTS_DIR"/*/ | xargs -I{} basename {}
    exit 1
fi

# Copy template if no state file exists
TEMPLATE_FILE="$SCRIPT_DIR/templates/SESSION_STATE.md"
if [ ! -f "$STATE_FILE" ]; then
    if [ ! -f "$TEMPLATE_FILE" ]; then
        echo "ERROR: Template not found: $TEMPLATE_FILE"
        exit 1
    fi
    cp "$TEMPLATE_FILE" "$STATE_FILE"
    echo "Created new SESSION_STATE.md in $PROJECT_DIR"
fi

# Gather git info automatically
cd "$PROJECT_DIR"
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
LAST_COMMIT=$(git log --oneline -1 2>/dev/null || echo "no commits")
CHANGED_FILES=$(git diff --name-only 2>/dev/null | head -10)
STAGED_FILES=$(git diff --cached --name-only 2>/dev/null | head -10)

echo ""
echo "=== Session Snapshot for: $PROJECT ==="
echo "Branch: $BRANCH"
echo "Last commit: $LAST_COMMIT"
if [ -n "$CHANGED_FILES" ]; then
    echo "Modified files:"
    echo "$CHANGED_FILES" | sed 's/^/  - /'
fi
if [ -n "$STAGED_FILES" ]; then
    echo "Staged files:"
    echo "$STAGED_FILES" | sed 's/^/  - /'
fi
echo ""
echo "SESSION_STATE.md location: $STATE_FILE"
echo ""
echo "TIP: Before ending your Claude session, ask Claude to"
echo "     'update my SESSION_STATE.md with current progress'"
echo ""
