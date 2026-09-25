#!/usr/bin/env bash
# Install tutor mode into a repository so it runs automatically in every Claude Code session.
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

# The @TUTOR.md line is a Claude Code import: it expands the contract into context at launch.
# It must stay outside backticks - Claude Code skips imports inside code spans, which means a
# backticked mention loads nothing and leaves the contract up to chance.
POINTER='# Operating contract

@TUTOR.md

The contract imported above governs this entire session.

Your first action in a new session, including a reply to a bare greeting such as "hello", is
to ask the three configuration questions at the top of that contract (depth, pace, purpose),
then stop and wait. Do not assume defaults. Do not start work, summarise the repo, or answer
anything else until all three are answered.'

dest="$TARGET/CLAUDE.md"
if [ -e "$dest" ]; then
    if grep -q '@TUTOR.md' "$dest" 2>/dev/null; then
        echo "ok      CLAUDE.md (already imports TUTOR.md)"
    elif grep -qF 'Read `TUTOR.md` in this repository' "$dest" 2>/dev/null; then
        printf '%s
' "$POINTER" > "$dest"
        echo "wrote   CLAUDE.md (upgraded an older tutor-kit pointer to a real import)"
    elif grep -q 'TUTOR.md' "$dest" 2>/dev/null; then
        echo "ACTION  CLAUDE.md mentions TUTOR.md but does not import it."
        echo "          A backticked mention does not load the contract. Add this line, unquoted:"
        echo "          @TUTOR.md"
    else
        echo "SKIPPED CLAUDE.md - it already exists. Add this line to the top of it:"
        echo "          @TUTOR.md"
    fi
else
    printf '%s\n' "$POINTER" > "$dest"
    echo "wrote   CLAUDE.md"
fi

# Earlier versions of this kit also wrote pointer files for other tools. Claude Code ignores
# them, and a stray AGENTS.md can confuse a later reader, so point them out.
leftovers=""
for f in AGENTS.md GEMINI.md .cursorrules .windsurfrules; do
    if [ -e "$TARGET/$f" ] && grep -q 'TUTOR.md' "$TARGET/$f" 2>/dev/null; then
        leftovers="$leftovers $f"
    fi
done
if [ -n "$leftovers" ]; then
    echo
    echo "note    leftover pointer files from an earlier tutor-kit install:$leftovers"
    echo "        Claude Code does not read them. Safe to delete:"
    echo "          (cd '$TARGET' && rm$leftovers)"
fi

echo
echo "Installed into $TARGET"
echo "Verify: start a NEW session there and say only 'hello'."
echo "The assistant should ask three configuration questions and wait."
