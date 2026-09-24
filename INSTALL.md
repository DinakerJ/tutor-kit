# Installing tutor mode

`TUTOR.md` is the whole contract. Everything else here just points a given tool at it.

The design is deliberate: **one source of truth, thin pointers.** Each AI coding tool
auto-loads a different filename. Rather than maintain five copies that drift apart, each tool
gets a one-line file telling it to read `TUTOR.md`.

---

## Quick install

From inside `tutor-kit/`:

```bash
./install.sh /path/to/target/repo
```

That copies `TUTOR.md` to the target repo root and writes the pointer files. Re-running it is
safe — it will not overwrite an existing `CLAUDE.md` or `AGENTS.md` without asking.

---

## Manual install

Copy `TUTOR.md` to the root of the target repo, then create whichever pointer files match the
tools you use.

| Tool | File it auto-loads | Scope |
| --- | --- | --- |
| Claude Code | `CLAUDE.md` | project root, plus any subdirectory you work in |
| Claude Code (on demand) | `~/.claude/skills/<name>/SKILL.md` | all projects |
| Codex CLI | `AGENTS.md` | project root |
| Cursor | `.cursor/rules/*.mdc`, or legacy `.cursorrules` | project root |
| Windsurf | `.windsurfrules` | project root |
| Gemini CLI | `GEMINI.md` | project root |
| Aider | a file passed with `--read`, or set in `.aider.conf.yml` | as configured |
| Anything else | paste `TUTOR.md` into the system prompt | that session |

Filenames move as these tools change. If one stops working, check the tool's current docs — the
contract in `TUTOR.md` does not change, only the pointer does.

### The pointer content

Every pointer file holds the same two lines:

```markdown
# Operating contract

Read `TUTOR.md` in this repository and follow it for the whole session. Start by asking the
three configuration questions at the top of that file, and wait for the answers.
```

That is the entire file. Keep it short — the point is that the tool reads `TUTOR.md`, not that
it reads a summary of it.

### If the repo already has a CLAUDE.md or AGENTS.md

Do not overwrite it. Add the two lines above at the top of the existing file instead. Project
instructions and the tutor contract are different things and both should apply.

---

## Claude Code: the on-demand version

The pointer approach makes tutor mode **always on** for that repo. If you would rather invoke
it explicitly with `/tutor-mode`, install it as a skill instead:

```bash
mkdir -p ~/.claude/skills/tutor-mode
cp TUTOR.md ~/.claude/skills/tutor-mode/SKILL.md
```

Then add this YAML block at the very top of that copy, above everything else:

```yaml
---
name: tutor-mode
description: Teaching contract for learn-while-building work. Explains before writing code, one unit per turn, comprehension questions, and a Built/Tested/Explained phase gate. Use when the user must be able to defend every line to a panel, interviewer, or reviewer.
---
```

Skills installed under `~/.claude/skills/` are available in every project. The trade-off: the
YAML frontmatter is Claude-specific, so that copy is no longer portable. Keep the clean
`TUTOR.md` as the master and treat the skill copy as generated.

---

## Verifying it took

Start a session in the target repo and say nothing but `hello`.

The assistant should respond by asking the three configuration questions — depth, pace,
purpose — and then stop and wait. If it starts working, or answers the questions itself, the
file was not loaded. Check that the pointer file is at the repo root and that you are running
the tool from that root.

---

## Changing settings mid-session

Say so plainly: "switch to pace 3", "drop to depth A", "I'm in interview mode now". The
assistant should restate the new setting in one line and carry on.
