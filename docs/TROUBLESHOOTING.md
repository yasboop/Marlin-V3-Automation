# Marlin V3 HFI Troubleshooting Guide

This doc covers every known failure mode people have hit while doing Marlin V3
tasks with `claude-hfi`. It explains what you see on screen, why it happens,
how to confirm the issue, and exactly how to fix it step by step.

You do NOT need any automation scripts to follow this guide. Everything here
works with just the `claude-hfi` binary and a terminal.

---

## Table of Contents

1. [Turns Missing from Snorkel (The Upload Timeout)](#problem-1-turns-missing-from-snorkel)
2. [Context Limit Reached](#problem-2-context-limit-reached)
3. [HFI Cant Spawn Trajectory Sessions](#problem-3-hfi-cant-spawn-trajectory-sessions)
4. [Trajectory Appears Stuck / Frozen](#problem-4-trajectory-appears-stuck--frozen)
5. ["Raw mode not supported" Error](#problem-5-raw-mode-not-supported-error)
6. [Worktree Corruption](#problem-6-worktree-corruption)
7. [Authentication Fails Repeatedly](#problem-7-authentication-fails-repeatedly)
8. [Wrong Number of Turns / Duplicate Turns](#problem-8-wrong-number-of-turns--duplicate-turns)
9. [Forgot to Exit HFI Between Turns](#problem-9-forgot-to-exit-hfi-between-turns)
10. [How to Find Your Session Directory](#how-to-find-your-session-directory)
11. [How to Verify All 3 Turns Uploaded](#how-to-verify-all-3-turns-uploaded)
12. [The 5 Golden Rules](#the-5-golden-rules)

---

## Problem 1: Turns Missing from Snorkel

This is the #1 issue people face. You did 3 turns, submitted feedback for each,
but Snorkel only shows 1 or 2 turns.

### What you see on screen

**During the task (if you catch it):**
After filling the feedback form and pressing Submit, the HFI control screen shows:

```
Submitting feedback...
Uploading diffs and syncing trajectory state
```

This message should disappear within 10-30 seconds. If instead you see:
- `timeout of 30000ms exceeded` -- the upload timed out
- The screen freezes for 30+ seconds and then just goes to the next prompt
  without saying "Feedback submitted successfully" -- silent failure
- It says "submitted" but very quickly (under 2 seconds) -- might be a
  local-only save that didnt reach the server

**After the task (when you realize something is wrong):**
- Snorkel Diff Viewer shows "files changed across 2 turns" instead of 3
- One or more turns are completely missing from the platform
- The Reflection page doesnt show all your turns

### Why it happens

HFI does two things when you submit feedback:
1. Saves a `submission-step-N.json` file LOCALLY on your machine
2. Uploads the trajectory diffs + feedback data to Anthropics servers

Snorkel reads from the server, not your machine. So if step 2 fails, the
local file exists but Snorkel never got the data.

**The most common root cause:** You didnt exit HFI between turns. When you
keep HFI running continuously across turns the context window fills up. By
Turn 3 the model is struggling, diffs are bloated/corrupted, and the upload
to the server exceeds the 30-second timeout.

**Other causes:**
- Network issues (slow connection, VPN, proxy)
- Very large diffs from the trajectory making too many file changes
- HFI launched with `--control` instead of `--tmux` (sessions dont work right)

### How to confirm the issue

**Step 1: Find your session directory**

HFI prints the session directory path when it launches. It looks like:
```
Session directory: /var/folders/xx/xxxxxxx/T/claude-hfi/abc12345-def6-7890-...
```

If you missed it, find it with:
```bash
# On macOS
ls -td ${TMPDIR}claude-hfi/*/ 2>/dev/null | head -1

# If that doesnt work try
ls -td /tmp/claude-hfi/*/ 2>/dev/null | head -1

# Nuclear option: search everywhere
find /var/folders -maxdepth 5 -type d -name "claude-hfi" 2>/dev/null
```

**Step 2: Check submission files for each turn**

Turns are 0-indexed in the files: Turn 1 = step 0, Turn 2 = step 1, Turn 3 = step 2.

```bash
cd /path/to/your/session/directory

# Check which submission files exist
ls -la submission-step-*.json

# You should see 3 files (one per turn):
#   submission-step-0.json  (Turn 1)
#   submission-step-1.json  (Turn 2)
#   submission-step-2.json  (Turn 3)
```

**What to look for:**
- **File is MISSING** -- the upload completely failed for that turn
- **File exists but is very small (under 1KB)** -- upload started but got cut off
- **File exists and is 10KB+ in size** -- the local save worked. Now check
  if the server actually got it (Step 3)

**Step 3: Check the debug log for upload confirmations**

```bash
# Check if diffs were actually uploaded to the server
grep "HFI:diff.*Uploaded" debug.txt

# You should see 2 lines per turn (one for trajectory A, one for B):
#   [HFI:diff] Uploaded attachment: trajectory-A-step-0.diff
#   [HFI:diff] Uploaded attachment: trajectory-B-step-0.diff
#   [HFI:diff] Uploaded attachment: trajectory-A-step-1.diff
#   ... etc

# Count them
grep -c "HFI:diff.*Uploaded" debug.txt
# Should be 6 total (2 per turn x 3 turns)
```

**Step 4: Check for errors and timeouts**

```bash
# Look for errors
grep "ERROR" debug.txt

# Look for timeouts specifically
grep -i "timeout" debug.txt

# Common error patterns:
#   [ERROR] Error streaming, falling back to non-streaming mode: The operation timed out.
#   [ERROR] timeout of 30000ms exceeded
#   [ERROR] 404 Not Found
```

### How to fix it

**If the turn can be retried (you havent submitted to Snorkel yet):**

1. Exit HFI completely: press **Ctrl+C twice**

2. Kill any leftover tmux sessions:
   ```bash
   tmux ls
   # Kill any sessions that start with your session ID or 'hfi-'
   tmux kill-session -t <session-name>
   ```

3. Go to your session directory and delete the failed turns files.
   For example if Turn 3 failed (step index = 2):
   ```bash
   cd /path/to/session/dir
   rm -f prompt-2.json base-commit-2.txt
   ```
   **DO NOT** delete the files for turns that succeeded (step 0 and step 1).

4. Open a regular terminal app (Terminal.app, iTerm2 -- NOT Cursors built-in terminal)
   and start a tmux session:
   ```bash
   tmux new-session -s hfi-retry
   ```

5. Inside that tmux session, navigate to your repo and relaunch HFI:
   ```bash
   cd /path/to/your/repo
   ./claude-hfi --tmux --continue
   ```
   The `--continue` flag tells HFI to resume the existing session.
   The `--tmux` flag is CRITICAL -- see Problem 3 for why.

6. Authenticate in the browser if prompted

7. When HFI shows the prompt input, paste your Turn 3 prompt

8. Wait for both trajectories to complete

9. Fill the feedback form carefully

10. After submitting, **WAIT** until you see "Feedback submitted successfully"
    or the "Continue/Finish conversation" selection. Dont touch anything until then

11. Select "Finish conversation" (since this is Turn 3)

12. Fill the post-thread survey

13. Verify the fix worked:
    ```bash
    cd /path/to/session/dir
    ls -la submission-step-2.json
    # Should exist and be >10KB
    grep "step-2.diff" debug.txt | grep "Uploaded"
    # Should show 2 lines (one for A, one for B)
    ```

**If you already submitted to Snorkel:**
Unfortunately you cannot fix this after Snorkel submission. You would need to
start a completely new task with a different PR.

### How to prevent this in the future
- **ALWAYS exit HFI (Ctrl+C twice) and relaunch with `--continue` between EVERY turn**
- **ALWAYS use the `--tmux` flag** when launching HFI
- After filling feedback, **WAIT** for the upload to complete before touching anything
- After Turn 3, verify all 3 submission files exist before going to Snorkel
  (see [How to Verify All 3 Turns Uploaded](#how-to-verify-all-3-turns-uploaded))

---

## Problem 2: Context Limit Reached

### What you see on screen
- You check a trajectory tmux window (`tmux select-window -t <id>:1`) and see
  the message "Context limit reached" or "context window exceeded"
- The model may have stopped working partway through, leaving incomplete changes
- The other trajectory might be fine, or both might be affected
- The HFI control screen still shows the feedback form as normal

### Why it happens
The model tried to read too many files and ran out of its context window.
This is the models problem, not yours. It happens more often when:
- Your prompt is too broad ("refactor the entire codebase")
- The repo has very large files the model tried to read
- You didnt exit HFI between turns, so old context accumulated
- The model went down a rabbit hole reading unnecessary files

### How to confirm
```bash
# Switch to trajectory windows and look for the error
tmux select-window -t <session-id>:1   # Trajectory A
tmux select-window -t <session-id>:2   # Trajectory B
# Press Ctrl+B then D to detach when done checking
```

If you see "Context limit reached" in the output, thats the issue.

### What to do in feedback
The trajectory that hit the context limit is effectively FAILED. In the
feedback form:
- Rate the failed trajectory at the lowest level (1 = "fails to complete",
  "broken", "no useful output")
- Strengths: write something like "Trajectory exhausted context window
  without producing complete changes"
- Rate the other trajectory normally if it succeeded
- If BOTH hit context limit: give both low ratings, write honest feedback,
  then craft a more focused Turn 2 prompt targeting fewer files

### How to prevent
- Write prompts that target specific files and functions, not entire modules
- Keep prompts under 300 words
- Always exit HFI between turns to reset accumulated context
- If working with large repos, mention which files to focus on in the prompt

---

## Problem 3: HFI Cant Spawn Trajectory Sessions

### What you see on screen
- HFI shows something like "Waiting for trajectories to complete..."
  but nothing is happening
- You run `tmux ls` and you only see your launcher session -- no `-A` or `-B`
  sessions exist
- The HFI debug log might say "Trajectory A started in window..." but when
  you check, those tmux sessions dont exist
- HFI is stuck indefinitely

### Why it happens
HFI needs a proper TTY (terminal interface) to create new tmux sessions.
This fails in two scenarios:

1. **You launched HFI from Cursors integrated terminal.** Cursors terminal
   shell doesnt provide a real TTY, so HFI cant create its child sessions.
   This is the most common cause.

2. **You used `--control` instead of `--tmux`.** The `--control` flag runs
   HFI in a different mode that doesnt create separate trajectory sessions.
   For multi-turn tasks you MUST use `--tmux`.

### How to confirm
```bash
tmux ls
```
Depending on how HFI was launched, you will see one of two layouts:

**Layout 1 (first launch with `--tmux`):** A single session with 3 windows:
- `<session-uuid>: 3 windows` -- window :0 (control), :1 (A), :2 (B)

**Layout 2 (relaunched with `--tmux --continue`):** Separate sessions:
- Your launcher session (e.g., `hfi-turn2`)
- `<session-uuid>-A` (Trajectory A)
- `<session-uuid>-B` (Trajectory B)

If you see ONLY the launcher and no trajectory sessions/windows, HFI failed to spawn them.

### How to fix
1. Kill everything:
   ```bash
   # Kill all tmux sessions (safe -- only kills tmux, not other processes)
   tmux kill-server
   ```

2. Open a REAL terminal app (Terminal.app, iTerm2, Alacritty -- NOT Cursor):
   ```bash
   # Start a tmux session first
   tmux new-session -s hfi-launcher

   # Then inside this tmux session, launch HFI
   cd /path/to/your/repo
   ./claude-hfi --tmux          # for first launch
   # OR
   ./claude-hfi --tmux --continue   # to resume an existing session
   ```

3. The key insight: HFI MUST run inside a tmux session to get a proper TTY.
   Creating the tmux session first and then running HFI inside it solves the
   problem every time.

### How to prevent
- **Never launch HFI directly from Cursors terminal** -- always use a real
  terminal app
- **Always use `--tmux` flag** -- never use `--control` for multi-turn tasks
- **Always launch from inside a tmux session** -- the pattern is:
  `tmux new-session` first, then `./claude-hfi --tmux` inside it

---

## Problem 4: Trajectory Appears Stuck / Frozen

### What you see on screen
- Both trajectories have been "running" for a long time (10+ minutes without
  any new output)
- The HFI control screen shows no progress
- Or one trajectory finishes but the other is stuck

### Why it happens
The most common cause: the model is **waiting for your permission** to do
something. HFI asks permission for certain actions (file writes, command
execution etc) in the TRAJECTORY sessions, not in the control session.
So you wont see the prompt unless you attach to the trajectory.

Other causes:
- The model hit an internal error and is silently retrying
- The model is doing something that takes a very long time (compiling, running
  a large test suite)
- Network issue between your machine and Anthropics API

### How to confirm
```bash
# Switch to each trajectory window and check whats happening
tmux select-window -t <session-id>:1   # Trajectory A
# Look for "Allow this action?" or "y/n" or "permission" prompts

tmux select-window -t <session-id>:2   # Trajectory B
```

### How to fix
- **Permission prompt**: type `y` and press Enter to approve the action.
  You can also press Shift+Tab in the HFI TUI to toggle "trust mode" which
  auto-approves all actions for that session

- **Genuinely stuck (no prompt, no output, no activity for 10+ minutes)**:
  The trajectory has likely hit an internal error. You can:
  - Wait for it to time out on its own (HFI has internal timeouts)
  - Or press Ctrl+C in the trajectory session to kill it. HFI will detect
    the trajectory ended and proceed to the feedback form

- **Running a long process**: If you see it compiling or running tests, just
  wait. Some test suites take 15-20 minutes

### How to prevent
- Periodically check on your trajectory sessions during execution:
  ```bash
  tmux select-window -t <session-id>:1   # Trajectory A
  tmux select-window -t <session-id>:2   # Trajectory B
  ```
- Consider using "trust mode" (Shift+Tab) if you dont want permission prompts

---

## Problem 5: "Raw mode not supported" Error

### What you see on screen
```
Error: Raw mode is not supported on the current process.stdin
```
HFI exits immediately after showing this.

### Why it happens
The terminal HFI is running in doesnt support raw mode input. This happens when:
- Running HFI from Cursors shell/terminal tool
- Running HFI through `script` or other wrappers
- Piping input/output to HFI
- Running HFI via SSH without proper terminal allocation

### How to fix
Launch HFI inside a tmux session from a real terminal:
```bash
tmux new-session -s hfi-launcher
cd /path/to/your/repo
./claude-hfi --tmux
```

For SSH connections, make sure you allocate a TTY:
```bash
ssh -t user@host 'tmux new-session -s hfi-launcher'
```

---

## Problem 6: Worktree Corruption

### What you see on screen
- HFI fails to start with errors about worktrees
- Messages like "worktree already locked", "invalid worktree", or
  "fatal: could not create worktree"
- Git errors during HFI startup

### Why it happens
Previous HFI sessions left corrupted state in the worktree cache directory.
This can happen when HFI crashes, when you force-kill it, or when the
system crashes during a task.

### How to fix
```bash
# Delete the entire HFI cache directory
rm -rf ~/.cache/claude-hfi/

# Then relaunch HFI -- it will recreate everything fresh
tmux new-session -s hfi-fresh
cd /path/to/your/repo
./claude-hfi --tmux
# OR with --continue if resuming
./claude-hfi --tmux --continue
```

This is completely safe. The cache only contains HFIs working copies of your
repo, not your actual repo. HFI recreates everything on the next launch.

---

## Problem 7: Authentication Fails Repeatedly

### What you see on screen
- Browser opens to the Auth0 login page
- You log in successfully but HFI still says "Authenticating..." or
  "Waiting for authentication..."
- Or HFI says "Authentication failed" or "Invalid credentials"
- Or the browser shows an error page after login

### Why it happens
- **Wrong email**: You must use your ALIAS email address, not Google sign-in.
  Go directly to `https://feedback.anthropic.com/claude_code?email_login=true`
  and use the email that was set up for you
- **Network/proxy blocking**: The auth callback uses localhost, which can be
  blocked by certain corporate proxies or VPNs
- **Expired session**: If its been a while since you last authenticated, the
  token may have expired

### How to fix
1. Make sure you go to the correct URL:
   `https://feedback.anthropic.com/claude_code?email_login=true`
   
2. Use your ALIAS email -- the one you were given for this project, not your
   personal email or Google account

3. If auth keeps failing:
   ```bash
   # Kill all HFI processes
   pkill -f claude-hfi
   
   # Clear any cached auth
   rm -rf ~/.claude-hfi/
   
   # Try again
   tmux new-session -s hfi-auth
   cd /path/to/your/repo
   ./claude-hfi --tmux
   ```

4. If you are behind a corporate proxy, check the instructions.md for proxy
   configuration details (HTTP_PROXY / HTTPS_PROXY environment variables)

---

## Problem 8: Wrong Number of Turns / Duplicate Turns

### What you see on screen
- Snorkel shows 4 turns instead of 3
- Or turns appear duplicated with the same content
- Or the turn numbering is off

### Why it happens
You submitted feedback twice for the same turn. This happens when:
- You clicked Submit and then clicked it again because the upload seemed slow
- HFI showed an error on first submit so you pressed Enter again, but the
  first one actually went through
- HFI v2.1.70 fixed a bug where "submitting feedback twice during upload
  could skip step indices" -- make sure your HFI is up to date

### How to check your HFI version
```bash
./claude-hfi --version
```
If its below v2.1.70, download a newer version from the platform.

### How to fix
- **If you havent submitted to Snorkel yet**: delete the duplicated turn
  files from the session directory and redo just that turn:
  ```bash
  cd /path/to/session/dir
  # If Turn 2 was duplicated as step 1 AND step 2
  rm -f prompt-2.json base-commit-2.txt result-2-A.json result-2-B.json
  rm -f feedback-step-2.json submission-step-2.json diff-paths-2.json
  # Then redo Turn 2 with --continue
  ```
- **If already submitted to Snorkel**: cannot be fixed. Skip this task and
  start fresh with a different PR

### How to prevent
- After pressing Submit, **WAIT** until you see "Feedback submitted successfully"
  or the "Continue/Finish" menu appears
- **Never press Submit/Enter multiple times** during the upload phase
- Make sure your HFI binary is v2.1.70 or later

---

## Problem 9: Forgot to Exit HFI Between Turns

### What you see on screen
- After submitting Turn 1 feedback, you selected "Continue conversation"
  and pasted your Turn 2 prompt directly -- WITHOUT exiting and relaunching HFI
- Context may still seem low early on but by Turn 3 the model is slow,
  outputs are messy, or you hit context limits
- Someone in your group asks "any way to clear the context after executing
  the prompt for a turn?"

### Why this is a problem
Per the Marlin V3 documentation, you MUST exit HFI between turns and relaunch
with `--continue`. This is not optional. Without doing this:
- Model context accumulates across turns, leading to degraded performance
- Trajectory diffs grow large from accumulated state
- Uploads are more likely to timeout
- The model may see stale context from previous turns

### What to do if you already made this mistake

**If you are currently stuck at Turn 3 with context maxed out:**
1. Press Ctrl+C twice to exit HFI
2. Relaunch properly:
   ```bash
   tmux new-session -s hfi-fix
   cd /path/to/your/repo
   ./claude-hfi --tmux --continue
   ```
3. When the prompt appears, type `/clear` and press Enter to reset context
4. Now paste your Turn 3 prompt
5. This time the model will have a fresh context window

**If turns 1 and 2 submitted fine but Turn 3 is failing:**
Follow the fix steps from Problem 1 -- delete Turn 3 state files and retry.

**If you completed all 3 turns without exiting but everything seems to have
uploaded fine:**
Check your submission files (see [How to Verify All 3 Turns Uploaded](#how-to-verify-all-3-turns-uploaded)).
If all 3 are there and >10KB each, you might be okay. But the quality of the
models work may have been degraded, so the evaluations might reflect that.

### The correct workflow between turns
```
Turn 1: Launch HFI -> paste prompt -> wait for trajectories -> fill feedback
        -> select "Continue conversation"
        -> EXIT HFI (Ctrl+C twice)

Turn 2: Relaunch: ./claude-hfi --tmux --continue
        -> type /clear and press Enter
        -> paste prompt -> wait -> fill feedback -> "Continue conversation"
        -> EXIT HFI (Ctrl+C twice)

Turn 3: Relaunch: ./claude-hfi --tmux --continue
        -> type /clear and press Enter
        -> paste prompt -> wait -> fill feedback -> "Finish conversation"
        -> fill the post-thread survey
```

---

## How to Find Your Session Directory

HFI stores all session data in a temp directory. You need to find this
directory to debug most issues.

**Method 1: Check HFI launch output**

When HFI starts, it prints the session directory:
```
Session directory: /var/folders/wv/zplv7lv92m32p0l4fs0gj_qr0000gn/T/claude-hfi/a2ef6961-a961-4f8c-90f9-63c460d9b3ed
```
If you have this, thats your path.

**Method 2: Search the temp directory (macOS)**

```bash
# List all HFI session directories, most recent first
ls -td ${TMPDIR}claude-hfi/*/ 2>/dev/null

# Or search more broadly
ls -td /var/folders/*/T/claude-hfi/*/ 2>/dev/null | head -5
```

**Method 3: Search the temp directory (Linux)**

```bash
ls -td /tmp/claude-hfi/*/ 2>/dev/null
```

**Method 4: Search everywhere (slow but thorough)**

```bash
find /var/folders -maxdepth 5 -type d -name "claude-hfi" 2>/dev/null
find /tmp -maxdepth 3 -type d -name "claude-hfi" 2>/dev/null
```

**What you will find inside:**

```
/path/to/session/dir/
  debug.txt                 # HFI debug log (most important file for debugging)
  prompt-0.json             # Turn 1 prompt
  prompt-1.json             # Turn 2 prompt
  prompt-2.json             # Turn 3 prompt
  base-commit-0.txt         # Git commit hash at Turn 1 start
  base-commit-1.txt         # Git commit hash at Turn 2 start
  base-commit-2.txt         # Git commit hash at Turn 3 start
  result-0-A.json           # Trajectory A output for Turn 1
  result-0-B.json           # Trajectory B output for Turn 1
  result-1-A.json           # ... Turn 2
  result-1-B.json           # ...
  result-2-A.json           # ... Turn 3
  result-2-B.json           # ...
  feedback-step-0.json      # Your feedback for Turn 1
  feedback-step-1.json      # Your feedback for Turn 2
  feedback-step-2.json      # Your feedback for Turn 3
  submission-step-0.json    # UPLOADED data for Turn 1 (CRITICAL)
  submission-step-1.json    # UPLOADED data for Turn 2 (CRITICAL)
  submission-step-2.json    # UPLOADED data for Turn 3 (CRITICAL)
  diff-paths-0.json         # Diff file paths for Turn 1
  diff-paths-1.json         # ...
  diff-paths-2.json         # ...
  thread-feedback.json      # Post-thread survey data
```

---

## How to Verify All 3 Turns Uploaded

Run this BEFORE going to Snorkel. It takes 30 seconds and can save you from
wasting a task.

```bash
# Replace with your actual session directory path
SESSION_DIR="/path/to/your/session/dir"

echo "=== Submission File Check ==="
for i in 0 1 2; do
  TURN=$((i + 1))
  FILE="$SESSION_DIR/submission-step-${i}.json"
  if [ -f "$FILE" ]; then
    SIZE=$(wc -c < "$FILE" | tr -d ' ')
    if [ "$SIZE" -gt 10000 ]; then
      echo "  Turn $TURN: OK ($SIZE bytes)"
    else
      echo "  Turn $TURN: WARNING - only $SIZE bytes (might be incomplete)"
    fi
  else
    echo "  Turn $TURN: MISSING - upload failed!"
  fi
done

echo ""
echo "=== Diff Upload Check ==="
for i in 0 1 2; do
  TURN=$((i + 1))
  COUNT=$(grep -c "step-${i}.diff" "$SESSION_DIR/debug.txt" 2>/dev/null || echo "0")
  if [ "$COUNT" -ge 2 ]; then
    echo "  Turn $TURN: OK ($COUNT diffs uploaded)"
  elif [ "$COUNT" -gt 0 ]; then
    echo "  Turn $TURN: WARNING - only $COUNT diff uploaded (should be 2)"
  else
    echo "  Turn $TURN: FAILED - no diffs uploaded to server"
  fi
done

echo ""
echo "=== Error Check ==="
ERRORS=$(grep -c "ERROR" "$SESSION_DIR/debug.txt" 2>/dev/null || echo "0")
TIMEOUTS=$(grep -ci "timeout" "$SESSION_DIR/debug.txt" 2>/dev/null || echo "0")
echo "  Total errors: $ERRORS"
echo "  Total timeouts: $TIMEOUTS"
if [ "$ERRORS" -gt 0 ]; then
  echo ""
  echo "  Last 3 errors:"
  grep "ERROR" "$SESSION_DIR/debug.txt" 2>/dev/null | tail -3 | sed 's/^/    /'
fi

echo ""
echo "=== Thread Feedback ==="
if [ -f "$SESSION_DIR/thread-feedback.json" ]; then
  echo "  Post-thread survey: OK"
else
  echo "  Post-thread survey: MISSING (did you select 'Finish conversation'?)"
fi
```

Copy this entire block into your terminal, replace the `SESSION_DIR` path,
and run it. If everything says OK, you are safe to proceed to Snorkel.

---

## The 5 Golden Rules

Follow these and you will avoid 95% of the problems in this guide:

1. **ALWAYS exit HFI between turns (Ctrl+C twice) and relaunch with
   `./claude-hfi --tmux --continue`**
   This is the single most important rule. Skipping this causes context
   overflow, upload timeouts, and missing turns.

2. **ALWAYS use `--tmux` flag when launching HFI**
   Never use `--control` for multi-turn tasks. The `--tmux` flag creates
   proper trajectory sessions that work correctly.

3. **ALWAYS launch HFI from inside a tmux session, not from Cursor terminal**
   ```bash
   tmux new-session -s hfi-turnN
   cd /path/to/repo
   ./claude-hfi --tmux
   ```
   Cursors terminal doesnt provide a proper TTY for HFI.

4. **ALWAYS wait for "Feedback submitted successfully" after pressing Submit**
   Dont click Submit twice. Dont press Enter again. Dont close anything.
   Wait for the confirmation message.

5. **ALWAYS verify submission files before going to Snorkel**
   Run the verification script above (or manually check `submission-step-*.json`
   files). If any turn is missing or undersized, fix it BEFORE submitting
   to Snorkel. You cannot fix it after.

---

## Quick Debug Cheatsheet

```bash
# Find your session directory
ls -td ${TMPDIR}claude-hfi/*/ 2>/dev/null | head -1

# Check if all submission files exist
ls -la /path/to/session/dir/submission-step-*.json

# Check file sizes (each should be >10KB)
wc -c /path/to/session/dir/submission-step-*.json

# Check if diffs were uploaded (should see 2 lines per turn = 6 total)
grep -c "HFI:diff.*Uploaded" /path/to/session/dir/debug.txt

# Check for errors
grep "ERROR" /path/to/session/dir/debug.txt

# Check for timeouts
grep -i "timeout" /path/to/session/dir/debug.txt

# List all tmux sessions
tmux ls

# Switch to trajectory A window
tmux select-window -t <session-id>:1

# Detach from tmux (without killing it)
# Press: Ctrl+B then D

# Kill all tmux sessions (nuclear option)
tmux kill-server

# Clear corrupted worktrees
rm -rf ~/.cache/claude-hfi/

# Check HFI version
./claude-hfi --version
```
