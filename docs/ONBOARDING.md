# Screen Share Onboarding Guide

Step-by-step script for onboarding someone onto the Marlin V3 Automation via screen share.

---

## Before the Call

Send them this checklist to prepare:

- [ ] Install **Cursor IDE** from https://cursor.com
- [ ] Install **GitHub CLI**: `brew install gh && gh auth login`
- [ ] Install **tmux**: `brew install tmux`
- [ ] Verify **Python 3.10+**: `python3 --version`
- [ ] Download **claude-hfi** binary from https://feedback.anthropic.com/claude_code
- [ ] Have your **Snorkel account** open in browser
- [ ] Have your **alias email** credentials ready (not Google sign-in)

---

## On the Call

### Step 1: Prerequisites Check (~3 min)

Open their terminal and verify everything:

```bash
gh auth status
tmux -V
python3 --version
```

If anything is missing: `brew install gh`, `brew install tmux`, etc.

### Step 2: Prepare the HFI Binary (~1 min)

```bash
ls ~/Downloads/ | grep -i claude
mv ~/Downloads/<downloaded-name> ~/Downloads/claude-hfi
chmod +x ~/Downloads/claude-hfi
~/Downloads/claude-hfi --help
```

### Step 3: Get the Automation Repo (~1 min)

```bash
git clone <repo-url> ~/Downloads/Marlin_V3_Automation
```

Or copy the folder via AirDrop/drive.

### Step 4: Open in Cursor (~2 min)

1. Open Cursor IDE
2. File > Open Folder > select `Marlin_V3_Automation`
3. **No manual rule setup needed.** The folder has `.cursor/rules/` with a rule that auto-loads on every chat. The AI already knows the playbook, the writing style rules, and all triggers the moment they open a chat.
4. Install deps:
   ```bash
   pip3 install -r automation/requirements.txt
   ```

### Step 5: Explain the Key Concept (~2 min)

Tell them:

> "Just say 'lets start a task' in Cursor chat. The AI already has all the rules loaded automatically from the .cursor/rules folder. It handles everything: PR selection, prompt generation, environment setup, HFI execution, feedback filling, and submission guidance. You just follow its prompts."

> "The AI tells you clearly what it handles vs what you need to do. Your manual actions: authenticate HFI once, approve permission prompts in tmux, paste prompt into Snorkel, paste reflection into Snorkel at the end."

### Step 6: tmux Mode (~1 min)

If they previously used `--vscode` mode:

> "This automation uses tmux mode instead of VS Code mode. The only change is `claude-hfi --tmux` instead of `claude-hfi --vscode`. Everything else is identical: same auth, same prompts, same feedback forms, same worktrees. tmux mode lets us automate form filling and prompt injection."

> "You can still open worktree folders in any editor. They live at `~/.cache/claude-hfi/<project>/A` and `~/.cache/claude-hfi/<project>/B`."

### Step 7: Run a Live Task Together (~rest of call)

1. Open Cursor chat, say "lets start a task"
2. Phase 1: Open Snorkel, pick a repo, paste URL into Cursor chat
3. Phase 2: Watch Cursor generate the prompt package
4. Paste prompt fields into Snorkel's Prompt Preparation form, submit
5. Wait for Snorkel approval
6. Phase 3: Watch Cursor set up environment, create CLAUDE.md, launch HFI
7. **Auth step**: Browser opens -- log in with alias email
8. Watch Turn 1 run. Show them how to check trajectories:
   ```bash
   tmux ls
   tmux attach -t <session-id>-A
   ```
9. Watch feedback form auto-fill and submit
10. Continue through Turns 2-3
11. Show them the Snorkel submission values at the end

### Step 8: Gotchas to Point Out (~1 min)

- **Permission prompts**: Trajectories sometimes ask "Allow this tool?" -- type `y` in that tmux session
- **HFI crashes**: Run `bash automation/hfi_orchestrator.sh diagnose` or check `docs/TROUBLESHOOTING.md`
- **Context limits**: If a trajectory runs out of context, note it as a weakness -- the other trajectory usually finishes
- **Nested .git dirs**: Large repos with submodules may have nested `.git` directories in worktrees that cause submission failures -- remove them manually
- **Always alias email for auth, never Google sign-in**

---

## Their Cheat Sheet (After the Call)

```
1. Open Marlin_V3_Automation in Cursor
2. Say "lets start a task" in Cursor chat (rules auto-load, no config needed)
3. Follow the prompts
4. If stuck: docs/TROUBLESHOOTING.md or bash automation/hfi_orchestrator.sh diagnose
```

---

## Quick Reference: tmux vs VS Code Mode

| Aspect | tmux mode (this automation) | VS Code mode |
|--------|----------------------------|--------------|
| Launch command | `claude-hfi --tmux` | `claude-hfi --vscode` |
| Control pane | tmux session | Regular terminal |
| Trajectory views | tmux sessions | VS Code windows |
| Automated form filling | Yes | No |
| Automated prompt injection | Yes | No |
| Code review | `git diff` or open files in any editor | VS Code diff viewer |
| Switch effort | N/A | Change one flag |
