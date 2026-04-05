# Marlin V3 Automation

End-to-end automation for Marlin V3 HITL tasks. Open this folder in Cursor, type `[start-full-task]` in the chat, and the AI handles PR selection, prompt generation, HFI orchestration, multi-turn feedback submission, evaluation drafting, and Snorkel submission guidance.

Your total manual effort: authenticate once, paste prompt into Snorkel, paste reflection into Snorkel. Everything else is automated.

---

## How It Works

The automation has three layers:

```
You (human)
  |
  |  type trigger commands like [start-full-task]
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

**`automation/playbook.md`** is the brain. It's a 1670-line instruction file that contains all the Marlin V3 rules, writing style guidelines, evaluation criteria, and step-by-step procedures for every phase. When you type a trigger like `[start-full-task]` in Cursor chat, the AI reads this file and follows it exactly.

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

3. **Load the playbook into Cursor.** The automation only works if Cursor can read `automation/playbook.md`. Two ways:
   - **Option A (recommended):** Add it as a Cursor Rule -- go to Cursor Settings > Rules > add the path `automation/playbook.md`
   - **Option B:** Keep the file open in a tab whenever you chat with Cursor

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

Type `[start-full-task]` in Cursor chat. Follow the prompts. Done in 2-4 hours.

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
3. Launches HFI inside a dedicated tmux session (provides proper TTY that HFI requires)
4. **You authenticate** -- a browser window opens, log in with your ALIAS email (this is the one-time manual step per session)
5. Cursor fills the Pre-Thread Survey (repo URL, PR URL, HEAD commit hash)
6. After HFI launches, Cursor generates a `CLAUDE.md` file (repo overview, dev setup, testing commands, architecture, conventions) and copies it to both trajectory worktree caches at `~/.cache/claude-hfi/.../A/` and `B/`

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
|   |-- playbook.md                       # THE BRAIN -- 1670 lines of workflow logic
|   |-- hfi_orchestrator.sh              # HFI/tmux orchestrator (2700 lines)
|   |-- pr_selector.sh                   # PR selection + clipboard capture (269 lines)
|   |-- prompt_validator.py              # Prompt quality checker (278 lines)
|   |-- eval_checker.py                  # Evaluation quality checker (633 lines)
|   |-- clipboard_watcher.py            # System clipboard URL capture (186 lines)
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

| Trigger | What it does | When to use |
|---------|-------------|-------------|
| `[start-full-task]` | Walks through all 8 phases end-to-end with `[AUTOMATION]` / `[YOUR TURN]` markers | **Starting a new task from scratch (use this one)** |
| `[resume-task]` | Reads `data/task_state.json` and jumps to the right phase | Picking up after closing Cursor or hitting an error |
| `[auto-complete-task]` | Runs Turns 2-3, evaluation, quality checks, and submission guidance | After Turn 1 is manually complete |
| `[prepare-prompt]` | Fetches PR data and generates all 8 Snorkel Prompt Preparation fields | When you already know which PR you want |
| `[analyze-repos]` | Reads `data/live_repos.json` and ranks repos against Marlin criteria | Phase 1 repo analysis only |
| `[analyze-prs]` | Reads `data/live_prs.json` and ranks PRs against Marlin criteria | Phase 1 PR analysis only |

For most people, `[start-full-task]` is all you need.

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
bash automation/hfi_orchestrator.sh claude-md /path/to/repo         # Generate CLAUDE.md (AFTER launch)
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
- **CLAUDE.md goes AFTER HFI launch** -- launch HFI first, then create CLAUDE.md, then copy to A/B caches. The Marlin V3 guide is explicit about this order
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
[ ] automation/playbook.md loaded as Cursor Rule or open in tab
[ ] Type [start-full-task] in Cursor chat
[ ] Follow the prompts
```
