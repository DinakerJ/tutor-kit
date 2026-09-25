# Installing tutor mode

`TUTOR.md` is the whole contract. Everything else here just gets Claude Code to load it.

The design is deliberate: **one source of truth, one import.** `CLAUDE.md` holds no copy of the
contract and no summary of it — only a pointer that Claude Code expands into context at launch.
Nothing can drift out of sync, because there is only one copy.

---

## Quick install

From inside `tutor-kit/` on macOS, Linux, WSL, or Git Bash:

```bash
./install.sh /path/to/target/repo
```

In Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 "C:\path\to\target\repo"
```

The two installers are equivalent and write byte-identical files. Use `install.ps1` on Windows:
`curl` there is an alias for `Invoke-WebRequest` and rejects `-fsSL`, and `bash` is not on
`PATH` even with Git for Windows installed.

That copies `TUTOR.md` to the target repo root and writes a `CLAUDE.md` importing it.
Re-running is safe — an existing `CLAUDE.md` is never overwritten.

---

## Manual install

Copy `TUTOR.md` to the root of the target repo, then create `CLAUDE.md` next to it containing:

```markdown
# Operating contract

@TUTOR.md

The contract imported above governs this entire session.

Your first action in a new session, including a reply to a bare greeting such as "hello", is
to ask the three configuration questions at the top of that contract (depth, pace, purpose),
then stop and wait. Do not assume defaults. Do not start work, summarise the repo, or answer
anything else until all three are answered.
```

That is the entire file.

### Why the `@` and why no backticks

`@TUTOR.md` is a Claude Code **import**. At session start Claude Code expands it and loads the
whole contract into context, before you type anything. Relative paths resolve against the file
containing the import, and imports can nest four hops deep.

The filename must stay **outside backticks**. Claude Code skips import parsing inside Markdown
code spans and fenced code blocks, so `` `@TUTOR.md` `` loads nothing at all. This is the
single most common way to get a tutor-kit install that appears correct but behaves randomly:
Claude sees an instruction to go read a file, and whether it bothers is a coin flip. With the
bare import there is no decision to make — the contract is already there.

### Where the files can live

| Location | Loaded | Notes |
| --- | --- | --- |
| `./CLAUDE.md` | every session | the default this kit installs |
| `./.claude/CLAUDE.md` | every session | equivalent; keeps the repo root clean |
| `./.claude/rules/*.md` | every session | loads alongside, and does **not** count as a `CLAUDE.md` |
| `./CLAUDE.local.md` | every session | for private, uncommitted overrides; gitignore it |

All discovered memory files are concatenated into context rather than overriding each other, so
an existing project `CLAUDE.md` and the tutor contract can coexist. Content is ordered from the
filesystem root down to your working directory.

### If the repo already has a CLAUDE.md

Do not overwrite it. Add the `@TUTOR.md` line at the top of the existing file instead. Project
instructions and the tutor contract are different things and both should apply.

Running `/init` later is safe: when a `CLAUDE.md` already exists, `/init` proposes improvements
rather than replacing it. Be aware that `/init` does read other tools' instruction files and
may fold some of that wording into `CLAUDE.md`, which can duplicate content but will not break
the import.

---

## Verifying it took

Start a **new** session in the target repo and say nothing but `hello`.

Claude should ask the three configuration questions — depth, pace, purpose — and then stop and
wait. If it starts working, or simply greets you back, the contract did not load.

Run `/context` and check the **Memory files** list. Both `CLAUDE.md` and `TUTOR.md` should be
there. If only `CLAUDE.md` is listed, the import is not firing — check that `@TUTOR.md` is on
its own line and not wrapped in backticks.

Other things worth checking:

- The session must be **new**. `CLAUDE.md` is read at session start, so a session that was
  already open when you installed will not see it.
- Claude must be launched from the repo root, where `CLAUDE.md` lives.

---

## On demand instead of always on

The import approach makes tutor mode **always on** for that repo. To invoke it explicitly with
`/tutor-kit` instead, install it as a skill:

```bash
mkdir -p ~/.claude/skills/tutor-kit
cp TUTOR.md ~/.claude/skills/tutor-kit/
```

In Windows PowerShell:

```powershell
New-Item -ItemType Directory -Force "$HOME\.claude\skills\tutor-kit" | Out-Null
Copy-Item TUTOR.md "$HOME\.claude\skills\tutor-kit\"
```

Then add `~/.claude/skills/tutor-kit/SKILL.md`:

```markdown
---
name: tutor-kit
description: Teaching contract for learn-while-building work. Explains before writing code, one unit per turn, comprehension questions, and a Built/Tested/Explained phase gate. Use when the user must be able to defend every line to a panel, interviewer, or reviewer.
---

Read TUTOR.md in this directory now and follow it for the rest of the session.
Start by asking the three configuration questions at the top of that file, and wait.
```

Skills installed under `~/.claude/skills/` are available in every project. The trade-off is that
you have to remember to invoke it.

---

## Other tools

This kit targets Claude Code. `TUTOR.md` is plain Markdown with no tool-specific syntax, so it
can be wired into other assistants by hand:

| Tool | File it auto-loads | Notes |
| --- | --- | --- |
| Codex CLI | `AGENTS.md` | repo root, or nested package directories. Hidden directories are not supported |
| Cursor | `.cursor/rules/*.mdc`, or legacy `.cursorrules` | repo root |
| Windsurf | `.windsurfrules` | repo root |
| Gemini CLI | `GEMINI.md` | repo root |
| Aider | a file passed with `--read`, or set in `.aider.conf.yml` | as configured |
| Anything else | paste `TUTOR.md` into the system prompt | that session only |

Those files need the contract text itself or their own pointer wording — `@TUTOR.md` is Claude
Code syntax and means nothing to them.

One interaction worth knowing: when a `CLAUDE.md` exists anywhere in the tree, Claude Code
reads it **instead of** `AGENTS.md`. So a repo set up for both tools works, but Claude will be
following `CLAUDE.md` while Codex follows `AGENTS.md`. Keep them consistent, or have
`CLAUDE.md` import `AGENTS.md`.

Filenames move as these tools change. If one stops working, check that tool's current docs —
the contract in `TUTOR.md` does not change, only the pointer does.

---

## Changing settings mid-session

Say so plainly: "switch to pace 3", "drop to depth A", "I'm in interview mode now". Claude
should restate the new setting in one line and carry on.
