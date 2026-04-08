# Marlin V3 Automation

End-to-end automation for Marlin V3 HITL tasks. Open this folder in Cursor, say "lets start a task" in the chat, and the AI handles PR selection, prompt generation, HFI orchestration, multi-turn feedback submission, evaluation drafting, and Snorkel submission guidance.

Your total manual effort: authenticate once, paste prompt into Snorkel, paste reflection into Snorkel. Everything else is automated.

---

## How It Works

The automation has three layers:

```
You (human)
  |
  |  say "lets start a task" or describe what you need
  v
Cursor AI (reads automation/playbook.md)
  |
  |  calls shell scripts, generates text, fills HFI forms via tmux
  v
Helper scripts + External systems
  - hfi_orchestrator.sh  -->  claude-hfi via tmux
  - pr_selector.sh       -->  GitHub via gh CLI
  - prompt_validator.py / eval_checker.py  -->  quality checks
```

**`automation/playbook.md`** is the brain. It contains all the Marlin V3 rules, evaluation criteria, and step-by-step procedures for every phase. **`.cursor/rules/marlin-workflow.mdc`** is what makes it automatic -- this Cursor rule loads on every chat session so the AI always knows about the playbook, the writing style rules in `docs/HUMANIZER_PROMPT.md`, and all trigger commands. No manual setup needed.

The shell scripts are mechanical helpers that Cursor calls on your behalf -- you rarely run them directly. `hfi_orchestrator.sh` (2700 lines) manages tmux sessions, launches HFI, injects prompts, monitors trajectories, fills feedback forms via keystrokes, and handles turn transitions. `pr_selector.sh` captures repo/PR URLs from your clipboard.

---

## Prerequisites

Install these before your first task:

| Tool | Install | Verify |
|------|---------|--------|
| Cursor IDE | https://cursor.com | Open the app |
| GitHub CLI | `brew install gh && gh auth login` | `gh auth status` |
| tmux | `brew install tmux` | `tmux -V` |
| Python 3.10+ | Usually pre-installed on macOS | `python3 --version` |
| claude-hfi | Download from https://feedback.anthropic.com/claude_code | `ls ~/Downloads/claude-hfi` or `ls ~/Downloads/darwin-arm64` |

Also needed:
- An **Anthropic account** authenticated with your **ALIAS email** (not Google sign-in)
- Python dependencies: `pip3 install -r automation/requirements.txt`

---

## First-Time Setup (2 minutes)

1. **Get the folder** -- clone or copy `Marlin_V3_Automation/` to your machine

2. **Open in Cursor** -- File > Open Folder > select `Marlin_V3_Automation`

3. **Thats it for Cursor setup.** The folder has a `.cursor/rules/` directory with rules that load automatically. When you open a Cursor chat in this workspace, the AI already knows about the playbook, the writing style rules, and all trigger commands. No manual configuration needed.

4. **Verify prerequisites:**
   ```bash
   gh auth status && tmux -V && python3 --version
   ```

5. **Install Python deps:**
   ```bash
   pip3 install -r automation/requirements.txt
   ```

Thats it. You're ready to run your first task.

---

## Doing a Task (End to End)

### The 30-second version

Say "lets start a task" in Cursor chat. Follow the prompts. Done in 2-4 hours.

### What actually happens

**Phase 1 -- Pick a PR** (~10 min)

1. Open Snorkel in your browser, browse the repository list
2. In Cursor chat, paste the repo URL and any available PRs (or share a screenshot of the Snorkel page)
3. Cursor fetches real data from GitHub via `gh` CLI, analyzes each PR against Marlin V3 criteria (complexity, language support, memorization risk, prompt category fit), and recommends the best one
4. You select and approve it on Snorkel

**Phase 2 -- Generate the prompt** (~15 min)

1. Cursor fetches the full PR diff, file tree, review comments, and repo metadata from GitHub
2. Generates all 8 Snorkel Prompt Preparation fields: Repo Definition, PR Definition, Prompt Category, Prompt Sub-Type, Edge Cases, Acceptance Criteria, Estimated Time, and Initial Prompt
3. All text follows built-in humanizing style rules so it scores low on AI detection
4. Validates the prompt with `prompt_validator.py` (checks word count, em-dashes, PR references, role prompting, LLM signature words)
5. You copy the fields into Snorkel's Prompt Preparation form and submit for approval

**Phase 3 -- Set up environment** (~10 min)

1. Cursor clones the repo and checks out the pre-PR commit state
2. Copies the `claude-hfi` binary into the repo directory
3. Cursor generates a `CLAUDE.md` file (repo overview, dev setup, testing commands, architecture, conventions). This is done BEFORE launching HFI so both trajectories automatically have it
4. Launches HFI inside a dedicated tmux session (provides proper TTY that HFI requires)
5. **You authenticate** - a browser window opens, log in with your ALIAS email (this is the one-time manual step per session)
6. Cursor fills the Pre-Thread Survey (repo URL, PR URL, HEAD commit hash)

**Phase 4-7 -- Execute 3 turns** (~1-2 hours, mostly waiting)

For each of the 3 turns, the automation:

1. Injects the prompt into the HFI control pane via `tmux load-buffer` / `tmux paste-buffer`
2. Both trajectories (Model A and Model B) run independently in separate tmux sessions
3. Monitors by polling tmux panes every 30 seconds until both trajectories complete or the feedback form appears
4. Captures full trajectory traces and diffs from both worktrees
5. Compares the two trajectories -- analyzes correctness, completeness, code quality, test execution, scope adherence
6. Generates detailed feedback text (senior expectations, strengths/weaknesses for each model, 11 axis ratings with justification)
7. Fills the HFI feedback TUI form by sending keystrokes via tmux
8. Verifies the submission file exists and is the right size (>10KB)
9. Exits HFI (`Ctrl+C`), relaunches with `--continue`, runs `/clear` to reset context
10. Generates the next turn's follow-up prompt (targeting edge cases, then cleanup)

After Turn 3, selects "Finish conversation", fills thread feedback, and HFI exits.

**You may need to** approve permission prompts if they appear in the trajectory tmux sessions (type `y` in the tmux pane).

**Phase 8 -- Submit on Snorkel** (~5 min)

1. Cursor gives you all the pre-filled Reflection field values: PR URL, HEAD commit, CLAUDE.md source, prompt type, time estimates, task reflection text
2. You paste them into the Snorkel platform and click Submit

### Human actions total: 4

1. HFI browser authentication (once per session)
2. Approve trajectory permission prompts (if any pop up in tmux)
3. Paste prompt package into Snorkel and submit (Phase 2)
4. Paste reflection values into Snorkel and submit (Phase 8)

---

## Project Structure

```
Marlin_V3_Automation/
|
|-- README.md                              # You are here
|
|-- docs/                                  # All documentation
|   |-- TROUBLESHOOTING.md               # HFI debug guide (9 common issues + manual fixes)
|   |-- HUMANIZER_PROMPT.md              # Copy-paste prompt for low AI-detection text
|   +-- reference/                        # Official Marlin docs (read-only reference)
|       |-- marlin_v3_guide.md           # Complete Marlin V3 execution manual
|       |-- hfi_cli_docs.md              # HFI CLI reference (changelog, modes, env vars)
|       +-- training/                     # 7 topic-specific training guides
|           |-- Marlin_V3_PR_Selection_Guide.txt
|           |-- Marlin_V3_Prompt_Preparation_Guide.txt
|           |-- Marlin_V3_CLI_Setup_Guide.txt
|           |-- Marlin_V3_PR_Creation_Guide.txt
|           |-- Marlin_V3_Common_Mistakes_Guide.txt
|           |-- Marlin_V3_Whats_New_Guide.txt
|           +-- Marlin_V3_Submission_Checker_Guide.txt
|
|-- automation/                            # All automation code
|   |-- playbook.md                       # THE BRAIN -- 1890 lines of workflow logic
|   |-- hfi_orchestrator.sh              # HFI/tmux orchestrator (2700 lines)
|   |-- pr_selector.sh                   # PR selection + clipboard capture (268 lines)
|   |-- prompt_validator.py              # Prompt quality checker (318 lines)
|   |-- eval_checker.py                  # Evaluation quality checker (670 lines)
|   |-- clipboard_watcher.py            # System clipboard URL capture (185 lines)
|   |-- requirements.txt                # Python deps (stdlib only)
|   +-- data/                            # Runtime artifacts (gitignored)
|       +-- .gitkeep                     # Keeps empty dir in version control
|
+-- .gitignore
```

### What each file does

| File | Role | When its used |
|------|------|--------------|
| `automation/playbook.md` | Contains all Marlin V3 rules, writing style guides, evaluation criteria, 6 trigger workflows, turn prompt templates, scenario handbook | Every interaction -- Cursor reads this as its instruction set |
| `automation/hfi_orchestrator.sh` | Manages tmux sessions, launches/kills HFI, injects prompts via paste-buffer, monitors trajectories, fills feedback TUI forms, handles turn transitions, diagnoses failures, retries failed turns | Phases 3-7 -- called by Cursor automatically |
| `automation/pr_selector.sh` | Captures repo/PR URLs from system clipboard, runs prompt validator | Phase 1 -- called by Cursor automatically |
| `automation/prompt_validator.py` | Checks prompts for em-dashes, PR number references, role prompting, over-prescriptive language, LLM signature words, word count (150-300 target) | Phase 2 -- validates every generated prompt |
| `automation/eval_checker.py` | Validates evaluation writeups for structural completeness (11 axes, 5 text fields), rating consistency, content quality, cross-turn prompt overlap, anti-rejection rules | Phase 6 -- validates evaluation before submission |
| `automation/clipboard_watcher.py` | Polls system clipboard every 0.5s, parses URLs, appends to `data/live_repos.json` or `data/live_prs.json` | Phase 1 -- called by pr_selector.sh |
| `docs/TROUBLESHOOTING.md` | 9 common HFI failure modes with manual diagnosis and fixes. Covers missing Snorkel turns, upload timeouts, trajectory spawn failures, context limits, auth, worktree corruption. Usable without the automation scripts | When things break |
| `docs/HUMANIZER_PROMPT.md` | Standalone system prompt to paste into any AI tool for text that bypasses AI detection. 11 style rules + before/after examples | When writing text manually outside the automation |
| `docs/reference/marlin_v3_guide.md` | Official Marlin V3 manual covering all 8 phases, 14 prompt categories, evaluation axes, submission rules | Reference -- the automation encodes these rules in the playbook |
| `docs/reference/hfi_cli_docs.md` | Official claude-hfi CLI documentation: `--vscode` vs `--tmux` modes, `CLAUDE_ENV_FILE`, worktrees, proxy setup, changelog | Reference -- for understanding HFI internals |

---

## Cursor Triggers

Type these in Cursor chat to start a workflow:

| What you say | What happens | When to use |
|---------|-------------|-------------|
| "lets start a task" / "new task" | Walks through all 8 phases end-to-end | **Starting a new task from scratch (use this one)** |
| "resume" / "continue" | Reads saved state and jumps to the right phase | Picking up after closing Cursor or hitting an error |
| "automate the rest" / "take it from here" | Runs Turns 2-3, evaluation, quality checks, submission guidance | After Turn 1 is complete |
| "generate the prompt" / "prepare the prompt" | Fetches PR data and generates all Snorkel Prompt Preparation fields | When you already know which PR you want |
| "analyze these repos" | Reads `data/live_repos.json` and ranks repos against Marlin criteria | Phase 1 repo analysis only |
| "analyze these PRs" | Reads `data/live_prs.json` and ranks PRs against Marlin criteria | Phase 1 PR analysis only |

For most people, "lets start a task" is all you need.

---

## Why tmux Mode (Not VS Code Mode)

HFI supports two modes: `--vscode` (opens VS Code windows for each trajectory) and `--tmux` (runs everything in tmux sessions). This automation requires **tmux mode** because it automates the feedback form filling and prompt injection via `tmux send-keys` / `tmux load-buffer` commands. These tmux commands cant reach a regular terminal (which is what VS Code mode uses for the control pane).

**If you previously used `--vscode` mode**, the switch is one flag:

```bash
# Instead of:
claude-hfi --vscode

# Use:
claude-hfi --tmux
```

Everything else is identical: same auth, same prompts, same feedback forms, same worktrees, same multi-turn workflow. You can still open the worktree folders (`~/.cache/claude-hfi/<project>/A` and `B`) in VS Code or any editor to review code visually.

| Aspect | tmux mode (this automation) | VS Code mode |
|--------|----------------------------|--------------|
| Launch command | `claude-hfi --tmux` | `claude-hfi --vscode` |
| Control pane | tmux session | Regular terminal |
| Automated form filling | Yes | No |
| Automated prompt injection | Yes | No |
| Code review | `git diff` or open files in any editor | VS Code diff viewer |

For detailed onboarding steps, see `docs/ONBOARDING.md`.

---

## Environment File (CLAUDE_ENV_FILE)

For **Python projects** with a virtual environment, HFI needs to know how to activate it. Without this, model trajectories cant import packages or run tests.

Create an activation script before the automation launches HFI:

```bash
echo 'source /path/to/your/repo/.venv/bin/activate' > /tmp/claude_env.sh
export CLAUDE_ENV_FILE=/tmp/claude_env.sh
```

The automation detects this and passes it through to tmux. When `CLAUDE_ENV_FILE` is set, HFI sources it before every bash command in both trajectories.

For JavaScript/TypeScript projects this isnt needed -- node/yarn are in the system PATH.

---

## Commands Reference

The automation calls these for you. Listed here for debugging or manual operation.

### PR Selection (`pr_selector.sh`)

```bash
bash automation/pr_selector.sh repos                    # Capture repo URLs from clipboard
bash automation/pr_selector.sh prs                      # Capture PR URLs from clipboard
bash automation/pr_selector.sh validate "prompt text"   # Check prompt quality
bash automation/pr_selector.sh status                   # Show data state
bash automation/pr_selector.sh clean                    # Reset for fresh start
```

### HFI Orchestration (`hfi_orchestrator.sh`)

```bash
bash automation/hfi_orchestrator.sh setup ~/Downloads/repo.tar     # Unpack + git init + deps
bash automation/hfi_orchestrator.sh launch /path/to/repo            # Copy HFI binary + start tmux
bash automation/hfi_orchestrator.sh claude-md /path/to/repo         # Generate CLAUDE.md (BEFORE launch)
bash automation/hfi_orchestrator.sh copy-claude-md                  # Copy to A/B worktree caches
bash automation/hfi_orchestrator.sh inject prompt.txt               # Inject prompt into HFI control
bash automation/hfi_orchestrator.sh monitor                         # Watch trajectories (2hr timeout)
bash automation/hfi_orchestrator.sh fill-feedback <file> [session]  # Auto-fill HFI feedback TUI
bash automation/hfi_orchestrator.sh next-turn                       # Exit HFI + relaunch --continue + /clear
bash automation/hfi_orchestrator.sh diagnose                        # Health check sessions + submission files
bash automation/hfi_orchestrator.sh retry-turn <N>                  # Delete turn N state + relaunch HFI
bash automation/hfi_orchestrator.sh status                          # Show current phase3 state
bash automation/hfi_orchestrator.sh full <tarball> <prompt>         # All-in-one pipeline
```

---

## Common Gotchas

- **Must exit HFI between turns** -- the automation handles this automatically. If doing anything manually: `Ctrl+C` to exit, then `./claude-hfi --tmux --continue`, then `/clear`
- **Never manually `git commit`** inside HFI worktrees -- HFI manages all git state. Manual commits corrupt trajectory tracking
- **ALIAS email for auth** -- use your Alias email at the Anthropic login page, not Google sign-in. This is critical
- **CLAUDE.md goes BEFORE HFI launch** - create CLAUDE.md after setup but before launching HFI. This way both trajectories automatically have it when HFI creates worktrees. Per official Snorkel training docs
- **Turns missing from Snorkel** -- usually a submission upload timeout. Run `bash automation/hfi_orchestrator.sh diagnose` or see `docs/TROUBLESHOOTING.md`
- **"Raw mode not supported"** -- HFI wasnt launched inside tmux. The automation handles this, but if manual: `tmux new-session -d -s hfi './claude-hfi --tmux'`
- **Context limit reached** -- one trajectory used all its context. Note it in feedback as a weakness. The other trajectory is usually fine
- **Trajectory stuck** -- check its tmux session (`tmux attach -t <session-id>-A`). It might be waiting for you to type `y` to approve a tool action
- **CLAUDE_ENV_FILE for Python** -- if trajectories cant find packages, you forgot to set the environment file (see section above)

---

## If Something Goes Wrong

1. **Run diagnosis:** `bash automation/hfi_orchestrator.sh diagnose` -- checks tmux session health, submission file sizes, debug log errors/timeouts
2. **Check the guide:** `docs/TROUBLESHOOTING.md` -- covers 9 common problems with step-by-step manual fixes, usable even without the automation
3. **Retry a failed turn:** `bash automation/hfi_orchestrator.sh retry-turn N` -- deletes turn N state files and relaunches HFI
4. **Check tmux sessions:** `tmux ls` to see whats running, `tmux attach -t <name>` to inspect
5. **If all else fails:** share the output of `diagnose` in the team channel

---

## Quick Start Checklist

```
[ ] Cursor installed and open
[ ] gh CLI authenticated (gh auth status)
[ ] tmux installed (tmux -V)
[ ] Python 3.10+ installed (python3 --version)
[ ] claude-hfi binary in ~/Downloads/
[ ] Python deps installed (pip3 install -r automation/requirements.txt)
[ ] Cursor rules auto-loaded (happens automatically when you open the folder)
[ ] Say "lets start a task" in Cursor chat
[ ] Follow the prompts
```
