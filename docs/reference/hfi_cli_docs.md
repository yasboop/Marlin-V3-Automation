# Custom Claude Code Setup Instructions

## Table of Contents

- [Changelog](#changelog)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Workflow: VS Code Mode (--vscode) - Recommended](#workflow-vs-code-mode---vscode---recommended)
- [Workflow: All-in-One Tmux Session (--tmux)](#workflow-all-in-one-tmux-session---tmux)
- [Git Worktrees](#git-worktrees)
- [Virtual Environment Setup](#virtual-environment-setup)
- [Proxy and SSL Certificate Configuration](#proxy-and-ssl-certificate-configuration)
- [Feedback Form](#feedback-form)
- [Winner Syncing](#winner-syncing)
- [Multi-Turn Sessions](#multi-turn-sessions)
- [Troubleshooting](#troubleshooting)
- [Which Mode Should I Use?](#which-mode-should-i-use)
- [Tips](#tips)

---

## Changelog

### New in 2.1.85
- Based on Claude Code v2.1.85 codebase.
- Trajectories now fail fast on tool result issues (missing results, placeholder content) instead of continuing to submission. You'll see the error immediately rather than after completing feedback.
- One-time project backfill: on first launch of this version, HFI uploads your full `~/.claude-hfi/projects/` directory (session transcript JSONLs) to recover clean transcripts that were affected by the tool-result pairing issue. A marker file ensures this runs exactly once per machine. Skip with `CLAUDE_CODE_SKIP_PROJECT_BACKFILL=1` if needed.
- Feedback form keyboard handling migrated to the newer input system for improved reliability across terminal emulators.
- Manifest checksums are now regenerated after macOS binary signing, so the published manifest matches the actual downloaded binaries.

### New in 2.1.80
- Based on Claude Code v2.1.80 codebase.
- Submissions with unpaired tool_use blocks now fail locally with a clear error (listing the offending IDs) instead of silently injecting `[Tool result missing]` placeholders into training data. With upstream parallel-tool fixes this should almost never fire; if it does, it indicates a real trajectory bug to investigate.

### New in 2.1.77
- Based on Claude Code v2.1.77 codebase.
- Fixed "interrupted" crash that occurred with newer experiment configurations using system prompt registry references or adaptive thinking.
- Fixed a resume failure for sessions that had saved experiment config but not yet completed a turn.

### New in 2.1.70
- Based on Claude Code v2.1.70 codebase.
- Fixed an issue where submitting feedback twice during upload could skip step indices and cause errors.

### New in 2.1.45
- Based on Claude Code v2.1.45 codebase.
- Fixed an issue where feedback questions were not displayed correctly.

### New in 2.1.41
- Repo snapshot upload: at session start, HFI uploads a git bundle and working tree tar so reviewers can reconstruct the exact starting repo state. Bundles are cached and only re-uploaded when new commits exist.
- Finish conversation option: after submitting per-comparison feedback, you can now choose "Continue conversation" or "Finish conversation" instead of auto-advancing. If configured, finishing shows a post-thread survey.
- Graceful exit from any screen: Ctrl+C / Ctrl+D now works to exit from auth, interface code entry, and loading screens.
- Fixed 400 errors on feedback submission caused by a race condition where trajectory results were signaled before the transcript was fully written to disk.
- Fixed tool result pairing in trajectory submissions.

### New in 2.1.31
- Tags and rating feedback fields: feedback forms now support `tags` (multi-select checkboxes) and `rating` (5-point scale) field types
- Pre-thread survey: experiments can now define a survey that appears before the first prompt
- Double-press Ctrl+C to exit: prevents accidental session termination
- Success confirmation: green checkmark after feedback submission
- Local submission logging: payloads saved to `submission-step-N.json` for debugging
- Fixed tool result pairing in trajectory submissions
- Fixed parallel tool call handling: split messages now correctly merged before submission
- Fixed user message duplication when resuming sessions

### New in 2.0.70 (GA)
- Added version check before starting HFI session - errors if a newer version is available
- Trajectory diffs are now uploaded as attachments with feedback for better analysis
- Fixed authentication issues in vscode/tmux modes
- Improved debugging output
- Fixed OAuth UI disappearing before completion
- Fixed "Cannot strip metadata from message type: system" error during feedback submission

### New in Beta RC 3
- Fixed compaction being enabled
- Fixed "Cannot strip metadata from message type..." error
- Changed default config directory to ~/.claude-hfi to prevent conflicts with production Claude Code builds
- Fixed issue with subagents

---

## Prerequisites

### Git Repository Root

HFI must be run from the root of a git repository. Before starting:

```bash
# Check if you're at the git root
git rev-parse --show-toplevel
# Should match your current directory

# If you're in a subdirectory, navigate to the root
cd $(git rev-parse --show-toplevel)
```

HFI uses git worktrees to create isolated environments for each model comparison. Running from a subdirectory will cause the winner's changes to be incorrectly applied.

### Tmux (Required)

HFI requires tmux to run the trajectory processes. Many computers already have tmux installed, but it can be added:

```bash
# macOS
brew install tmux

# Linux (Ubuntu/Debian)
apt-get install tmux

# Linux (RHEL/CentOS)
yum install tmux
```

---

## Quick Start

Download the appropriate version for your Mac or Linux computer from [https://feedback.anthropic.com/claude_code](https://feedback.anthropic.com/claude_code)

After downloading, rename the file and make it executable:

```bash
mv ~/Downloads/<image-name> claude-hfi
chmod +x claude-hfi
```

For most users, you'll want to choose one of these two modes:

```bash
# VS Code mode (recommended) - visual file comparison + integrated terminals
claude-hfi --vscode

# All-in-one tmux session - everything in one session, easy window switching
claude-hfi --tmux
# Or auto-attach to the session:
$(claude-hfi --tmux)
```

Most (but not all) of the features of Claude Code will work in this custom build. For more about getting started with Claude Code, see [here](https://code.claude.com/docs/en/overview).

Run `claude-hfi --help` to see all available CLI options.

**Advanced users only:**

```bash
# Separate sessions mode - control in terminal, trajectories in separate tmux sessions
# This mode requires managing multiple tmux sessions manually
claude-hfi
```

---

## Workflow: VS Code Mode (--vscode) - Recommended

When you run `claude-hfi --vscode`, HFI opens VS Code instances for each trajectory worktree, while control runs in your current terminal:

### Layout

```
Your terminal:              Control (you interact here)

VS Code windows:
├── Window 1:              Trajectory A worktree
└── Window 2:              Trajectory B worktree
```

### Step-by-Step Workflow

1. **Start HFI**
   - Run `claude-hfi --vscode`
   - Two VS Code windows open automatically:
     - One for trajectory A's worktree
     - One for trajectory B's worktree
   - Control remains in your current terminal

2. **Authentication**
   - Browser opens for Auth0 login in the control terminal
   - Once authenticated, you're back at the prompt

3. **Enter your prompt**
   - Type your task in your terminal
   - Press Enter to submit

4. **Monitor trajectories (required)**
   - Control displays tmux session IDs for A and B
   - Open integrated terminals in VS Code:
     - In trajectory A's VS Code window, open terminal and run:
       ```bash
       tmux attach -t <session-id>-A
       ```
     - In trajectory B's VS Code window, open terminal and run:
       ```bash
       tmux attach -t <session-id>-B
       ```
   - Or use separate terminal windows/tabs
   - Watch for permission prompts and user input requests in both terminals
   - You can view/edit files in the VS Code editor while watching terminal output

5. **Wait for completion**
   - Control shows "Waiting for trajectories to complete..."
   - Feedback form appears when both finish

6. **Inspect results**
   - Files are already open in VS Code - review changes visually
   - Use VS Code's git diff, file explorer, search, etc.
   - Check terminal output in each tmux session
   - Type `exit` in trajectory shells when done inspecting

7. **Provide feedback (required to continue)**
   - Return to control terminal
   - Rate which model did better
   - Press Enter to submit

8. **Continue or exit**
   - Winner's changes synced to main repository
   - Give another prompt or Ctrl+C to exit

### VS Code Advantages

- **Visual file comparison:** Use VS Code's diff viewer, sidebar, and file explorer
- **Better code review:** Syntax highlighting, jump to definition, search across files
- **Integrated terminal:** Attach tmux session directly in VS Code terminal panel
- **Side-by-side editing:** Arrange both VS Code windows to compare trajectories visually
- **Recommended for most users:** Especially for complex code changes or multi-file modifications

---

## Workflow: All-in-One Tmux Session (--tmux)

When you run `claude-hfi --tmux`, everything runs in a single tmux session with three windows:

### Session Layout

```
Your terminal:
Separate tmux sessions (background):
├── Session <id>-control:    Control (you interact here)
├── Session <id>-A:          Trajectory A
└── Session <id>-B:          Trajectory B
```

### Step-by-Step Workflow

1. **Authentication (first time only)**
   - Browser opens automatically for Auth0 login
   - Once authenticated, you're returned to the control prompt

2. **Enter your prompt**
   - Type your task in your terminal
   - Press Enter to submit
   - HFI creates a tmux session and starts both trajectories

3. **Monitor trajectories (required)**
   - Control shows "Waiting for trajectories to complete..." and displays session IDs
   - You must monitor the trajectory sessions - they may require interaction:
     - Permission prompts for tool usage
     - User input requests
     - Error confirmations
   - **Important:** If a trajectory is waiting for input, it will appear stuck. Check both trajectory windows!

4. **Wait for completion**
   - Control automatically detects when both trajectories finish
   - You'll see the feedback form appear in your terminal

5. **Provide feedback (required to continue)**
   - Rate which model did better using the feedback form
   - You cannot continue without submitting feedback
   - Press Enter to submit

6. **Continue or exit**
   - The winner's changes are synced to your main repository
   - Give another prompt to continue, or Ctrl+C to exit

### Inspecting Results

After trajectories complete, they drop into interactive shells in their respective tmux sessions.

The trajectories remain in interactive shells until you manually exit them. This lets you inspect results even after submitting feedback.

---

## Git Worktrees

### What are Worktrees?

HFI creates two separate git worktrees for isolated execution:

```
Your project:                    /path/to/your/project  (main repo)
Trajectory A worktree:          ~/.cache/claude-hfi/your-project/A
Trajectory B worktree:          ~/.cache/claude-hfi/your-project/B
```

Each worktree is a complete working copy of your repository at the same commit, but with its own:

- Working directory
- Index (staging area)
- Branch (`hfi/<sessionId>/A` or `/B`)

### Why Worktrees?

This isolation ensures:

- Both models start from identical file state
- Changes in A don't affect B (and vice versa)
- Your main repository stays clean during execution
- Each model can make git commits independently

### Worktree Location

Worktrees are created in `~/.cache/claude-hfi/`:

```
~/.cache/claude-hfi/
├── my-project/
│   ├── A/          # Trajectory A worktree
│   └── B/          # Trajectory B worktree
└── other-project/
    ├── A/
    └── B/
```

If worktrees become corrupted, you can safely delete them:

```bash
rm -rf ~/.cache/claude-hfi/
```

HFI will recreate them on the next run.

---

## Virtual Environment Setup

If your project uses conda, virtualenv, or other environment managers, you'll want the environment to persist across shell commands. HFI supports this via the `CLAUDE_ENV_FILE` environment variable.

### Using CLAUDE_ENV_FILE

Create a shell script that activates your environment, then set `CLAUDE_ENV_FILE` to point to it before starting HFI:

```bash
# Create an activation script
echo 'conda activate myenv' > ~/my-env-setup.sh
# Or for virtualenv:
# echo 'source /path/to/venv/bin/activate' > ~/my-env-setup.sh

# Start HFI with the env file
export CLAUDE_ENV_FILE=./my-env-setup.sh
claude-hfi --vscode
```

When `CLAUDE_ENV_FILE` is set, its contents are sourced before every Bash command, ensuring your virtual environment stays activated throughout the session. HFI automatically passes this setting to both trajectory processes.

### Environment Variables

For projects that need `.env` files or other environment variables:

```bash
# Add .env file to each worktree
cp /path/to/your/project/.env ~/.cache/claude-hfi/my-project/A/
cp /path/to/your/project/.env ~/.cache/claude-hfi/my-project/B/
```

Files in your home directory (like `~/.config/myapp/`) are automatically shared across all worktrees.

---

## Proxy and SSL Certificate Configuration

HFI uses tmux to launch trajectory processes in separate sessions. Environment variables set in your current shell (e.g., via `export`) are **not** inherited by these tmux sessions. If your network requires a proxy or custom CA certificates, you need to ensure the relevant variables are available in new shell sessions.

### Recommended: Add to Shell Startup Files

Add your proxy and SSL variables to your shell startup file (`~/.bashrc`, `~/.zshrc`, or `~/.profile`) so that every new shell -- including those started by tmux -- picks them up:

```bash
# Add to ~/.bashrc or ~/.zshrc
export HTTP_PROXY="http://proxy.example.com:8080"
export HTTPS_PROXY="http://proxy.example.com:8080"
export NO_PROXY="localhost,127.0.0.1,.example.com"

# For custom CA certificates (e.g., corporate SSL inspection)
export NODE_EXTRA_CA_CERTS="/path/to/your/ca-bundle.crt"
```

After editing, either open a new terminal or source the file:

```bash
source ~/.bashrc  # or ~/.zshrc
```

Then start HFI as usual. Both trajectory sessions will inherit these settings.

### Alternative: Using CLAUDE_ENV_FILE

If you prefer not to modify your shell startup files, you can use `CLAUDE_ENV_FILE` to inject these variables into every Bash command run by the trajectories. See the [Virtual Environment Setup](#virtual-environment-setup) section above for details.

```bash
# Create an env setup script
cat > ~/hfi-proxy-setup.sh << 'EOF'
export HTTP_PROXY="http://proxy.example.com:8080"
export HTTPS_PROXY="http://proxy.example.com:8080"
export NO_PROXY="localhost,127.0.0.1,.example.com"
export NODE_EXTRA_CA_CERTS="/path/to/your/ca-bundle.crt"
EOF

# Start HFI with the env file
export CLAUDE_ENV_FILE=~/hfi-proxy-setup.sh
claude-hfi --vscode
```

### Common Variables

| Variable | Purpose |
|----------|---------|
| `HTTP_PROXY` | Proxy for HTTP requests |
| `HTTPS_PROXY` | Proxy for HTTPS requests |
| `NO_PROXY` | Comma-separated list of hosts/domains that bypass the proxy |
| `NODE_EXTRA_CA_CERTS` | Path to a PEM file with custom CA certificates (e.g., for corporate SSL inspection) |

---

## Feedback Form

### Navigation

| Key | Action |
|-----|--------|
| ↑↓ or j/k | Move between questions |
| ←→ or h/l | Select rating on scale |
| Enter | Submit answer / Continue to next question |
| ? | Show description of current question |
| Ctrl+C | Cancel (exits HFI) |

---

## Winner Syncing

After you submit feedback, HFI:

1. Determines the winner based on your overall preference rating
2. Copies all files from the winner's worktree to your main repository
3. Loads the winner's conversation state
4. Returns you to the prompt

**Result:** Your main repository now contains the winner's changes, and you can continue the conversation from where the winner left off.

> **Warning:** Any uncommitted changes in your main repository will be overwritten by the winner's state. Commit or stash your work before using HFI.

---

## Multi-Turn Sessions

You can give multiple prompts in a single session:

```
Round 1: Prompt → A & B execute → Feedback → Winner synced
Round 2: Prompt → A & B continue from winner → Feedback → Winner synced
Round 3: ...
```

This lets you evaluate how models handle follow-up tasks and conversation context.

---

## Troubleshooting

### "Not at git repository root"

HFI must be run from the root of a git repository, not a subdirectory.

```bash
# Navigate to the repo root
cd $(git rev-parse --show-toplevel)
```

### "Not in a git repository"

You must run HFI inside a git repository.

```bash
git init  # if needed
```

### "Authentication failed"

- Check network connection
- Re-run to trigger new auth flow
- Contact #claude-cli-feedback if persistent

### "Worktree sync failed"

- Ensure your repository is in a clean state:
  ```bash
  git status  # check for conflicts
  git stash   # stash uncommitted changes
  ```
- Check for in-progress git operations (merge, rebase, etc.)
- Delete corrupted worktrees: `rm -rf ~/.cache/claude-hfi/`

### Conda/virtualenv not activated in worktrees

Use `CLAUDE_ENV_FILE` to persist virtual environment activation across commands. See the "Virtual Environment Setup" section above.

### Trajectories fail due to missing dependencies

- Use `CLAUDE_ENV_FILE` to ensure your environment is activated (see "Virtual Environment Setup")
- Verify dependencies are installed in your virtual environment
- Check environment variables are set correctly

### Trajectory appears stuck or frozen

- Check if it's waiting for input - attach to tmux and look at the trajectory window
- Common causes:
  - Permission prompt waiting for approval/rejection
  - Interactive tool waiting for user input
  - Error message waiting for acknowledgment
- Switch to the trajectory window and provide the required input

### Tmux not found

Tmux is required. Install it:

```bash
brew install tmux  # macOS
```

### Can't see trajectory output in tmux

- **Default mode:** Trajectories run in separate sessions - use `tmux attach -t <session-id>-A` and `-B`
- **--tmux mode:** Switch windows with Ctrl+b then 0/1/2
- **VS Code mode:** Open integrated terminal in each VS Code window and attach to the respective tmux session

### VS Code doesn't open in --vscode mode

- Ensure VS Code's `code` command is installed:
  - Open VS Code
  - Cmd+Shift+P → "Shell Command: Install 'code' command in PATH"
- Or run `code` in terminal to verify it works

---

## Which Mode Should I Use?

| User Type | Recommended Mode | Reason |
|-----------|------------------|--------|
| Most users | `--vscode` | Visual file comparison and easy inspection |
| CLI users | `--tmux` | Simple all-in-one session |
| Advanced users | Default mode | Fine-grained control over separate tmux sessions |

---

## Tips

1. **Run from git root:** Always navigate to the repository root before starting HFI

2. **Start with clean git state:** Commit or stash changes before running HFI (winner will overwrite your working directory)

3. **Use CLAUDE_ENV_FILE:** For conda/virtualenv projects, set this before starting HFI to keep your environment activated

4. **Always monitor trajectories:** Keep an eye on both trajectory terminals - they may need permission approvals or user input

5. **Multi-turn testing:** Give follow-up prompts to test how models handle conversation context

6. **Inspect thoroughly:** Take time to examine files before rating - you must submit feedback to continue

7. **VS Code tip:** Arrange both VS Code windows side-by-side for easy comparison

8. **Tmux tip:** Use Ctrl+b then 1/2 to quickly switch between trajectories

9. **Auto-attach shortcut:** For --tmux mode, use `$(claude-hfi --tmux)` to automatically enter the session



