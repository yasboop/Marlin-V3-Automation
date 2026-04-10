# MARLIN V3 — MASTER EXECUTION GUIDE

> **Purpose:** The single, definitive reference for every phase of a Marlin V3 task. From picking a PR to clicking Submit.
> Consolidated from all 10 official training documents + HFI CLI docs + operational experience.
> All rules here are absolute and current.

---

## TABLE OF CONTENTS

| # | Section | Purpose |
|---|---------|---------|
| 0 | [Program-Level Rules](#0-program-level-rules) | Zero-tolerance rules (violation = removal) |
| 1 | [PR Selection](#phase-1--pr-selection) | Pick your repo + PR on Snorkel |
| 2 | [Prompt Preparation](#phase-2--prompt-preparation) | Write the prompt + supporting fields |
| 3 | [Environment & CLI Setup](#phase-3--environment--cli-setup) | Unpack tarball, set up env, launch HFI |
| 4 | [Task Execution](#phase-4--task-execution) | Run turns, review trajectories, iterate |
| 5 | [Review Diffs & Traces](#phase-5--review-diffs--traces) | Line-by-line review of code + model reasoning |
| 6 | [Evaluation Writeup](#phase-6--evaluation-writeup) | 7 text fields + 11 axis questions |
| 7 | [Rating & Justification Rules](#phase-7--rating--justification-rules) | Scale, key-axis, calibration, common mistakes |
| 8 | [Submission Checker](#phase-8--submission-checker) | Optional sanity-check tool on Snorkel |
| 9 | [Final Submit](#phase-9--final-submit) | Claim, paste, submit (irreversible) |
| 10 | [LLM Detection Rules](#10-llm-detection-rules) | What reviewers flag, threshold, signal categories |
| 11 | [Dispute Process](#11-dispute-process) | How disputes work, denial limits |
| 12 | [Troubleshooting & FAQ](#12-troubleshooting--faq) | Common issues, reporting, workarounds |
| A | [Common Mistakes Checklist](#appendix-a--common-mistakes-checklist) | Pre-submission verification |
| B | [Prompt Templates Library](#appendix-b--prompt-templates-library) | Copy-paste ready templates |
| C | [Quick Reference Card](#appendix-c--quick-reference-card) | Key numbers, do-not list, rating scale |
| D | [Gap Analysis vs Playbook](#appendix-d--gap-analysis-vs-playbook) | What playbook has/lacks vs official PDFs |

---

## 0. Program-Level Rules

These are zero-tolerance rules. Violations may result in removal from the program.

| Rule | Source |
|------|--------|
| DO NOT push work to public repositories. All work must remain private. Applies to ALL task types including Greenfield. | Training_0 |
| DO NOT use external LLMs or AI tools outside the provided platform to analyze code, write prompts, review outputs, or draft explanations. Submissions showing signs of heavy or direct LLM usage may be rejected. | Training_4, Training_7 |

---

## PHASE 1 — PR SELECTION

### What this is
You visit the Snorkel platform and pick ONE repository + ONE pull request to base your work on. Think of it as choosing the exam question: hard enough to make a model genuinely struggle, but within a language/domain you actually understand.

### Step-by-step
1. **Open the Snorkel interface** (split-screen: repos on left, PRs on right)
2. **Browse the PR Glossary** (each repo shows available PRs)
3. **Apply the complexity filter** (mental checklist):
   - Would a human engineer need ~2+ hours?
   - Would a model likely fail on the 1st or 2nd try?
   - Is the language supported?
4. **Pick a prompt category** that fits (14 categories, see below)
5. **Select repo -> Select PR -> Click SUBMIT**
6. **Wait 1-2 minutes** for Snorkel to process

### Supported Languages
Python, JavaScript/TypeScript, Go, Rust, Java, C++

### The 14 Prompt Categories

Every submission must fit at least one. Submissions that do not fit any category will be rejected.

| # | Category | One-liner |
|---|----------|-----------|
| 1 | Git | Tasks involving git operations (branch, merge, rebase, etc.) |
| 2 | Ambiguous | Prompt where a good model should ask for clarification first |
| 3 | Discussion | Answer questions about code without producing code |
| 4 | Explaining | Walk through / narrate how existing code works. Distinct from Discussion: Discussion is reasoning through problems or tradeoffs, Explaining is asking how existing code or a change works. |
| 5 | Code Review | Review a feature suite or meaningful chunk of code |
| 6 | Refactor | Cleanup, consolidation, readability, no behavior change |
| 7 | Greenfield | Build from scratch in an empty repo (no PR needed) |
| 8 | Bug Fix | Find and fix a specific, reproducible bug |
| 9 | Chore | Maintenance: deps, config, build fixes |
| 10 | Documentation | Write/update docs, docstrings, READMEs |
| 11 | New Feature | Add entirely new functionality to existing repo |
| 12 | Performance | Reduce latency, memory, compute, with measurable success |
| 13 | Testing & QA | Write, improve, or extend tests |
| 14 | Other | Genuinely doesn't fit above (rare, check Slack first) |

### What Reviewers Check (Categories)

- Reviewer verifies selected category matches prompt
- **Severe mismatch**: Reviewer will reject
- **Partial match**: Reviewer may modify rather than reject
- Reviewers can add or change categories at the end to reflect the full conversation

### Key rules
- Category can **evolve** across turns (Turn 1 = Discussion, Turn 2 = Code Review). You only declare the initial category. Reviewers account for category evolution.
- If one category gets flooded, Snorkel may temporarily **disable** it until submissions balance out.

---

## PHASE 2 — PROMPT PREPARATION

### What this is
You write the task description that the model will receive. Think of it as writing a very detailed GitHub issue: describe the problem, what success looks like, and any edge cases. You do NOT say "Act as a senior engineer" or reference the PR itself.

### What you must prepare (4 sections)

#### 2.1 — Repository & PR Context
Explain what the repo does and what needs to change and why, clearly enough that someone unfamiliar with the codebase can follow. Focus on behavior and impact rather than implementation history.

#### 2.2 — Task Approach
- Current behavior vs. desired behavior
- Which files/functions/components are involved
- Dependencies or interactions that may break
- Concrete edge cases (not hypothetical)
- What tests should cover and how they validate behavior
- Clear acceptance criteria ("done when...")

#### 2.3 — Prompt Definition
The actual text the model will see. Rules:
- **Self-contained**: someone reading only this text understands the full task
- **No role-based prompting**: no "You are a senior engineer..."
- **No PR references**: write as if you are the developer building this from scratch
- **No LLM usage**: you must write this yourself
- **No asking model to create CLAUDE.md**: this is a rejection trigger
- **Not over-prescriptive**: describe problem + success, not "on line 47, change X to Y"
- **6-8 engineer-hours** complexity target

#### 2.4 — Effort & Complexity
Brief paragraph explaining WHY this is non-trivial (number of files, logic depth, component interactions, edge cases). This is NOT a restatement of the task.

### Absolute Prohibitions for Prompts

| Prohibition | Consequence |
|-------------|-------------|
| Reference the PR (PR number, branch, "this PR") | Rejection |
| Role-based prompting ("You are a senior engineer...") | Rejection |
| Use LLMs at any stage of prompt creation | Rejection |
| Ask model to create CLAUDE.md via a turn prompt | Rejection |
| Select wrong category | Rejection |
| Over-prescriptive instructions | Rejection |

### Phased Implementation

The initial prompt is NOT required to include the full scope. It is acceptable to implement core logic in Turn 1 and introduce remaining related functionality (missing edge cases, tests, secondary features) in later turns, as long as each turn advances the implementation concretely.

### Verifiable Prompts

Verifiable prompts are strongly encouraged but not mandatory, provided the acceptance criteria field explicitly describes expected behaviour, signals for judging correctness, and what counts as incomplete.

**Important**: Open-ended does not mean lazy. Reviewers will closely check the "What is the ideal response?" field. An intentionally open-ended prompt should be challengingly open, not vague because the author was not sure what they wanted.

### Over-Prescriptive Prompts (Rejection Reason)

Models are capable of significant independent engineering judgment. Prompts that micromanage every step deprive reviewers of the ability to evaluate that capability.

| Over-prescriptive (AVOID) | Appropriately scoped (AIM FOR) |
|---------------------------|-------------------------------|
| "In api/search.py, on line 47, change the call from decode('ascii') to decode('utf-8'). Then open tests/test_search.py and add a test named test_non_ascii_query..." | "Requests to /api/search return 500 when the query contains non-ASCII characters. Fix the encoding/decoding path so unicode queries work correctly and add regression test coverage." |

You ARE encouraged to veer away from the exact PR scope and use it only as a starting point. As long as you are asking for something genuinely challenging at the 6-8 hour level, that is more valuable than strictly matching the PR scope.

### Purpose of the PR in Writing Your Prompt

The PR exists for three reasons:
1. **Creativity hurdle**: Helps get past the challenge of coming up with a unique prompt
2. **Prompt diversity**: Keeps prompts varied
3. **Historical repo state**: Allows working off a historical state of a repo

Your prompt scope does not have to match the PR scope exactly.

### Example of a GOOD Prompt
> Update Gaphor's property editor to clearly separate model-level and diagram-level behavior for UML Dependency elements. Add a dedicated property page for Dependency model objects that shows Source and Target when selected from the model tree. Refactor the existing Dependency diagram item editor into a separate item-specific page with updated identifiers. Add support for the UML isFinalSpecialization attribute on classifiers and expose it through a toggle in the classifier property editor using proper transaction handling. Update the GTK UI definitions where needed and add unit tests to verify both Dependency property visibility and classifier specialization updates. The changes should follow the UML specification and leave the code production ready.

**Why it works:** Names exact components, verifiable outcomes, reads like a real issue, thinks about production, sounds human.

### Writing Quality Checklist
- [ ] No role-based prompting
- [ ] No LLMs used at any stage
- [ ] Names exact components and behaviours (no hand-waving)
- [ ] Outcomes are observable and testable
- [ ] Reads like a real GitHub issue
- [ ] Thinks about production: transaction handling, spec compliance, error handling
- [ ] Category selected that best fits initial prompt

### Scope Rules
- Prompt scope must be coherent (think of it as a hypothetical PR)
- You may add requirements beyond the real PR, provided they are relevant
- You must NOT request features entirely unrelated to the repo or PR scope
- For Greenfield, you may not use a PR at all
- Conversations can span multiple prompt types (that is expected)

### Prompt Strategy — The Divergence-Completion Principle

Your task must satisfy two constraints simultaneously:
1. **Divergence**: Model A and B must produce meaningfully different outputs (at least A3/B3 on key axes)
2. **Completion**: By the final turn, the code must be production-ready within the PR scope

**The 3-Turn Funnel:**
- **Turn 1** (~80-150 words): Describe the problem and desired outcome. Leave implementation to the model. Core implementation should get done. Open-ended Turn 1 forces models to make independent engineering decisions, creating natural differences.
- **Turn 2**: React to the winner's actual diff. Target 2-3 specific gaps. Most remaining gaps addressed.
- **Turn 3**: Integration verification, cleanup, final polish. Production-ready after this.

**What kills divergence (the A4/B4 trap):**
- Too-detailed Turn 1 where both models follow the same recipe
- Too-simple tasks where both models solve identically
- Prescriptive step-by-step instructions leaving no room for judgment

**PR scope sizing matters:** If your scope is too big, 3 turns is not enough to reach production-ready. If too small, Turn 1 finishes everything with nothing for Turn 2/3. The sweet spot: Turn 1 gets the core done with clear gaps visible in the diff for follow-up turns.

---

## PHASE 3 — ENVIRONMENT & CLI SETUP

### What this is
After your prompt is approved, you receive an email with a tarball of the repo at its pre-PR state (the code BEFORE the PR changes existed). You unpack it, set up the dev environment, create CLAUDE.md, install the CLI tool, and prepare everything so the model can actually run code.

### System Prerequisites
Git, VS Code (in PATH), Python, tmux, Terminal, Internet

### Step-by-step

#### 3.1 — Unpack the tarball & initialize git
```bash
tar -xvf <downloaded-file>.tar
cd <repo-folder>
git init
git add .
git commit -m "Initial commit"
```
**CRITICAL:** This is the ONLY `git commit` you ever run manually. The CLI manages all subsequent git state. Manual commits between turns corrupt trajectory tracking.

#### 3.2 — Set up the dev environment
```bash
# Example for Python:
python -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
pytest  # verify baseline tests pass
```
**Why this matters:** If the environment is broken, the model cannot run tests. That is YOUR fault, not the model's. Reviewers will NOT penalize the model for env issues you caused.

#### 3.3 — Create CLAUDE.md

If the repo does not already have one, create it BEFORE launching HFI. This way it is part of the repo state and both trajectory worktrees get it automatically. No manual cache copy needed.

If the repo already has a CLAUDE.md, use it as-is (you may make targeted additions).

**Do NOT ask the model to create CLAUDE.md via a turn prompt.** This is a rejection trigger.

CLAUDE.md should contain:
- Repository overview (what it does)
- Dev setup (how to install deps, run the project)
- Testing (how to run tests, e.g. `pytest tests/`)
- Code conventions (naming, structure, error handling patterns)
- Architecture (key modules and how they interact)

#### 3.4 — HEAD Commit Clarification

In the Pre-Thread Survey, "HEAD commit at the time the task was started" refers to:

| Correct | Incorrect |
|---------|-----------|
| The base repository commit representing the code **before** the PR changes. The commit from `git init && git add . && git commit` on the pre-PR tarball. | The commit at the tip of the PR branch (which already contains the changes). |

#### 3.5 — DO NOT Check Out the PR Branch
Checking out the PR branch loads code that already contains the feature. This defeats the purpose and can invalidate your submission. Always start from the pre-PR state.

#### 3.6 — Authenticate with Anthropic
Open: `https://feedback.anthropic.com/claude_code?email_login=true`
Login with your **Alias email** (NOT Google sign-in).

#### 3.7 — Download & install the CLI binary
```bash
mv ~/Downloads/darwin-arm64 claude-hfi
chmod +x claude-hfi
```
Every repository you work on must contain its own copy of claude-hfi at the root.

#### 3.8 — Launch the CLI

```bash
# tmux mode (what we use):
claude-hfi --tmux
# Auto-attach shortcut:
$(claude-hfi --tmux)

# VS Code mode (official docs default):
claude-hfi --vscode
```

When prompted for Interface Code, enter: **`cc_agentic_coding_next`**

### Launch Modes

| Mode | Command | Layout |
|------|---------|--------|
| **tmux** (what we use) | `claude-hfi --tmux` | Three separate tmux sessions: `<id>-control`, `<id>-A`, `<id>-B` |
| **VS Code** | `claude-hfi --vscode` | Control in terminal, two VS Code windows for trajectory worktrees |

### tmux Mode Session Layout
```
Session <id>-control:    Control (you interact here, enter prompts, submit feedback)
Session <id>-A:          Trajectory A
Session <id>-B:          Trajectory B
```

Attach to sessions: `tmux attach -t <session-id>-A` (or `-B`, or `-control`)

### Git Worktrees

HFI creates two isolated git worktrees:
```
Your project:               /path/to/your/project  (main repo)
Trajectory A worktree:      ~/.cache/claude-hfi/your-project/A
Trajectory B worktree:      ~/.cache/claude-hfi/your-project/B
```

Both start from identical file state. Changes in A do not affect B. Your main repo stays clean during execution.

If worktrees become corrupted: `rm -rf ~/.cache/claude-hfi/` (HFI recreates them on next run).

### CLAUDE_ENV_FILE

For projects using conda, virtualenv, or nvm:
```bash
echo 'conda activate myenv' > ~/my-env-setup.sh
export CLAUDE_ENV_FILE=./my-env-setup.sh
claude-hfi --tmux
```
When set, its contents are sourced before every Bash command, keeping the environment activated. HFI passes this to both trajectories automatically.

---

## PHASE 4 — TASK EXECUTION

### What this is
This is the actual work. You paste your approved prompt, the CLI sends it to two separate model instances (Trajectory A and Trajectory B), you review what each produces, iterate with follow-up prompts, and eventually pick the better output.

### Step-by-step

#### 4.1 — Paste your Turn 1 prompt
Paste the **exact prompt** from your approved Prompt Preparation. Press Enter. Both trajectories start working independently.

**Turn 1 must exactly match the approved Prompt Preparation. Significant deviations are grounds for rejection.**

#### 4.2 — Monitor trajectories (required)
Control shows session IDs. You MUST monitor both trajectory sessions:
```bash
tmux attach -t <session-id>-A
tmux attach -t <session-id>-B
```
Watch for permission prompts and user input requests. If a trajectory appears stuck, check if it is waiting for input.

#### 4.3 — Wait for completion
Control shows `Waiting for trajectories to complete...` and the feedback form appears when both finish.

#### 4.4 — Review both trajectories
For each trajectory:
1. Open the Source Control panel (or `git diff`) to see all modified files
2. Click every modified file and examine line-level diffs
3. Confirm requested behavior is implemented
4. Check for unnecessary/unrelated changes
5. Check for missing functionality
6. Identify edge cases not handled
7. Run tests if available
8. Verify new tests exist for new functionality

#### 4.5 — Submit feedback and continue
Rate which model did better using the feedback form. After feedback, the winner's changes are synced to your main repo and you enter the next prompt directly.

### Multi-Turn Sessions (No Restart Needed)

Multiple prompts work within a single session:
```
Turn 1: Prompt -> A & B execute -> Feedback -> Winner synced
Turn 2: Prompt -> A & B continue from winner -> Feedback -> Winner synced
Turn 3: Prompt -> A & B continue from winner -> Feedback -> Finish
```

**Do NOT run `git commit` between turns.** HFI manages git state automatically.

If a session gets stuck or context-limited, you can exit with `Ctrl+C` and relaunch with `./claude-hfi --tmux --continue` to resume. The `--continue` flag picks up the existing session state.

### Winner Syncing

After you submit feedback, HFI:
1. Determines the winner based on your overall preference rating
2. Copies all files from the winner's worktree to your main repository
3. Loads the winner's conversation state
4. Returns you to the prompt for the next turn

**Warning**: Any uncommitted changes in your main repo will be overwritten by the winner's state.

### Follow-Up Turn Rules (minimum 3 meaningful turns total)

Each follow-up must:
- **Identify a specific issue** (name the file, function, behavior)
- **Request a concrete change** (not "review everything")
- **Advance the implementation** meaningfully
- **Remain relevant** to the original task

Related functionality (missing edge cases, tests, secondary features) may be introduced in later turns. Requirements entirely unrelated to the original task, contradicting earlier instructions, or belonging in a separate PR are NOT acceptable.

### Turn Contradictions (Rejection Trigger)
- Turn 1 says "do not add comments" -> Turn 2 criticizes "model didnt add comments"
- Turn 1 requests a new test file -> Turn 2 asks to delete that same file

### Non-Meaningful Follow-Ups (Rejection Trigger)
- "Please double check that all changes were applied correctly"
- "Review the implementation and fix anything that might be wrong"
- "Ensure everything is production ready"
- "Check for any remaining bugs or improvements"

### Turn Examples

**Good Turn 2:**
> "The `compute_serialized_data` function in `serialization/compute.py` does not handle the case where `spec.deps` is empty. It will produce a `KeyError` when looking up downstream neighbors. Add a guard for empty deps and add a test in `test_load_defs.py` that passes an asset spec with no dependencies."

**Bad Turn 2:**
> "Please review everything and make sure it works correctly."

### Final Preferred Output
If additional turns could clearly bring the preferred output to an acceptable state but you stopped short, the submission may be rejected. Use all available turns to reach a production-ready result.

### Feedback Form Navigation

| Key | Action |
|-----|--------|
| Up/Down or j/k | Move between questions |
| Left/Right or h/l | Select rating on scale |
| Enter | Submit answer / Continue to next question |
| ? | Show description of current question |
| Ctrl+C (double press) | Exit HFI |

---

## PHASE 5 — REVIEW DIFFS & TRACES

### What this is
You must not just look at the final code, but also review HOW the model thought and worked. Read the model's reasoning (traces) alongside the code changes (diffs).

### What You Must Review
- The code diff **line-by-line** for each trajectory
- The model traces to evaluate how the model reasoned and acted
- Run the code to verify it works and identify what is missing

### What to Look for in Traces

| Question | What it reveals |
|----------|----------------|
| Did it actually run tests, or did it only claim to? | Verification discipline |
| Did it investigate the root cause, or patch symptoms? | Engineering depth |
| Did it avoid risky actions (force push, delete) without asking? | Safety judgment |
| Did it keep scope tight and avoid unrelated changes? | Scope control |
| Did it accurately report what it changed? | Self-reporting honesty |
| Did it ask clarification when genuinely needed? | Question discipline |

---

## PHASE 6 — EVALUATION WRITEUP

### What this is
You fill in a structured form comparing Model A vs. Model B. Every claim must reference specific files, functions, or test output. No hand-waving.

### Required Text Fields (7 total)

For each category where you selected anything other than an equivalent rating, your fields MUST contain explicit, evidence-backed reasons referencing specific files, functions, tests, or trace behaviour.

| # | Field | What to Write |
|---|-------|---------------|
| 1 | **Senior Engineer Expectations** | What would a strong senior engineer do given your prompt? This sets the baseline. |
| 2 | **Model A: Solution Quality** | Correctness, code quality, edge cases, tests. For Discussion/Ambiguous/Code Review: quality of reasoning/analysis. Must be evaluative with evidence. |
| 3 | **Model A: Agency** | How it behaved as an independent agent: risky/destructive actions (or restraint), independent judgment, when it sought clarification. Must cite specific transcript evidence. |
| 4 | **Model A: Communication** | Quality of written output: clarity of reasoning and summary, honesty about what it did and did not do, documentation and comments. Reference transcript. |
| 5 | **Model B: Solution Quality** | Same as #2 but for Model B. |
| 6 | **Model B: Agency** | Same as #3 but for Model B. |
| 7 | **Model B: Communication** | Same as #4 but for Model B. |

### SxS Question Mappings

| Field | Maps to SxS Questions |
|-------|----------------------|
| Solution Quality | 5.1, 5.2, 5.3, 5.4, 5.8 |
| Agency | 5.5, 5.7, 5.9 |
| Communication | 5.6 |

### Fields Must Be EVALUATIVE, Not Descriptive

Each field should explain **why** something matters in context of the rating, not just describe that it happened.

| Descriptive (WEAK) | Evaluative (STRONG) |
|--------------------|---------------------|
| "Model A added tests" | "Model A added regression coverage in tests/test_search.py::test_non_ascii_query. Without this test, a future refactor could silently reintroduce the bug." |
| "Model B has better error handling" | "Model B wraps the getQuote and addPromoCode calls in try/catch with distinct error messages that use the logger. Model A adds try/catch but does not parse the error object from the upstream 200 response." |

### How to Fill These Fields Well

- **Evaluate each model independently** in the per-model fields. Focus on what that model did on its own. Save A-vs-B comparison for the overall justification and key-axis.
- **Build observations while reviewing.** Take notes as you go through diffs and traces, not after.
- **Only include observations relevant to the rated axes.** Do not pad with irrelevant things (response time, number of tool calls).
- **Overall justification must be self-contained.** Assume the reader has no access to your per-model fields. Resurface the key evidence.
- Always use the exact terms **"Model A"** and **"Model B"**.
- **Write in a text editor first, paste into the CLI.** Writing directly in the tmux form leads to rushed, thin feedback.
- **Imperfect but honest > polished AI.** Do not over-correct. Browser spellchecker is fine, Grammarly is not.
- **Go deeper than the surface.** What looks like "73 great test cases" might be garbage when you check what they test. What looks like "model failed" might be a minor coordinate issue when you read the code.
- **Check HOW, not just WHAT.** If both models ran the linter, check how each ran it — one might have used the wrong command or applied autofixing that created undesirable changes.

### Axis Questions (6.1 through 6.11)

| # | Question | What to Write |
|---|----------|--------------|
| 6.1 | Did it get the right answer? | What was implemented; whether it matches required behaviour; where it still fails; how you verified. |
| 6.2 | Is code well-structured / consistent? | What files changed; whether helpers match existing patterns; naming, structure, error handling follow conventions. |
| 6.3 | Did it follow directions + CLAUDE.md? | Whether it followed prompt constraints; avoided forbidden behaviour; any justified deviations. |
| 6.4 | Did it right-size the solution? | Did it overbuild or underdeliver? Did it change unrelated files? |
| 6.5 | Did it confirm before destructive actions? | List risky actions and whether it asked first. If none, state that explicitly. |
| 6.6 | Did it accurately report what it did? | Compare model claims vs actual diffs. Call out false claims. |
| 6.7 | Professional judgment (not sycophantic)? | Did it challenge bad assumptions? Suggest alternatives? Proceed when it should have asked? |
| 6.8 | Did it check its work (tests/edges)? | What tests were run or not; failures fixed or suppressed; edge cases covered. |
| 6.9 | Did it ask questions only when ambiguous? | Which questions asked; whether needed; whether discoverable by reading code. |
| 6.10 | Senior SWE-like approach? | Sound engineering process: planning, exploring before acting, verifying assumptions. |
| 6.11 | Communication clear and concise? | Easy to understand, appropriately concise, professional tone. |

---

## PHASE 7 — RATING & JUSTIFICATION RULES

### What this is
You assign a relative preference rating (A1 through B1) and fill in the key-axis field. Every rating must be backed by specific evidence from your evaluation writeup. This is where internal consistency matters most — reviewers will flag mismatches between your written evaluation and your numeric ratings.

### Rating Scale

| Rating | Meaning | Required Language |
|--------|---------|-------------------|
| A1 | A is clearly superior | "fails", "incorrect", "broken" |
| A2 | A is significantly better | "substantially better", "missing key coverage" |
| A3 | A is better overall | "better structured", "tighter scope" |
| A4/B4 | Effectively equivalent | "minor differences only" |
| B3 | B is better overall | same as A3 for B |
| B2 | B is significantly better | same as A2 for B |
| B1 | B is clearly superior | same as A1 for B |

### Core Rules

- **Multi-axis rating required.** Submissions without a selected rating will be rejected. N/A must NOT be used.
- **Compare A vs B against each other**, NOT against an ideal output. If A=60% correct, B=30%, rate A2 or A3, NOT A4/B4.
- **Justification language must match rating magnitude.** "Clearly better" with A3, or "slightly more readable" with A1 creates ambiguity and will be flagged.

### Key-Axis Field

Required for A1, A2, A3, B1, B2, B3. Name the specific dimension that drove the preference (e.g., correctness, test coverage, scope control, root cause handling, accuracy of self-reporting). One sentence is sufficient.

**Calibration rule**: Do NOT default to correctness. Choose the axis that best explains the preference signal. If the deciding factor was tighter scope control, better testing discipline, or more accurate/honest self-reporting, select that directly.

### Common Rating Mistakes (Rejection Triggers)

| Mistake | Why It Gets Rejected |
|---------|---------------------|
| Extreme ratings (A1/B1) not supported by diffs | Unjustified extremes undermine credibility |
| Selecting "equivalent" when a real difference exists | Avoiding making a call is itself a justification issue |
| Overuse of N/A ratings | Excessive N/A signals disengagement |
| Vague or generic justifications | Must reference specific files, functions, behaviors |
| Ratings not aligned with written evaluation fields | Internal contradiction will be flagged |
| Justification language doesn't match rating magnitude | Ambiguity for reviewers |
| Anchoring on ideal output instead of relative performance | Rate the delta between A and B |
| Fields only summarise (not evaluative) | Must explain WHY it matters |
| Key-axis field left empty for non-equivalent preference | Required for all non-A4/B4 ratings |
| Defaulting key-axis to correctness | Use the axis that actually decided it |
| Praising a model for work it did not do | Verify every claim against the actual diff |

---

## PHASE 8 — SUBMISSION CHECKER

### What this is
An optional but recommended sanity-check tool on Snorkel. You paste your prompts, ratings, and feedback fields, and it flags common issues before you submit for real.

### How to use
1. Go to Snorkel -> **Marlin-Submission-Checker-V3**
2. Fill in fields per turn: prompt, Model A/B Solution Quality/Agency/Communication, SxS ratings
3. Hit feedback button to run checks
4. Fix any flagged issues
5. Copy clean values into the CLI submission

### What it flags
- Your overall justification favors one model but SxS scores favor the other
- Ratings not explained in written feedback
- Prompts that reference the PR directly
- Follow-up prompts that repeat Turn 1

### Multi-Turn Prompt Checker
Second tab: paste prompts across turns and it flags redundant requests or scope drift.

### Important
- This tool is optional and nothing auto-rejects your submission
- Checks are experimental (flag disagreements in Slack)
- Flagged issues are a preview of what reviewers look for
- Getting green here is a good sign

---

## PHASE 9 — FINAL SUBMIT

### What this is
You go to Marlin-Prompt-Review V3 on Snorkel, claim your task, paste everything, and submit. **This is irreversible.** Once submitted, you cannot edit.

### Steps
1. Navigate to **Marlin-Prompt-Review V3**
2. Claim your task
3. Paste: PR URL, evaluation writeup, all ratings and justifications
4. Review everything one final time
5. Submit

### If You Submit Too Early
You cannot fix it. The recovery path:
1. Skip the task
2. Restart the entire workflow from Phase 1
3. Get new Prompt Prep approval
4. Use the NEW tarball
5. Re-run the CLI

Attempting to reuse an old tarball or partial run may invalidate the new submission.

### Large Diffs Warning
If you see unexpectedly large diffs touching many files, you likely ran the CLI without initializing the repo first. Must run `git init && git add . && git commit` before launching.

---

## 10. LLM Detection Rules

### What this is
The review team checks all human-written text (prompts, evaluations, justifications) for signs of LLM generation. Understanding what gets flagged helps you write naturally and avoid false positives.

### Standard
The review team uses a **beyond-reasonable-doubt** standard. Rejection requires:
- **3-4 cumulative distinct repeated signals**, OR
- **One critical signal** (hallucination or chat-log leak)

Not all suspected LLM content should be rejected. The totality of the writing sample along with these flags are considered together.

### Two Categories of LLM Signals

**Category 1: Unnaturally "over-correct" writing** that a human would be unlikely to write

**Category 2: Hallucinations or contrived mistakes** from LLMs attempting to mimic natural writing

### Specific Signals That Get Flagged

#### 1. Hallucinations
Referencing functions, files, or constants that don't exist in the codebase.

**Example**: "Correctly handles datetime objects by calling isinstance() early, reusing the to_iso_string() utility to normalize before returning True." (to_iso_string() does not exist anywhere.)

#### 2. Uncommon ASCII Characters
Em-dashes, arrows used consistently, especially mid-sentence.

**Example**: "fastapi/params.py -- Add a scope field. fastapi/types.py -- Change the cache key." (Seven consecutive bullets each using a perfectly formatted em-dash.)

#### 3. Random Markdown or Bolding
Terms bolded, italicized, or wrapped in code font with no clear reason.

**Example**: "The **core behavior** seems solid. It stayed scoped to `pricing/discounts.py` which is what we want. Run **pytest** to verify." (Bolding random phrases for no reason.)

#### 4. Grammar That Is Too Perfect
No casual phrasing, no hesitation, no typos anywhere in a long piece of writing.

**Example**: Two full paragraphs of evaluation with zero contractions, zero hedging, and zero casual phrasing. Every sentence reads like edited prose rather than a developer writing during a review session.

#### 5. Justifications in Batched Lists
Multiple parallel reasons given for a simple thing, when a human would just pick the main one.

**Example**: "Solution Quality (B): Leverages the validate_format_chain() helper... The formats list is passed through DATE_FORMAT_REGISTRY... Correctly handles datetime objects... Adds implicit support for timezone-aware strings..." (Four justifications with equal weight and perfect parallel structure.)

---

## 11. Dispute Process

### What this is
If you believe a rejection was wrong, you can dispute it through Linear. There is a limit on how many denied disputes you can accumulate, so only dispute when you genuinely believe the rejection was incorrect.

- Disputes go to **Marlin-Submission-Disputes-V3** project in Linear
- **2-Dispute Denial Limit**: Goes into effect April 11, 2026. If 2 disputes are denied, further consequences apply.
- The dispute form includes a version toggle so reviewers know which guidelines version was used

---

## 12. Troubleshooting & FAQ

### Common Questions
- **Can I skip steps or jump ahead?** No. Steps must be completed sequentially.
- **Is the prompt the same thing as the PR?** No. The PR defines what should change. The prompt defines how the model should implement those changes.
- **Can I select multiple PRs?** Yes. You are responsible for managing your workload.
- **Can I use external LLMs or AI tools?** No. All reasoning and evaluation must be your own.
- **Why do I see two model responses?** Each turn produces two alternative outputs. Review both, compare, and select the stronger result.

### Common Issues

| Issue | Fix |
|-------|-----|
| "Not at git repository root" | `cd $(git rev-parse --show-toplevel)` |
| "Not in a git repository" | `git init` |
| Authentication failed | Re-run to trigger new auth flow. Contact #claude-cli-feedback if persistent. |
| Worktree sync failed | `git status` to check conflicts, `git stash` uncommitted changes, or `rm -rf ~/.cache/claude-hfi/` |
| Conda/virtualenv not activated in worktrees | Use `CLAUDE_ENV_FILE` |
| Trajectory appears stuck | Check if waiting for input (permission prompt, interactive tool). Attach to tmux and provide input. |
| Tmux not found | `brew install tmux` (macOS) |
| VS Code doesn't open in --vscode mode | Cmd+Shift+P -> "Shell Command: Install 'code' command in PATH" |

### Reporting Issues

**CLI Tool Issues**: Report via Slack workflow in #ec-marlin-support-v2. Upload a zip of the **entire debug folder** (not just the .txt file). Find debug path: look for `Logging to: /var/folders/.../claude-hfi/<session-id>/debug.txt` and zip that folder.

**Snorkel Platform Issues**: Post in #ec-marlin-support-v2 with the task ID (UID from right side of task, or UUID from left side of dashboard).

---

## APPENDIX A — COMMON MISTAKES CHECKLIST

### Pre-submission verification (check every box)

- [ ] Prompt does NOT reference the PR
- [ ] Prompt was NOT created with an LLM
- [ ] Did NOT ask model to create CLAUDE.md via turn prompt
- [ ] Used the pre-PR tarball (NOT the PR branch)
- [ ] At least 3 meaningful turns with real code changes
- [ ] Turn 1 matches approved Prompt Preparation
- [ ] Each follow-up identifies specific issue + requests concrete change
- [ ] Ratings supported by actual diffs
- [ ] Ratings, Agency/Communication/Solution Quality fields, and justifications are internally consistent
- [ ] Final preferred output is production-ready
- [ ] Prompt is NOT over-prescriptive
- [ ] Dev environment was set up before CLI run
- [ ] SxS scores = relative performance (not closeness to ideal)
- [ ] Justification language matches rating magnitude
- [ ] Solution Quality/Agency/Communication fields are evaluative (explain WHY), not descriptive
- [ ] Key-axis field completed for A1/A2/A3/B1/B2/B3
- [ ] Key-axis does NOT default to correctness (pick the real deciding axis)
- [ ] Evaluation writeup covers all 11 axis questions with evidence
- [ ] Diffs AND model traces reviewed before submission

### Top rejection reasons
1. Prompt references the PR
2. Role-based prompting ("Act as...")
3. Prompt created with LLM
4. Asking model to create CLAUDE.md
5. Fewer than 3 meaningful turns
6. Non-meaningful follow-ups ("review everything")
7. Checked out PR branch instead of pre-PR tarball
8. Over-prescriptive prompt
9. Wrong category selected
10. Ratings not aligned with evaluation fields
11. Extreme ratings (A1/B1) not supported by diffs
12. Praising model for work not visible in diff

---

## APPENDIX B — PROMPT TEMPLATES LIBRARY

Ready-to-use templates. Combine as needed.

**Important:** These templates are structural starting points. For Turn 1, keep the prompt shorter and more open-ended than shown here to create divergence between Model A and B (see "Prompt Strategy" in Phase 2). Describe the problem and desired outcome, not step-by-step instructions.

### B.1 — Turn 1: Refactor Category

```
The [module/subsystem name] in this repository currently [describe current behavior
and its problems].

Refactor the [module] to:

1. Define explicit, serializable data classes for [list the key data concepts].
   Each class must round-trip cleanly through the project's serialization framework.

2. Consolidate all computation of this data into a single module that:
   - Walks [source of truth]
   - Queries [external system] for relevant state
   - Builds upstream/downstream adjacency, per-group sets, and ordering
   - Returns the top-level serializable bundle

3. Add a reconstruction path: when loading in reconstruction mode and cached
   metadata is available, deserialize from cache instead of recomputing.

4. Introduce a facade type that wraps the serialized data and exposes only
   query methods.

5. Remove the old utility module(s) that held the scattered logic.

6. Update tests to cover the new data shapes, round-trip serialization, and
   at least one reconstruction path.

The code must be production-ready: no broken imports, no orphaned references,
all existing tests still pass.
```

### B.2 — Turn 2: Edge Cases / Hardening

```
Review the refactored [module] from the previous turn. I have identified the
following gaps:

1. [Specific gap, e.g., "When an asset spec has zero dependencies, the
   downstream adjacency lookup produces a KeyError because the key was never
   initialized."] Add a guard and a test case.

2. [Second gap, e.g., "The custom field serializer for non-scalar-key mappings
   does not handle an empty mapping."] Add a test that round-trips an empty
   mapping.

3. [Third gap, e.g., "The facade's topo_order_index method calls list.index()
   which is O(n). For large graphs this could be slow."] Pre-compute a lookup
   dict during construction if feasible.

Fix each issue and ensure all tests (old and new) pass.
```

### B.3 — Turn 3: Integration / Cleanup

```
The refactored [module] and its edge-case fixes from the previous turns need
integration verification:

1. Run the full test suite and report any failures. For each failure, identify
   root cause and fix it.

2. Verify that the sensor module now delegates to the facade rather than doing
   its own computation. If any redundant logic remains, remove it.

3. Confirm that no file still imports from the deleted utility module. Fix any
   orphaned imports.

4. Check that CLAUDE.md accurately reflects the new module structure. Update
   if needed.

Leave the code production-ready.
```

### B.4 — Discussion/Explaining Category (Turn 1)

```
Walk me through how [specific subsystem] works in this codebase:

1. What data is computed, from what sources, and in what order?
2. How does the serialization boundary work, what gets cached, where, and
   how is it recovered during reconstruction?
3. What are the performance implications of the current design for large
   graphs?
4. Are there any single points of failure or data consistency risks?

Be specific: reference file paths, class names, and function signatures.
Do not generate code, this is an analysis question.
```

### B.5 — Bug Fix Category (Turn 1)

```
There is a bug in [module/file]: when [specific trigger condition], the system
[describe failure].

Fix the bug by:
1. Adding defensive handling for [the specific condition]
2. Emitting a warning log when the inconsistency is detected
3. Adding a regression test that reproduces the scenario and verifies the fix

Do not change unrelated code. All existing tests must continue to pass.
```

### B.6 — Testing & QA Category (Turn 1)

```
The [module/subsystem] currently has minimal test coverage. Add comprehensive
tests covering:

1. Unit tests for each serializable data class, verify construction, field
   access, and round-trip serialization/deserialization.
2. Integration test for the compute function, mock external API calls, provide
   realistic specs with dependencies, verify output structure.
3. Edge cases:
   - Empty definitions (no assets, no DAGs)
   - Asset with no dependencies
   - Circular dependency handling
   - DAG with no tasks
   - Multiple DAGs sharing the same key
4. Reconstruction test, serialize computed data, deserialize, verify equality.

Use the project's existing test framework and conventions. All tests must pass.
```

---

## APPENDIX C — QUICK REFERENCE CARD

### Rating Scale at a Glance
```
A1  clearly superior     "fails / broken / incorrect"
A2  significantly better "substantially better / missing key coverage"
A3  better overall       "better structured / tighter scope"
A4  equivalent           "minor differences only"
B3  B is better overall
B2  B is significantly better
B1  B is clearly superior
```

### Key Numbers
- **3**: Minimum meaningful turns required
- **6-8 hours**: Target engineering effort for prompt complexity
- **11**: Number of axis questions (6.1 through 6.11)
- **7**: Number of required text fields in evaluation writeup
- **14**: Number of prompt categories
- **6**: Number of supported languages
- **3-4**: Number of cumulative LLM signals needed for rejection (or 1 critical)

### Critical "Do NOT" List
1. Do NOT push to public repos
2. Do NOT use external LLMs
3. Do NOT reference the PR in prompts
4. Do NOT use role-based prompting
5. Do NOT ask model to create CLAUDE.md
6. Do NOT run git commit between turns
7. Do NOT check out the PR branch
8. Do NOT use N/A for any axis
9. Do NOT default key-axis to correctness
10. Do NOT write over-prescriptive prompts
11. Do NOT use "Sign in with Google" for auth
12. Do NOT skip dev environment setup

---

## APPENDIX D — GAP ANALYSIS VS PLAYBOOK

### Rules in Official PDFs MISSING from playbook.md

| # | Missing Rule | PDF Source | Impact |
|---|-------------|-----------|--------|
| 1 | **Beyond-reasonable-doubt LLM detection threshold**: 3-4 cumulative signals OR one critical signal needed for rejection. Not all suspected LLM content should be rejected. | Training_8 | HIGH: Calibrates how aggressively to avoid LLM signals. |
| 2 | **Five specific LLM signal examples**: Hallucinations, uncommon ASCII (em-dashes), random markdown/bolding, grammar too perfect, batched parallel lists. | Training_7 | HIGH: Playbook lacks batched-list, random-bolding, and grammar-too-perfect patterns. |
| 3 | **Two categories of LLM signals** officially defined: (a) over-correct writing, (b) hallucinations/contrived mistakes. | Training_7, Training_8 | MEDIUM: Helps prioritize which signals are most dangerous. |
| 4 | **Submission Checker tool details**: How to access, what it flags (justification/SxS mismatch, unexplained ratings, PR references, repeated follow-ups), multi-turn tab. | Training_6 | MEDIUM: Playbook says "run checker" but not how it works. |
| 5 | **Explaining vs Discussion distinction**: Explaining = how code works. Discussion = reasoning through tradeoffs. | Training_1, Training_2, Training_8 | LOW |
| 6 | **Accidental submission recovery**: Skip task, restart from Phase 1, new tarball. | Training_4 | LOW |
| 7 | **Category rebalancing**: Popular categories may be temporarily disabled. | Training_1 | LOW |
| 8 | **Issue reporting procedures**: CLI issues via Slack workflow with debug folder zip. Snorkel issues with task ID. | Training_9 | LOW |
| 9 | **Large diffs from not initializing repo**: Must run `git init && git add . && git commit` before CLI. | Training_7 | LOW |
| 10 | **Dispute 2-denial limit timing**: Goes into effect April 11, 2026. | Training_8 | MEDIUM |
| 11 | **Conversations spanning multiple prompt types**: Explicitly stated. Declare initial only. Reviewers account for evolution. | Training_2, Training_5 | LOW |
| 12 | **Category mismatch enforcement**: Severe mismatch = reject, partial match = reviewer may modify. | Training_2 | LOW |

### Rules in playbook.md NOT from Official PDFs (Custom Additions)

| # | Custom Rule | Assessment |
|---|------------|------------|
| 1 | **Grounding Rules section** (cross-model verification, scope deviation, evidence grounding, trace-vs-diff reconciliation, pre-submission diff audit) | KEEP: Critical, derived from rejection feedback. PDFs say "verify against diffs" generically; our rules operationalize this. |
| 2 | **Scenario Handbook** (context limit, one-fails, partial completion, identical output, both fail, scope deviation, Greenfield setup, feedback timeout, worktree corruption, winner syncing) | KEEP: Invaluable operational guidance not in PDFs. |
| 3 | **Word count "150-300 words" for initial prompt** | CAUTION: PDFs do NOT specify a word count. PDFs say "6-8 engineer-hours of complexity" without word limits. |
| 4 | **LLM signature words list** (leverage, utilize, delve, comprehensive, robust, streamline, facilitate, encompass, pivotal, intricate, nuanced, paradigm) | KEEP: Good safeguard. PDFs warn about LLM signals generally but do not list specific words beyond em-dashes. |
| 5 | **Key-axis must use axis NAME not raw numbers** ("NEVER 6.1, 6.2") | KEEP: PDFs say "name the specific dimension" which implies this; our explicit prohibition is clearer. |
| 6 | **CLAUDE_ENV_FILE for conda/virtualenv/nvm** | KEEP: Practical guidance from HFI CLI docs. PDFs say "set up dev environment" without mentioning this mechanism. |
| 7 | **Turn 2/3 prompt templates** | KEEP: Useful starting points. Not from PDFs. |
| 8 | **All automation scripts and commands** (hfi_orchestrator.sh, playbook.md automation section) | KEEP: Our custom tooling. Not from PDFs. |
| 9 | **Blanket extreme ratings prohibition** ("NEVER rate all 11 axes identically") | KEEP: Derived from "Extreme ratings not supported by diffs" in Training_7. |
| 10 | **Rating for identical output** ("lean towards one model based on trace behavior") | KEEP: Operational guidance. PDFs don't address this scenario explicitly. |

### Contradictions Found

| # | Playbook Says | PDFs Say | Resolution |
|---|--------------|---------|------------|
| 1 | **CLAUDE.md**: Create before launching HFI. Both worktrees get it automatically. No manual cache copy. | **CLAUDE.md**: Launch HFI first, create CLAUDE.md after, then copy to cache manually. (Training_0, Training_4, Training_5) | **Follow playbook approach.** Create before launch so both worktrees see it automatically. Simpler and proven in our workflow. |
| 2 | "2-Dispute Denial Limit is in effect" | "Goes into effect April 11, 2026." (Training_8) | **Timing dependent.** Until April 11, the limit is not enforced. After that date, if 2 disputes are denied, further consequences apply. |

### Automation & Tooling References

This guide is part of the Marlin V3 Automation suite. Related files:

| File | Purpose |
|------|---------|
| `automation/playbook.md` | Operational playbook with grounding rules, scenario handbook, and automation commands |
| `automation/hfi_orchestrator.sh` | Shell script that automates tarball setup, git init, CLI launch, and environment configuration |
| `docs/HUMANIZER_PROMPT.md` | Rules for humanizing all written text to avoid LLM detection |
| `docs/reference/hfi_cli_docs.md` | Detailed HFI CLI documentation (tmux mode, worktrees, winner syncing) |
| `docs/reference/marlin_v3_training_consolidated.md` | Raw extraction from all 10 training PDFs with source attribution |

---

*Consolidated from all 10 Marlin EC Training documents + HFI CLI docs + operational experience. Last updated: 2026-04-04.*
