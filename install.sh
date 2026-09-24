#!/usr/bin/env bash
# Install tutor mode into a repository so it runs automatically in every session.
#
#   ./install.sh /path/to/repo      install into that repo
#   ./install.sh .                  install into the current directory
#
# Works from a clone, or piped straight from GitHub:
#   curl -fsSL https://raw.githubusercontent.com/DinakerJ/tutor-kit/main/install.sh | bash -s -- .

set -euo pipefail

RAW_BASE="https://raw.githubusercontent.com/DinakerJ/tutor-kit/main"
TARGET="${1:-}"

if [ -z "$TARGET" ]; then
    echo "usage: $0 /path/to/repo" >&2
    echo "       $0 .              (current directory)" >&2
    exit 1
fi

if [ ! -d "$TARGET" ]; then
    echo "error: $TARGET is not a directory" >&2
    exit 1
fi

TARGET="$(cd "$TARGET" && pwd)"

# Find TUTOR.md next to this script; fall back to downloading it.
SRC_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "$(dirname "${BASH_SOURCE[0]}")/TUTOR.md" ]; then
    SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [ -n "$SRC_DIR" ]; then
    cp "$SRC_DIR/TUTOR.md" "$TARGET/TUTOR.md"
    echo "wrote   TUTOR.md (from $SRC_DIR)"
else
    if ! command -v curl >/dev/null 2>&1; then
        echo "error: no local TUTOR.md and curl is not available" >&2
        exit 1
    fi
    curl -fsSL "$RAW_BASE/TUTOR.md" -o "$TARGET/TUTOR.md"
    echo "wrote   TUTOR.md (downloaded)"
fi

POINTER='# Operating contract

Read `TUTOR.md` in this repository and follow it for the whole session. Start by asking the
three configuration questions at the top of that file, and wait for the answers.'

for f in CLAUDE.md AGENTS.md GEMINI.md .cursorrules .windsurfrules; do
    dest="$TARGET/$f"
    if [ -e "$dest" ]; then
        if grep -q 'TUTOR.md' "$dest" 2>/dev/null; then
            echo "ok      $f (already points at TUTOR.md)"
        else
            echo "SKIPPED $f — it already exists. Add this line to the top of it:"
            echo "          Read \`TUTOR.md\` in this repository and follow it for the whole session."
        fi
    else
        printf '%s\n' "$POINTER" > "$dest"
        echo "wrote   $f"
    fi
done

echo
echo "Installed into $TARGET"
echo "Verify: start a session there and say only 'hello'."
echo "The assistant should ask three configuration questions and wait."
