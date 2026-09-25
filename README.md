# tutor-kit

A teaching contract for **Claude Code**, for when you need to understand the code, not just
have it.

Drop it into a repo and Claude stops writing code at you. It explains the idea first, works one
small piece at a time, asks you a question after each piece, and waits for your answer before
continuing.

---

## The problem

Claude can produce a working feature faster than you can read it. That is fine until someone
asks you to defend it — in a code review, a design discussion, an interview, or a panel. Then
the code being correct is not enough. You have to know why it is shaped that way, what it
assumes, and what breaks if the assumptions fail.

The default behaviour works against this. Ask a question, get a code block. Say "ok", get three
more files. Nothing stops to check whether you followed.

`tutor-kit` inverts that.

---

## Quickstart

Two installers, same result, byte-identical output. Pick the one matching the shell you are
typing into — they are **not** interchangeable.

| If your prompt looks like | You are in | Use |
| --- | --- | --- |
| `PS C:\Users\you\repo>` | Windows PowerShell | `install.ps1` |
| `you@host:~/repo$` | macOS, Linux, WSL, Git Bash | `install.sh` |

### Windows PowerShell

`cd` into the repo you want to install into, then:

```powershell
irm https://raw.githubusercontent.com/DinakerJ/tutor-kit/main/install.ps1 | iex
```

Or from a clone, naming the target explicitly:

```powershell
git clone https://github.com/DinakerJ/tutor-kit.git
cd tutor-kit
powershell -ExecutionPolicy Bypass -File .\install.ps1 "C:\path\to\your\repo"
```

Quote the path if it contains spaces or an apostrophe.

> ⚠️ **The `curl ... | bash` line below does not work in PowerShell.** It fails with
> `bash : The term 'bash' is not recognized`. That is expected, and no change to this repo can
> fix it — there are two independent reasons. `curl` in Windows PowerShell is an alias for
> `Invoke-WebRequest`, which rejects `-fsSL`; and `bash` is not on `PATH`, even when Git for
> Windows is installed, because the installer only adds `Git\cmd` (which holds `git.exe`, not
> `bash.exe`). Use `install.ps1` above.

### macOS, Linux, WSL, or Git Bash

```bash
git clone https://github.com/DinakerJ/tutor-kit.git
cd tutor-kit
./install.sh /path/to/your/repo
```

Or without cloning:

```bash
curl -fsSL https://raw.githubusercontent.com/DinakerJ/tutor-kit/main/install.sh | bash -s -- .
```

---

## What gets installed

```
your-repo/
├── TUTOR.md          the contract itself
└── CLAUDE.md         four lines that import it
```

Two files. `CLAUDE.md` is not a summary of the contract — it is an **import** of it:

```markdown
# Operating contract

@TUTOR.md
```

That `@TUTOR.md` line matters more than it looks. Claude Code expands `@path` imports into
context when the session starts, so the full contract is loaded and in front of Claude before
you type anything. Relative paths resolve against the file holding the import, and imports
nest up to four hops deep.

> **Do not put the filename in backticks.** Claude Code's import parser deliberately skips
> Markdown code spans and fenced code blocks, so `` `@TUTOR.md` `` imports nothing. A
> `CLAUDE.md` that merely *asks* Claude to go read `TUTOR.md` leaves the contract to chance:
> sometimes Claude reads it, sometimes it just says hello back. The unquoted import is what
> makes the behaviour deterministic.

If `CLAUDE.md` already exists, the installer leaves it alone and prints the line to add
yourself. Your project instructions and this contract are different things and both should
apply — they are concatenated into context, not overridden.

---

## Verifying it took

Start a **new** session in the target repo and say nothing but `hello`.

Claude should reply by asking the three configuration questions — depth, pace, purpose — and
then stop and wait. If it starts working, or greets you back, something did not load.

| Symptom | Cause | Fix |
| --- | --- | --- |
| Greets you back, no questions | `CLAUDE.md` mentions `TUTOR.md` in backticks instead of importing it | Replace the mention with a bare `@TUTOR.md` line, or re-run the installer |
| No questions at all | The session was already open when you installed | `CLAUDE.md` loads at session start, so start a new session |
| No questions at all | Claude was launched from a subdirectory or a parent | Run it from the repo root, where `CLAUDE.md` lives |

To see exactly what loaded, run `/context` in a session and check the **Memory files** list.
Both `CLAUDE.md` and `TUTOR.md` should appear.

---

## Configuring it

The contract is not one fixed behaviour. It asks three questions at the start of every session
and adapts.

**Contract depth**

| | |
|---|---|
| `A` | Teaching style only |
| `B` | Style plus a Built / Tested / Explained phase gate *(recommended)* |
| `C` | Style, phase gate, and a defect ledger with a bug-walkthrough protocol |

**Pace**

| | |
|---|---|
| `1` | One unit, one question, wait. Thorough |
| `2` | Whole topic, then a quiz block. Faster |
| `3` | Scenario-driven. You attempt the problem first, concepts arrive as needed |

**Purpose**

| | |
|---|---|
| `X` | Real work — defensible decisions, failure modes, correct sizing |
| `Y` | Interview or exam — perform under time pressure |
| `Z` | Depth — no deadline, rabbit holes allowed |

Change any of them mid-session by saying so.

---

## What the contract actually enforces

A selection. The full text is in [`TUTOR.md`](TUTOR.md).

- **Explain before writing.** Never opens with a code block.
- **Every line gets explained.** Not a summary of what a block does — the actual constructs,
  calls, and choices.
- **Validate your reading first.** When you say what you think the code does, Claude judges
  your claims point by point *before* adding anything new. Otherwise a fresh explanation talks
  past you and you cannot tell which parts of your model survived.
- **"ok" is not understanding.** It does not advance on acknowledgement. It asks a real
  question and waits.
- **Name the file and line** an explanation comes from. And say so explicitly when the thing
  being discussed does not exist yet.
- **Loud versus silent failures.** When a bug turns up, the walkthrough states which kind it
  is, because the silent ones are the ones that cost you days.
- **Plain language.** A banned-words list, and a rule to replace computer-science vocabulary
  with plain description.
- **Commit messages describe the code**, not the tutoring. Someone may read the log to judge
  your work.

---

## The phase gate

At depth `B` or `C`:

> A phase is complete only when **Built and Tested and Explained-back-by-you**.

Two of three is not complete. Working code you cannot explain does not pass. **Only you can
mark *Explained*** — Claude may never infer it, and may never mark it on your behalf.

Progress lives in a single `PROGRESS.md` holding both the plan and the ledger, because the
checklist for a phase is its tracker.

---

## On demand instead of always on

The install above makes the contract always on for that repo. If you would rather invoke it
explicitly with `/tutor-kit`:

```bash
mkdir -p ~/.claude/skills/tutor-kit
cp TUTOR.md ~/.claude/skills/tutor-kit/
```

In Windows PowerShell:

```powershell
New-Item -ItemType Directory -Force "$HOME\.claude\skills\tutor-kit" | Out-Null
Copy-Item TUTOR.md "$HOME\.claude\skills\tutor-kit\"
```

Then create `~/.claude/skills/tutor-kit/SKILL.md`:

```markdown
---
name: tutor-kit
description: Teaching contract for learn-while-building work. Explains before writing code, one unit per turn, comprehension questions, Built/Tested/Explained gate. Use when the user must be able to defend every line.
---

Read TUTOR.md in this directory now and follow it for the rest of the session.
Start by asking the three configuration questions at the top of that file, and wait.
```

Skills under `~/.claude/skills/` are available in every project. The trade-off is that you have
to remember to type it. Always-on cannot be forgotten, which matters more than it sounds — the
sessions where you forget are exactly the ones where you end up with code you cannot explain.

---

## Other tools

This kit targets Claude Code. `TUTOR.md` itself is plain Markdown with no tool-specific syntax,
so it works anywhere a file can be handed to a model — Codex via a root `AGENTS.md`, Cursor via
`.cursor/rules/`, or pasted straight into a system prompt. Wiring those up is manual for now;
see [INSTALL.md](INSTALL.md).

Earlier versions of this kit wrote pointer files for five tools. The installer now detects
those leftovers and tells you they are safe to delete.

---
