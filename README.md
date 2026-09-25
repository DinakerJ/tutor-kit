# tutor-kit

A teaching contract for AI coding assistants, for when you need to **understand** the code, not
just have it.

Drop it into a repo and the assistant stops writing code at you. It explains the idea first,
works one small piece at a time, asks you a question after each piece, and waits for your
answer before continuing.

Works with Claude Code, Codex, Cursor, Windsurf, Gemini CLI, and anything else that reads a
file.

---

## The problem

An AI assistant can produce a working feature faster than you can read it. That is fine until
someone asks you to defend it — in a code review, a design discussion, an interview, or a panel.
Then the code being correct is not enough. You have to know why it is shaped that way, what it
assumes, and what breaks if the assumptions fail.

The default behaviour of every assistant works against this. Ask a question, get a code block.
Say "ok", get three more files. Nothing stops to check whether you followed.

`tutor-kit` inverts that.

---

## Quickstart

**macOS, Linux, WSL, or Git Bash**

```bash
git clone https://github.com/DinakerJ/tutor-kit.git
cd tutor-kit
./install.sh /path/to/your/repo
```

Or without cloning:

```bash
curl -fsSL https://raw.githubusercontent.com/DinakerJ/tutor-kit/main/install.sh | bash -s -- .
```

**Windows PowerShell**

Run this from inside the repo you want to install into:

```powershell
irm https://raw.githubusercontent.com/DinakerJ/tutor-kit/main/install.ps1 | iex
```

Or from a clone, naming the target:

```powershell
git clone https://github.com/DinakerJ/tutor-kit.git
cd tutor-kit
powershell -ExecutionPolicy Bypass -File .\install.ps1 C:\path\to\your\repo
```

Use `install.ps1` here, not the `curl | bash` line above. In Windows PowerShell `curl` is an
alias for `Invoke-WebRequest`, which rejects `-fsSL`, and `bash` is not on `PATH` even when Git
for Windows is installed. The two installers write byte-identical files, so it makes no
difference which one a repo was set up with.

Then open your repo in any AI coding tool and say `hello`. It should ask you three
configuration questions and wait. If it starts working instead, the file was not picked up —
check that you ran the install against the repo root.

---

## What gets installed

```
your-repo/
├── TUTOR.md          the contract itself
├── CLAUDE.md         ┐
├── AGENTS.md         │  two-line pointers, one per tool,
├── GEMINI.md         │  each saying "read TUTOR.md"
├── .cursorrules      │
└── .windsurfrules    ┘
```

One source of truth, thin pointers. Every tool auto-loads a different filename, so rather than
maintain five copies that drift apart, each tool gets a one-line file telling it where to look.

If a pointer file already exists in your repo, the installer leaves it alone and tells you what
line to add yourself. Your existing project instructions and this contract are different things
and both should apply.

---

## Configuring it

The contract is not one fixed behaviour. It asks you three questions at the start of every
session and adapts.

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
- **Validate your reading first.** When you say what you think the code does, the assistant
  judges your claims point by point *before* adding anything new. Otherwise a fresh explanation
  talks past you and you cannot tell which parts of your model survived.
- **"ok" is not understanding.** The assistant does not advance on acknowledgement. It asks a
  real question and waits.
- **Name the file and line** an explanation comes from. And say so explicitly when the thing
  being discussed does not exist yet.
- **Loud versus silent failures.** When a bug turns up, the walkthrough states which kind it is,
  because the silent ones are the ones that cost you days.
- **Plain language.** A banned-words list, and a rule to replace computer-science vocabulary
  with plain description.
- **Commit messages describe the code**, not the tutoring. Someone may read the log to judge
  your work.

---

## The phase gate

At depth `B` or `C`:

> A phase is complete only when **Built and Tested and Explained-back-by-you**.

Two of three is not complete. Working code you cannot explain does not pass. **Only you can
mark *Explained*** — the assistant may never infer it, and may never mark it on your behalf.

Progress lives in a single `PROGRESS.md` holding both the plan and the ledger, because a
phase's checklist is its tracker.

---

## Claude Code: on demand instead

The install above makes the contract always on for that repo. If you would rather invoke it
explicitly with `/tutor-kit`:

```bash
mkdir -p ~/.claude/skills/tutor-kit
cp TUTOR.md INSTALL.md install.sh install.ps1 ~/.claude/skills/tutor-kit/
```

In Windows PowerShell:

```powershell
New-Item -ItemType Directory -Force "$HOME\.claude\skills\tutor-kit" | Out-Null
Copy-Item TUTOR.md, INSTALL.md, install.sh, install.ps1 "$HOME\.claude\skills\tutor-kit\"
```

Then create `~/.claude/skills/tutor-kit/SKILL.md` containing a YAML header and a pointer:

```markdown
---
name: tutor-kit
description: Teaching contract for learn-while-building work. Explains before writing code, one unit per turn, comprehension questions, Built/Tested/Explained gate. Use when the user must be able to defend every line.
---

Read `TUTOR.md` in this skill's directory now and follow it for the rest of the session.
Start by asking the three configuration questions at the top of that file, and wait.
```

The trade-off is that you have to remember to type it. Always-on cannot be forgotten, which
matters more than it sounds — the sessions where you forget are exactly the ones where you end
up with code you cannot explain.

---

## Tool support

| Tool | File it reads | Installed by default |
|---|---|---|
| Claude Code | `CLAUDE.md` | yes |
| Codex CLI | `AGENTS.md` | yes |
| Gemini CLI | `GEMINI.md` | yes |
| Cursor | `.cursorrules` | yes |
| Windsurf | `.windsurfrules` | yes |
| Aider | passed via `--read` or `.aider.conf.yml` | manual |
| Anything else | paste `TUTOR.md` into the system prompt | manual |

For manual wiring, per-tool detail, and what to do when a filename changes, see
[INSTALL.md](INSTALL.md).

These filenames move as the tools change. If one stops working, check that tool's current docs
— the contract does not change, only the pointer does.

---

## Origin

Written while building a graded capstone project that had to be defended to a panel. The rules
are not theoretical; each one exists because its absence caused a specific problem — code that
worked and could not be explained, a correction that talked past the misunderstanding, a phase
marked done on the strength of someone saying "ok".

## License

MIT. See [LICENSE](LICENSE).
