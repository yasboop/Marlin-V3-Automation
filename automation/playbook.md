# MARLIN V3 — CURSOR-NATIVE AUTOMATION (FULL WORKFLOW)

> This file is the single source of truth for ALL Marlin V3 phases (1-8).
> Cursor reads this file, fetches REAL data using `gh` CLI, and handles everything directly.
> Python is used only for clipboard capture and prompt validation. All GitHub data fetching and analysis is done by Cursor via `gh` CLI.

---

## MARLIN V3 RULES (CONSOLIDATED FROM ALL DOCS)

These rules are extracted from all 6 documentation files. Violations of any = task rejection.

### Prompt Rules
- NO em-dashes (Unicode U+2014 or "--" that renders as long dash). Use hyphens or commas.
- NO PR references (#number, pull/number, "this PR", branch names).
- NO role-based prompting ("You are a senior engineer", "Act as an expert").
- NO over-prescriptive instructions ("on line 47, change X to Y").
- NO LLM signature words: leverage, utilize, delve, comprehensive, robust, streamline, facilitate, encompass, pivotal, intricate, nuanced, paradigm.
- Word count: 150-300 words for initial prompt.
- Must read like a human-written GitHub issue, not an AI spec.
- Turn 1 prompt MUST exactly match the Snorkel-approved prompt. No modifications.

### Multi-Turn Rules
- Minimum 3 meaningful turns required. Non-meaningful follow-ups = rejection.
- MUST exit HFI (Ctrl+C) and relaunch with `--continue` between every turn.
- DO NOT run `git commit` between turns. HFI manages git state.
- Each follow-up must target a DIFFERENT specific file/function gap.
- Never ask to "review everything" or "check for bugs" -- too vague.
- After Turn 1 & 2 feedback: select "Continue conversation".
- After Turn 3 feedback: select "Finish conversation".

### CLAUDE.md Rules
- Create AFTER launching HFI, not before.
- DO NOT use claude-hfi to generate CLAUDE.md.
- Must manually copy to both A/B worktree caches (`~/.cache/claude-hfi/<project>/A/` and `/B/`).
- A bad CLAUDE.md leads to bad trajectories.

### Feedback Form Rules
- Strengths must be EVALUATIVE, not descriptive. Use "because" / "which means" to explain impact.
- N/A only for truly inapplicable axes. Overusing N/A = rejection.
- Key-axis REQUIRED for all non-equivalent ratings (A1-A3, B1-B3).
- Extreme ratings (A1/B1) require strong evidence ("fails", "broken", "incorrect").
- Overall preference must be consistent with axis ratings majority.
- Rating language: A1/B1 = "fails/broken", A2/B2 = "substantially better", A3/B3 = "better structured", A4/B4 = "minor differences only".

### Submission Rules
- Submissions are IRREVERSIBLE. Cannot edit after clicking Submit.
- Run Snorkel Submission Checker before final submit.
- Review model traces (reasoning, tool calls) in tmux sessions, not just code diffs.
- Pre-Thread Survey HEAD commit = the git hash from `cmd_setup`, NOT the `git init` hash.

### Environment Rules
- Interface code for V3: `cc_agentic_coding_next`
- Use ALIAS email for auth, not Google account.
- If repo has virtual env, set `CLAUDE_ENV_FILE` before launching HFI.
- Keep tmux trajectory sessions visible -- approve permission prompts manually.

### Official V3 Prompt Categories (14)
1. Git  2. Ambiguous  3. Discussion  4. Explaining  5. Code Review
6. Refactor  7. Greenfield  8. Bug Fix  9. Chore  10. Documentation
11. New Feature  12. Performance  13. Testing and Quality Assurance  14. Other

---

## WRITING STYLE RULES (APPLY TO ALL GENERATED TEXT)

When generating any text that the user will paste into Snorkel or submit,
follow these rules to produce natural-sounding human writing:

1. COMPACT TECHNICAL LISTS: No spaces after commas in technical 
   term lists. Write "VAE,UNet,SD3,Flux" not "VAE, UNet, SD3, Flux"
   
2. DROP APOSTROPHES: Write "dont", "its", "wont", "thats", "doesnt",
   "isnt", "cant" instead of the contracted forms

3. OCCASIONAL SPACING QUIRKS: Sometimes put a space before a comma
   like "makes it harder ,plus" -- not every comma, just 1 in 4

4. USE ABBREVIATIONS: param (not parameter), repo (not repository),
   config (not configuration), deps (not dependencies), 
   SOTA (not state-of-the-art), dev (not development)

5. DASHES OVER FORMAL CONNECTORS: Use " - " instead of semicolons
   or "which includes" / "including" clause structures

6. NO TRAILING PERIODS: Drop the period from the last sentence
   of each section

7. INFORMAL PHRASING: Use casual phrases like "all over the place"
   instead of "fragmented", "a bunch of" instead of "multiple",
   "set up" instead of "implement"

8. NO PERFECT PARALLEL STRUCTURE: Avoid balanced "both X and Y"
   or "not only X but also Y" constructions. Just say things plainly

9. RUN-ON SENTENCES: Use comma splices instead of always starting
   new sentences. Chain thoughts with commas

10. COMPACT PARENTHETICALS: No spaces inside parenthetical groups.
    Write "(DiT,PixArt,Flux,SD3)" not "(DiT, PixArt, Flux, SD3)"

11. VARY OPENERS: Never start consecutive bullets or list items with
    the same phrase. Mix up how each one begins -- some with the subject,
    some with a verb, some just stating the end state directly.
    BAD: "Done when X... Done when Y... Done when Z..."
    GOOD: "X verifies that... All duplicate Y removed from... Empty Z methods have..."

### EXAMPLE 1 (follow this style exactly)

BAD (high AI detection):
"The gradient checkpointing test coverage across the diffusers model test
suite is fragmented. Multiple model test files (VAE, UNet2DCondition,
UNetMotion, UNetSpatioTemporal, ControlNetXS) each carry their own
copy-pasted implementation of gradient checkpointing verification logic,
including both the numerical equivalence test (forward pass with and without
checkpointing, comparing loss and parameter gradients) and the module
registration test (monkey-patching _set_gradient_checkpointing to track
which modules get enabled). This duplication makes maintenance expensive
and leaves newer transformer model tests without any gradient checkpointing
coverage at all. The work involves consolidating these tests into the
shared ModelTesterMixin so every model that supports gradient checkpointing
gets tested uniformly."

GOOD (1% AI detection):
"The gradient checkpointing tests across the diffusers test suite are all
over the place right now. The VAE,UNet2DCondition,UNetMotion,UNetSpatioTemporal
and ControlNetXS test files each have their own copy-pasted version of the
gradient checkpointing verification logic - the numerical equivalence
check(forward pass with and without checkpointing,comparing loss and param
gradients) and the module registration check(monkey-patching
_set_gradient_checkpointing to track which modules get enabled). Its a lot
of duplicated code that makes maintaining things harder ,plus the newer
transformer model tests dont even have any gradient checkpointing coverage.
The fix is consolidating all of this into the shared ModelTesterMixin so
all models that support gradient checkpointing get tested the same way"

### EXAMPLE 2

BAD (high AI detection):
"Diffusers is a PyTorch library maintained by Hugging Face for
state-of-the-art diffusion models covering image, video, and audio
generation. The codebase organizes models into subpackages -- autoencoders
(VAE variants), UNets (2D conditional, motion, spatiotemporal, ControlNetXS),
and transformers (DiT, PixArt, Flux, SD3, CogVideoX, Allegro, AuraFlow,
Latte, CogView3Plus). Each model class inherits from a shared ModelMixin
base, and the test suite mirrors this structure with a common test mixin
(ModelTesterMixin in test_modeling_common.py) that individual model test
files extend."

GOOD (1% AI detection):
"Diffusers is a PyTorch library maintained by Hugging Face for SOTA
diffusion models that covers image,video and audio generation. The codebase
organizes the models into subpackages autoencoders ,VAE variants,
UNets(2Dconditional,motion,spatiotemporal,ControlNetXS) and
transformers(DiT,PixArt,Flux,SD3,CogVideoX,Allegro,AuraFlow,Latte,CogView3Plus),
Each model class inherits from a shared ModelMixin base, and the test suite
mirrors this structure with a common test mixin(ModelTesterMixin in
test_modeling_common.py) that individual model test files extend"

Key changes: "SOTA" instead of "state-of-the-art", missing space after commas
in "image,video", space before comma in "autoencoders ,VAE", compact
parenthetical groups with no spaces, comma splice instead of period between
sentences, no trailing period.

Both examples show: same content, same meaning -- only formatting
imperfections and casual phrasing differ.

---

## SCENARIO HANDBOOK (EDGE CASES AND WHAT TO DO)

### When a trajectory hits context limit
- The model reads too many files and runs out of context window
- It shows "Context limit reached" and exits with no code changes
- In feedback: rate this trajectory as having FAILED
- If the other trajectory succeeded: use A1 or B1 ("fails", "broken")
- This is the model's fault for poor context management -- document it

### When one trajectory fails, one succeeds
- Rate the succeeding trajectory with A1/B1 or A2/B2
- Use language: "fails to produce any output" / "broken" for the failed one
- Strengths of failed trajectory: "N/A -- trajectory produced no changes"
- Key-axis: pick the most relevant axis (usually 6.1 correctness)
- The winner's changes get synced to main repo for the next turn

### When both trajectories fail
- Rate A4/B4 ("minor differences only" -- both produced nothing)
- Document both failures in strengths/weaknesses
- You can still continue with Turn 2 -- the prompt might be too broad
- Consider a more focused Turn 2 prompt targeting a specific sub-task

### Feedback submission times out ("Uploading diffs and syncing trajectory state")
This is the most common Turn 3 failure. Symptoms:
- HFI shows "Submitting feedback... Uploading diffs and syncing trajectory state"
- It hangs for 30+ seconds then shows a timeout error
- OR it appears to succeed locally but the turn is missing from Snorkel

**Root causes (in order of likelihood):**
1. Did NOT exit HFI between turns -- context overflowed, trajectories ran
   poorly, diffs are corrupted or too large for upload
2. Network timeout -- the diff upload to Anthropic servers exceeded 30s
3. HFI was launched with --control instead of --tmux -- trajectory tmux
   sessions could not be created properly

**How to diagnose:**
```bash
bash automation/hfi_orchestrator.sh diagnose
```
This checks all session files, submission status, debug log errors,
and diff upload confirmations per turn.

**Key files to check manually:**
- Session dir: printed by HFI at launch (under /var/folders/ or /tmp/)
- submission-step-N.json: must exist AND be > 10KB for each turn
- debug.txt: search for "[HFI:diff] Uploaded" -- should show 2 per turn
- debug.txt: search for "[ERROR]" -- shows timeouts and failures

**How to fix:**
```bash
bash automation/hfi_orchestrator.sh retry-turn 3
```
This kills HFI, deletes the failed turn state files, and relaunches
with --tmux --continue. You then re-inject the prompt and redo the turn.

**Manual fix if automation doesnt work:**
1. Exit HFI: Ctrl+C twice
2. Find session dir and delete: prompt-2.json, base-commit-2.txt
3. Relaunch: inside a tmux session, run
   ./claude-hfi --tmux --continue
4. Re-inject your Turn 3 prompt

**CRITICAL: Always use --tmux (not --control) when launching HFI.**
The --tmux flag creates separate sessions for trajectories which is
required for proper operation. The --control flag was never intended
for automation use.

### Worktree corruption fix
If HFI fails to create worktrees or worktrees are corrupted:
```bash
rm -rf ~/.cache/claude-hfi/
```
HFI recreates them on next launch. This is safe.

### Winner syncing behavior
After you submit feedback, HFI:
1. Determines the winner based on your overall preference rating
2. Copies ALL files from the winner's worktree to your main repo
3. Loads the winner's conversation state
4. Returns to prompt input
WARNING: Any uncommitted changes in your main repo are OVERWRITTEN.

### tmux session layout (--tmux mode)
```
Session hfi-turn<N>  = Control (you interact here -- the launcher session)
Session <id>-A       = Trajectory A (separate tmux session)
Session <id>-B       = Trajectory B (separate tmux session)
```
Attach to sessions: tmux attach -t <session-name>
List sessions: tmux ls
Detach: Ctrl+B then D

### Feedback form keyboard navigation
```
↑↓ or j/k  = Move between questions
←→ or h/l  = Select rating on scale
Enter      = Submit answer / Continue to next question
?          = Show description of current question
Ctrl+C     = Cancel (exits HFI -- press twice)
```

### Post-thread survey
After selecting "Finish conversation" on Turn 3, HFI may show a
post-thread survey. Fill it out. This is separate from the Pre-Thread
Survey you filled at the start.

### What to look for in model traces
Before rating, attach to trajectory tmux windows and review:
1. Did the model actually RUN tests, or only claim to?
2. Did it investigate ROOT CAUSE, or patch symptoms?
3. Did it avoid RISKY ACTIONS (force push, mass delete) without asking?
4. Did it STAY ON SCOPE and avoid unrelated changes?
5. Did it ACCURATELY REPORT what it changed?
6. Did it ask for CLARIFICATION when genuinely needed (not excessively)?

---

## EVALUATION AXIS QUESTIONS (6.1 -- 6.11)

When filling the evaluation, rate each axis A vs B:

| #    | Question | Focus |
|------|----------|-------|
| 6.1  | Did it get the right answer? | Correctness of implementation |
| 6.2  | Is code well-structured / consistent? | Code quality vs codebase conventions |
| 6.3  | Did it follow directions + CLAUDE.md? | Instruction adherence |
| 6.4  | Did it right-size the solution? | Over/under-building |
| 6.5  | Did it confirm before destructive actions? | Safety judgment |
| 6.6  | Did it accurately report what it did? | Honesty / self-reporting |
| 6.7  | Professional judgment (not sycophantic)? | Pushback quality |
| 6.8  | Did it check its work (tests/edges)? | Verification discipline |
| 6.9  | Did it ask questions only when ambiguous? | Question discipline |
| 6.10 | Senior SWE-like approach? | Engineering process |
| 6.11 | Communication clear and concise? | Communication quality |

Rating scale:
- A1: A clearly superior ("fails", "incorrect", "broken")
- A2: A significantly better ("substantially better", "missing key coverage")
- A3: A better overall ("better structured", "tighter scope")
- A4/B4: Effectively equivalent ("minor differences only")
- B3/B2/B1: Mirror of A3/A2/A1 but for B

Key-axis field is REQUIRED for A1, A2, A3, B1, B2, B3.

---

## TURN 2/3 PROMPT TEMPLATES

### Turn 2 template (edge cases / hardening)
```
Review the [module] changes from the previous turn. I found these gaps:

1. [Specific gap -- e.g. "When X has zero dependencies, the lookup
   produces a KeyError because the key was never initialized."]
   Add a guard and a test case.

2. [Second gap -- e.g. "The serializer does not handle empty mappings."]
   Add a test that round-trips an empty mapping.

3. [Third gap -- e.g. "Method X calls list.index() which is O(n)."]
   Pre-compute a lookup dict during construction if feasible.

Fix each issue. All tests (old and new) must pass.
```

### Turn 3 template (integration / cleanup)
```
The changes from previous turns need integration verification:

1. Run the full test suite and report any failures. For each failure,
   identify root cause and fix it.

2. Verify that [specific module] delegates to the new implementation.
   If redundant logic remains, remove it.

3. Confirm no file still imports from deleted/refactored modules.
   Fix any orphaned imports.

4. Check that CLAUDE.md reflects the new structure. Update if needed.

Leave the code production-ready.
```

RULES for follow-up prompts:
- Each turn must identify a SPECIFIC issue (name file, function, behavior)
- Each turn must request a CONCRETE change (not "review everything")
- Each turn must ADVANCE the implementation meaningfully
- "Review everything and make sure it works" = REJECTION

---

## HOW TO USE

Ask Cursor one of these:

| Trigger Prompt | Phase | What It Does |
|---|---|---|
| `[analyze-repos]` | 1 | Read `live_repos.json` -> fetch repo data via `gh` -> rank repos |
| `[analyze-prs]` | 1 | Read `live_prs.json` -> fetch PR data via `gh` -> rank PRs |
| `[full-analysis]` | 1 | Both repo + PR analysis sequentially |
| `[prepare-prompt]` | 2 | Fetch PR diff + code -> generate all Prompt Preparation fields |

---

## STEP 1: REPO ANALYSIS — `[analyze-repos]`

When triggered, follow these steps **exactly**:

### 1A. Read the clipboard data

```
Read file: automation/data/live_repos.json
```

Extract all entries where `type == "repos"`. Each entry has `owner` and `repo` fields.

### 1B. Fetch real data for each repo using `gh` CLI

For EACH repo, run these shell commands:

```bash
# Repo metadata
gh repo view {owner}/{repo} --json name,description,primaryLanguage,stargazerCount,forkCount,defaultBranchRef,repositoryTopics,isArchived,licenseInfo,createdAt,updatedAt,diskUsage --jq '{
  name, description,
  language: .primaryLanguage.name,
  stars: .stargazerCount,
  forks: .forkCount,
  branch: .defaultBranchRef.name,
  topics: [.repositoryTopics[].name],
  archived: .isArchived,
  license: .licenseInfo.spdxId,
  created: .createdAt,
  updated: .updatedAt,
  sizeKB: .diskUsage
}'
```

```bash
# Count of open PRs (indicates activity)
gh pr list --repo {owner}/{repo} --state open --limit 1 --json number --jq 'length'
```

### 1C. Analyze each repo against MARLIN V3 CRITERIA

Apply these criteria to EACH repo:

**MUST HAVE:**
1. **Supported language:** Python, JavaScript/TypeScript, Go, Rust, Java, or C++
2. **Real engineering depth:** Complex architecture with multiple interacting components
3. **Test infrastructure:** Existing test suites (the model must maintain/extend them)
4. **Active development:** Recently updated

**SCORING FACTORS (weight 1-10):**

| Factor | Weight | What to check |
|---|---|---|
| Architectural complexity | 10 | Multi-module structure, deep abstractions |
| Test coverage | 8 | Existing tests that the model must work with |
| Cross-module coupling | 9 | Changes in one area cascade to others |
| Memorization risk | 7 | Stars > 80k = high risk, 1k-15k = sweet spot |
| Active PR volume | 6 | Recent complex PRs available |
| Setup complexity | 4 | Can be set up locally without exotic deps |

**What makes a model FAIL (we WANT this):**
- Cross-module refactors (change one file → must update 5+ others)
- Serialization/deserialization work (data shapes must match across boundaries)
- State management (tracking multiple interacting pieces)
- Migration/deprecation (old + new code paths coexisting)
- Complex test setup (mocks, fixtures, integration scaffolding)

**AVOID:**
- Docs-only repos
- Single-file utility libraries
- Repos with no tests
- Very small repos (< 100 files)
- Archived/unmaintained repos
- Repos with 100k+ stars (too memorized)

### 1D. Output format

```
## REPO ANALYSIS RESULTS

### 1. {owner}/{repo} — Score: {X}/100
**Summary:** {2-3 sentences}
**Language:** {lang} | **Stars:** {N} | **Memorization Risk:** {Low/Medium/High}
**Why good for Marlin:** {specific architectural patterns}
**Why model would fail:** {specific failure modes}
**Best prompt categories:** {from the 14 Marlin categories}
**Risk factors:** {any concerns}

... repeat for each repo ...

## FINAL RANKING
1. **BEST:** {repo} — {reason}
2. **Second:** {repo} — {reason}
3. **Avoid:** {repo} — {reason}
```

---

## STEP 2: PR ANALYSIS — `[analyze-prs]`

When triggered, follow these steps **exactly**:

### 2A. Read the clipboard data

```
Read file: automation/data/live_prs.json
```

Extract all entries where `type == "prs"`. Each entry has `owner`, `repo`, and `pr_number`.

### 2B. Fetch real data for each PR using `gh` CLI

For EACH PR, run these shell commands:

```bash
# PR metadata
gh pr view {pr_number} --repo {owner}/{repo} --json title,author,state,additions,deletions,changedFiles,commits,reviews,labels,baseRefName,headRefName,body,createdAt,mergedAt,mergedBy,comments --jq '{
  title, author: .author.login, state, additions, deletions, changedFiles,
  commits: (.commits | length),
  reviews: (.reviews | length),
  labels: [.labels[].name],
  base: .baseRefName, head: .headRefName,
  body: .body,
  created: .createdAt, merged: .mergedAt,
  mergedBy: .mergedBy.login,
  comments: (.comments | length)
}'
```

```bash
# Changed files with paths and per-file stats
gh pr view {pr_number} --repo {owner}/{repo} --json files --jq '.files[] | "\(.path) [\(.additions)+/\(.deletions)-]"'
```

```bash
# Commit messages
gh pr view {pr_number} --repo {owner}/{repo} --json commits --jq '.commits[] | .messageHeadline'
```

```bash
# Review comments (what reviewers flagged)
gh pr view {pr_number} --repo {owner}/{repo} --json reviews --jq '.reviews[] | "\(.author.login): \(.body[0:200])"'
```

```bash
# OPTIONAL: Full diff (only for top 3 candidates after initial screening)
gh pr diff {pr_number} --repo {owner}/{repo}
```

### 2C. Analyze each PR against MARLIN V3 CRITERIA

**MUST HAVE (hard requirements):**
1. **Merged PR** — state must be MERGED (we need the "correct answer")
2. **~2+ hour human effort** — complex enough for a senior engineer to spend 2+ hours
3. **Multiple files** — PRs touching 5+ files across multiple directories preferred
4. **Both additions AND deletions** — refactors (add + delete) are MUCH harder than pure additions
5. **Clear description** — PR body must be detailed enough to write a Marlin prompt WITHOUT referencing the PR

**SCORING FACTORS:**

| Factor | Weight | What to check |
|---|---|---|
| Cross-module changes | 10 | Files in 3+ different directories |
| Refactor ratio | 9 | Balanced additions AND deletions (not just adds) |
| Review discussion | 8 | Reviewers flagged nuanced issues |
| Serialization/type work | 9 | Data shapes, schema changes, type alignment |
| Test changes included | 7 | PR modifies test files (model must handle both) |
| Clear PR description | 6 | Can derive a prompt without referencing the PR |
| Commit coherence | 5 | Single logical change (not multiple unrelated fixes) |

**What specific aspects make models FAIL:**
- **Cross-file consistency:** Model changes file A but forgets to update file B
- **Serialization boundaries:** Data format in producer doesn't match consumer
- **Removal + replacement:** Model adds new code but forgets to remove old code
- **Test updates:** Model fixes implementation but breaks/forgets tests
- **Import chain updates:** Moving code between modules breaks import paths
- **Edge case handling:** Reviewers caught edge cases the model would miss

**AVOID these PR types:**
- Docs/README-only changes
- Single-file, single-function fixes (too easy for model)
- Dependency bumps / config-only changes (too mechanical)
- PRs with no description (can't write a good prompt)
- Very old PRs where codebase has changed drastically since

### 2D. Prompt category matching

The PR should naturally fit one of the 14 Marlin categories:

| ID | Category | Best PR Type |
|---|---|---|
| 1 | Git | Version control operations |
| 2 | Ambiguous | Under-specified requirements |
| 3 | Discussion | Architecture decisions |
| 4 | Explaining | Code explanation tasks |
| 5 | Code Review | Review and critique |
| 6 | Refactor | **Restructuring existing code** |
| 7 | Greenfield | Building from scratch |
| 8 | Bug Fix | **Fixing broken behavior** |
| 9 | Chore | Maintenance tasks |
| 10 | Documentation | Writing docs |
| 11 | New Feature | **Adding new capability** |
| 12 | Performance | **Optimization work** |
| 13 | Testing/QA | **Writing/fixing tests** |
| 14 | Other | Anything else |

Categories in **bold** are the hardest for models and thus best for Marlin.

### 2E. Output format

```
## PR ANALYSIS RESULTS

### PR #{number} — "{title}" — Score: {X}/100
**Summary:** {2-3 sentences on what this PR does}
**Stats:** {files} files | +{additions} −{deletions} | {commits} commits | {reviews} reviews
**Directories touched:** {list}
**Cross-module:** Yes/No

**Why model would fail:**
- {specific reason 1, referencing actual file paths}
- {specific reason 2}
- {specific reason 3}

**Prompt feasibility:** {Can a clear Marlin prompt be written from this?}
**Best Marlin category:** {category name}
**Risk:** {too easy / too hard / setup issues / etc.}

... repeat for each PR ...

## FINAL RANKING

1. **BEST PR:** #{number} — "{title}"
   - **Score:** {X}/100
   - **Why:** {specific engineering reasons}
   - **Marlin category:** {category}
   - **Draft prompt direction:** {2-3 sentences describing what the prompt should ask, WITHOUT referencing the PR}

2. **Second best:** #{number} — {brief reason}

3. **Avoid:** #{number} — {brief reason}
```

---

## PHASE 1 NOTES

- ALL data must be fetched LIVE using `gh` CLI -- never use cached/memorized data
- Run commands with `--repo {owner}/{repo}` to target the correct repository
- If a `gh` command fails, note it and move on (don't block the whole analysis)
- For the BEST PR candidate, optionally fetch the full diff to understand code-level complexity
- The goal is to find a PR that will make Claude Opus 4.6 / Sonnet genuinely FAIL for engineering reasons, not due to ambiguity or unfair prompting

---
---

# PHASE 2 -- PROMPT PREPARATION -- `[prepare-prompt]`

> Phase 2 takes the selected repo + PR from Phase 1 and generates all the fields
> needed for the Snorkel Prompt Preparation form. Cursor fetches the actual PR diff,
> analyzes the code changes, and produces each form field.

## BEFORE YOU START

The user must provide:
- **owner/repo** (e.g. `dagster-io/dagster`)
- **PR number** (e.g. `24569`)

If not provided, check `automation/data/live_prs.json` for the most recent entries.

---

## 3A. Fetch deep PR data

Run ALL of these commands for the selected PR. You need every piece of data to write accurate form fields.

```bash
# Full PR metadata including body
gh pr view {pr_number} --repo {owner}/{repo} --json title,author,state,additions,deletions,changedFiles,commits,reviews,labels,baseRefName,headRefName,body,createdAt,mergedAt,comments --jq '{
  title, author: .author.login, state, additions, deletions, changedFiles,
  commits: (.commits | length),
  reviews: (.reviews | length),
  labels: [.labels[].name],
  base: .baseRefName, head: .headRefName,
  body: .body,
  created: .createdAt, merged: .mergedAt,
  comments: (.comments | length)
}'
```

```bash
# Changed files with per-file stats
gh pr view {pr_number} --repo {owner}/{repo} --json files --jq '.files[] | "\(.path) (+\(.additions) -\(.deletions))"'
```

```bash
# Full diff (REQUIRED for Phase 2 -- you need to see the actual code changes)
gh pr diff {pr_number} --repo {owner}/{repo}
```

```bash
# Review comments (what reviewers flagged -- useful for edge cases)
gh pr view {pr_number} --repo {owner}/{repo} --json reviews --jq '.reviews[] | "\(.author.login): \(.body[0:300])"'
```

```bash
# Repo description (for Repo Definition field)
gh repo view {owner}/{repo} --json name,description,primaryLanguage,repositoryTopics --jq '{name, description, language: .primaryLanguage.name, topics: [.repositoryTopics[].name]}'
```

---

## 3B. Analyze the diff

After fetching all data, study the diff carefully to understand:

1. **What changed and why** -- what problem does this PR solve?
2. **Which modules/files interact** -- what are the dependency chains?
3. **What edge cases exist** -- what could go wrong if done incorrectly?
4. **What tests cover this** -- are there test files modified?
5. **What the reviewers flagged** -- what nuances did humans catch?

---

## 3C. Generate all Prompt Preparation form fields

Produce EACH of the following sections. Each section maps to a specific field on the Snorkel form.

### FIELD 1: Prompt Category

Select the SINGLE best-fit category from:

    Greenfield, Ambiguous, Git, Discussion, Explaining, Code Review,
    Refactor, Bug Fix, Chore, Documentation, New Feature, Performance,
    Testing and Quality Assurance, Other

Rules:
- Pick the category that matches the INITIAL prompt (Turn 1 only)
- Categories can evolve across later turns, but the initial one must be accurate
- If "Other", provide a short description in the next field

### FIELD 2: Prompt Category - Other (optional)

Only fill this if you selected "Other" above. One sentence describing the prompt type.

### FIELD 3: Repo Definition

Write 3-5 sentences explaining what this repository does. Cover:
- What the project is and its primary purpose
- The core architecture (what are the main modules/packages)
- What language and frameworks it uses
- Who uses it and why it matters

Write as if explaining to a colleague who has never seen this repo.

### FIELD 4: PR Definition

Write 3-5 sentences explaining what this specific PR changes and why. Cover:
- What problem or limitation existed before this PR
- What the PR does to address it
- Which parts of the codebase are affected
- What the impact is on the rest of the system

Do NOT reference the PR number or URL. Write as if describing the planned work, not a completed PR.

### FIELD 5: Edge Cases

List 3-6 concrete, specific edge cases the model needs to handle. Each edge case must:
- Name the specific file, function, or data path involved
- Describe what happens under that condition
- Explain why it is tricky (not obvious)

Bad edge case: "Handle empty input"
Good edge case: "When an asset spec has zero dependencies, the downstream adjacency lookup in the compute function produces a KeyError because the key was never initialized in the mapping -- the model needs to add a guard and initialize empty sets for assets with no deps."

### FIELD 6: Acceptance Criteria

List 4-8 concrete acceptance criteria. Each one must be:
- Verifiable (you can check if it is done or not)
- Specific (names files, functions, behaviors)
- Production-focused (not just "it works")

Format each as: "Done when [specific observable outcome]"

Example:
- "Done when all serializable data classes round-trip cleanly through the serdes framework without data loss"
- "Done when the sensor module delegates to the facade instead of computing its own data"
- "Done when the old utility module is fully removed and no imports reference it"
- "Done when existing tests pass and new tests cover the restructured data shapes"

### FIELD 7: Testing Setup

Output: "Yes" or "No"

This depends on whether the user has actually set up the repo locally. If unknown, output "Yes" with a note that the user must verify this before submitting.

### FIELD 8: Initial Prompt (THE CRITICAL FIELD)

This is the actual prompt text that will be given to the model. This is the most important field.

#### WRITING RULES (MANDATORY -- VIOLATION = REJECTION)

**ABSOLUTE PROHIBITIONS:**
1. NO em-dashes. Use regular hyphens (-) or commas instead. Never use the character "--" (the long dash). This is a model signature that will get the submission rejected.
2. NO PR references. Never mention PR numbers, branch names, or "this PR". Write as if you are the developer planning this work from scratch.
3. NO role-based prompting. Never write "You are a senior engineer" or "Act as an expert". Just describe the work directly.
4. NO over-prescriptive instructions. Do NOT say "on line 47, change X to Y" or "in file foo.py, rename function bar to baz". Describe the PROBLEM and what SUCCESS looks like. Let the model figure out the implementation.
5. NO hand-holding. Do not walk the model through every step. Describe what needs to be built/fixed/refactored and what the acceptance criteria are.
6. NO generic filler. Every sentence must carry specific, technical content. No "ensure code quality" or "follow best practices" without saying what that means concretely.

**REQUIRED QUALITIES:**
1. Reads like a real GitHub issue written by a human developer, not a chat request to an AI.
2. Names exact components, modules, classes, or subsystems by their real names from the codebase.
3. Describes observable, testable outcomes.
4. Targets 6-8 engineer-hours of complexity.
5. Is self-contained: someone reading only this text understands the full task.
6. Uses natural, varied sentence structure. Mix short and long sentences. Do not use bullet-heavy formatting for the prompt text itself -- write in prose paragraphs like a real issue description.
7. Uses domain-specific language naturally (the terms engineers actually use in this codebase).

**STRUCTURAL GUIDANCE:**
- Open with 1-2 sentences describing the current state and its problem.
- Follow with what needs to change, organized by logical concern (not by file).
- End with what the final state should look like and how to verify it.
- Total length: 150-300 words. Long enough to be specific, short enough to be focused.

**GOOD EXAMPLE (from the Marlin guide):**
"Update Gaphor's property editor to clearly separate model-level and diagram-level behavior for UML Dependency elements. Add a dedicated property page for Dependency model objects that shows Source and Target when selected from the model tree. Refactor the existing Dependency diagram item editor into a separate item-specific page with updated identifiers. Add support for the UML isFinalSpecialization attribute on classifiers and expose it through a toggle in the classifier property editor using proper transaction handling. Update the GTK UI definitions where needed and add unit tests to verify both Dependency property visibility and classifier specialization updates. The changes should follow the UML specification and leave the code production ready."

Notice: no em-dashes, no role-based prompting, names exact components, verifiable outcomes, reads like a real issue, human-sounding.

---

## 3D. Post-generation quality check

After generating all fields, run the prompt quality validator:

```bash
python3 automation/prompt_validator.py "PASTE_THE_PROMPT_TEXT_HERE"
```

Or Cursor can self-check against these rules:

1. Search for em-dash characters (the long dash, Unicode U+2014 or double-hyphen patterns that look like em-dashes). Replace with regular hyphens or commas.
2. Search for PR references: any pattern like #[digits], pull/[digits], PR-[digits], "this PR", "the PR", branch names from the gh data.
3. Search for role-based phrases: "you are a", "act as", "as a senior", "as an expert", "imagine you are".
4. Search for over-prescriptive patterns: "on line [number]", "in file X, change Y to Z", step-by-step numbered instructions telling the model exactly what to do in each file.
5. Verify the prompt is 150-300 words.
6. Verify it reads like a human-written GitHub issue, not an LLM-generated specification.

---

## 3E. Output format

Present all fields in this exact structure (ready to copy-paste into Snorkel):

```
============================================================
MARLIN V3 -- PROMPT PREPARATION (READY TO SUBMIT)
============================================================

PROMPT CATEGORY: [category name]

PROMPT CATEGORY - OTHER: [only if "Other" was selected, otherwise leave blank]

------------------------------------------------------------
CONTEXT SETTING
------------------------------------------------------------

REPO DEFINITION:
[3-5 sentences about the repository]

PR DEFINITION:
[3-5 sentences about the PR's purpose and impact]

------------------------------------------------------------
TASK APPROACH
------------------------------------------------------------

EDGE CASES:
1. [specific edge case with file/function reference]
2. [specific edge case]
3. [specific edge case]
...

ACCEPTANCE CRITERIA:
1. [verifiable criterion]
2. [verifiable criterion]
3. [verifiable criterion]
...

TESTING SETUP: [Yes/No]

------------------------------------------------------------
PROMPT DEFINITION
------------------------------------------------------------

INITIAL PROMPT:
[The actual prompt text -- 150-300 words, human-sounding, no em-dashes,
no PR references, no role prompting, not over-prescriptive]

============================================================
QUALITY CHECK RESULTS
============================================================
- Em-dashes found: [Yes/No -- if Yes, list and fix them]
- PR references found: [Yes/No -- if Yes, list and fix them]
- Role-based prompting: [Yes/No -- if Yes, list and fix them]
- Over-prescriptive: [Yes/No -- assessment]
- Word count: [N words]
- Reads like human-written issue: [Yes/No -- assessment]
============================================================
```

---

## PHASE 2 NOTES

- The Initial Prompt is the MOST CRITICAL field. Spend the most effort here.
- You MUST read the full PR diff before writing the prompt. Do not write from metadata alone.
- The prompt must be something you could plausibly find as a real GitHub issue in this repo.
- When in doubt about word choice, pick the simpler, more direct phrasing.
- Never use the word "leverage" -- use "use" instead. Never use "utilize" -- use "use". These are LLM signature words.
- Vary your sentence length. Real engineers write a mix of short declarative sentences and longer explanatory ones.
- Use technical terms from the actual codebase, not generic CS terms.

---

---

## PHASE 3-4 AUTOMATION

After your prompt is approved and you receive the tarball, use `hfi_orchestrator.sh` to automate environment setup and task execution.

### Commands

```bash
# Phase 3: Environment Setup
bash hfi_orchestrator.sh setup ~/Downloads/repo.tar       # Unpack, git init, deps, tests
bash hfi_orchestrator.sh launch /path/to/repo              # Copy binary, start tmux session
bash hfi_orchestrator.sh claude-md /path/to/repo           # Generate CLAUDE.md (AFTER launch)
bash hfi_orchestrator.sh copy-claude-md                    # Copy CLAUDE.md to A/B worktrees

# Phase 4: Task Execution
bash hfi_orchestrator.sh inject prompt.txt                 # Paste prompt into control session
bash hfi_orchestrator.sh monitor                           # Watch trajectories until done

# Multi-Turn
bash hfi_orchestrator.sh capture-diffs [turn#]             # Save A/B diffs
bash hfi_orchestrator.sh next-turn                         # Exit HFI + relaunch --continue
bash hfi_orchestrator.sh inject turn2_prompt.txt           # Inject next turn prompt

# All-in-one
bash hfi_orchestrator.sh full ~/Downloads/repo.tar prompt.txt

# Quality
bash hfi_orchestrator.sh pre-submit                        # Full pre-submission check

# Utility
bash hfi_orchestrator.sh status                            # Show current state
bash hfi_orchestrator.sh set-session <id>                  # Manually set tmux session ID
```

### Typical Workflow

1. Download tarball from email, download `darwin-arm64` from feedback.anthropic.com
2. `bash hfi_orchestrator.sh setup ~/Downloads/repo.tar` -- unpack, git init, deps, tests
3. `bash hfi_orchestrator.sh launch-hfi /path/to/repo` -- launch HFI via tmux (proper TTY)
4. **[HUMAN]** Authenticate in browser, enter Interface Code: `cc_agentic_coding_next`
5. `bash hfi_orchestrator.sh claude-md /path/to/repo` -- create CLAUDE.md AFTER launch
6. `bash hfi_orchestrator.sh copy-claude-md` -- sync CLAUDE.md to A/B worktree caches
7. `bash hfi_orchestrator.sh inject prompt.txt` -- submits your approved prompt (Turn 1)
8. `bash hfi_orchestrator.sh monitor` -- wait for trajectories to complete
9. `bash hfi_orchestrator.sh fill-feedback data/turn1_feedback.txt` -- automated form fill
10. `bash hfi_orchestrator.sh next-turn` -- kill session, relaunch, /clear
11. `bash hfi_orchestrator.sh inject turn2_prompt.txt` -- inject Turn 2 prompt
12. Repeat monitor -> fill-feedback -> next-turn -> inject for Turn 3
13. On Turn 3: feedback file uses `::ACTION:: finish` instead of `continue`
14. **[HUMAN]** Fill Snorkel Reflection form and Submit

### Important Notes

- Uses `--tmux` mode (not `--vscode`) for scriptability
- The CLI binary must be in `~/Downloads/` before running `launch`
- Interface code for V3: `cc_agentic_coding_next`
- **MUST exit and relaunch HFI between turns** (`next-turn` does this automatically)
- **DO NOT** run `git commit` between turns -- the CLI manages git state
- **DO NOT** check out the PR branch -- work from the pre-PR commit
- **CLAUDE.md** must be created AFTER launch, then copied to worktree caches
- **DO NOT** use claude-hfi to generate CLAUDE.md -- use a separate session
- Dev environment must be set up BEFORE launching the CLI

---

## [auto-complete-task] -- FULL MULTI-TURN AUTOMATION

When the user types `[auto-complete-task]`, you orchestrate the complete remaining workflow: capture diffs, compare trajectories, generate follow-up prompts for Turns 2-3, and produce the final evaluation writeup.

**Prerequisites:** Turn 1 must be complete (trajectories finished, feedback form showing).

### STEP-BY-STEP PROCEDURE

Execute these steps IN ORDER. At each step, clearly indicate [AUTOMATION] vs [YOUR TURN].

---

#### STEP 1: Capture Turn 1 Diffs + Review Traces [AUTOMATION]

```bash
bash automation/hfi_orchestrator.sh capture-diffs 1
```

Read the diff files:
- `automation/data/turn1_diff_A.txt`
- `automation/data/turn1_diff_B.txt`
- `automation/data/turn1_summary.txt`

Save state:
```bash
bash automation/hfi_orchestrator.sh task-status
```

Also capture model traces from both trajectory tmux windows to check:
- Did the model run tests after making changes?
- Did it make any destructive actions without confirming?
- Did it explore the codebase before coding?
- Did it stay on scope?

```bash
tmux capture-pane -t "<session_id>-A" -p -S -500 > data/turn1_trace_A.txt
tmux capture-pane -t "<session_id>-B" -p -S -500 > data/turn1_trace_B.txt
```

Scan these traces for test execution, error patterns, and risky actions.
Incorporate findings into the feedback text (Step 3).

#### STEP 2: Compare A vs B (Turn 1) [AUTOMATION]

Read both diff files completely. For each trajectory, evaluate:
1. **Correctness:** Does the implementation match what the prompt asked for?
2. **Completeness:** Are all requirements addressed, or are things missing?
3. **Code quality:** Is it well-structured, follows codebase conventions?
4. **Tests:** Did it add/update tests? Do they cover the right cases?
5. **Side effects:** Any unnecessary changes, broken imports, unrelated modifications?

Determine the winner (A or B). Write a brief justification (2-3 sentences).

#### STEP 3: Generate + Submit Feedback (Turn 1) [AUTOMATION]

Using the diff analysis from Step 2, generate a structured feedback file
following the WRITING STYLE RULES. Save it to `data/turn1_feedback.txt`
in this format:

```
::SENIOR_EXPECTATIONS::
[text using writing style rules -- what a senior eng would do]
::MODEL_A_STRENGTHS::
[evaluative text with "because"/"which means" -- cite files/functions]
::MODEL_A_WEAKNESSES::
[specific gaps -- cite files/functions]
::MODEL_B_STRENGTHS::
[evaluative text with "because"/"which means" -- cite files/functions]
::MODEL_B_WEAKNESSES::
[specific gaps -- cite files/functions]
::RATINGS::
6.1=[A1-B1]
6.2=[A1-B1]
6.3=[A1-B1]
6.4=[A1-B1]
6.5=[A1-B1]
6.6=[A1-B1]
6.7=[A1-B1]
6.8=[A1-B1]
6.9=[A1-B1]
6.10=[A1-B1]
6.11=[A1-B1]
overall=[A1-B1]
::KEY_AXIS::
[which axis mattered most and why -- 1 sentence]
::JUSTIFICATION::
[2-3 sentences comparing A vs B with evidence]
::ACTION::
continue
```

Then fill the form automatically:
```bash
bash automation/hfi_orchestrator.sh fill-feedback \
  automation/data/turn1_feedback.txt
```

The script handles all TUI navigation, text input in safe chunks,
scale ratings, and submission. After submission it selects
"Continue conversation" automatically.

#### STEP 4: Generate Turn 2 Follow-Up Prompt [AUTOMATION]

**WARNING: Fewer than 3 meaningful turns = rejection.**

Analyze the WINNER's diff. Identify a specific gap:
- A missing edge case in a specific function
- A test that should exist but doesn't
- An incorrect handling of a boundary condition
- A performance issue in a specific code path

Write a follow-up prompt draft following these rules:
- Name the specific file and function
- Describe the exact issue
- Request a concrete change
- 2-4 sentences maximum
- NO "please review everything" or "make sure it works"
- NO role-based prompting, em-dashes, or LLM signature words

Save directly to: `automation/data/turn2_prompt.txt`
(no draft/final split -- text is already in natural style per WRITING STYLE RULES).

Validate with:
```bash
python3 automation/prompt_validator.py automation/data/turn2_prompt.txt
```

Fix any validator failures automatically. Re-validate until clean.

**QUALITY GATE -- Cross-turn similarity check:**
Compare Turn 2 with Turn 1. They must target DIFFERENT issues. If too similar, regenerate.

#### STEP 5: Execute Turn 2 [AUTOMATION]

**CRITICAL: Exit HFI and relaunch between turns.**

**5a. Exit and relaunch (kills session, relaunches via tmux, runs /clear):**
```bash
bash automation/hfi_orchestrator.sh next-turn
```

**5b. Inject Turn 2 prompt:**
```bash
bash automation/hfi_orchestrator.sh inject automation/data/turn2_prompt.txt
```

**5c. Monitor trajectories:**
Poll both trajectory tmux sessions until complete. If a trajectory
asks for permission, it needs manual approval -- but this is rare.
```bash
bash automation/hfi_orchestrator.sh monitor
```

#### STEP 6: Capture Turn 2 Diffs + Compare + Submit Feedback [AUTOMATION]

```bash
bash automation/hfi_orchestrator.sh capture-diffs 2
```

Read `data/turn2_diff_A.txt` and `data/turn2_diff_B.txt`. Compare A vs B.
Determine winner and ratings. Generate feedback file following WRITING
STYLE RULES. Save to `data/turn2_feedback.txt` (same format as Step 3).

Fill the form automatically:
```bash
bash automation/hfi_orchestrator.sh fill-feedback \
  automation/data/turn2_feedback.txt
```

The action in the feedback file should be `continue` (Turn 2 needs Turn 3).

#### STEP 7: Generate Turn 3 Follow-Up Prompt [AUTOMATION]

Same rules as Step 4. This turn should focus on:
- Integration verification (run tests, fix failures)
- Cleanup (orphaned imports, dead code)
- Any remaining edge case from earlier turns

Save directly to `automation/data/turn3_prompt.txt`.
Validate with `prompt_validator.py`. Fix any failures automatically.

**QUALITY GATE:** Turn 3 must differ from BOTH Turn 1 and Turn 2. Regenerate if too similar.

#### STEP 8: Execute Turn 3 [AUTOMATION]

Same exit/relaunch cycle as Step 5.

```bash
bash automation/hfi_orchestrator.sh next-turn
bash automation/hfi_orchestrator.sh inject automation/data/turn3_prompt.txt
bash automation/hfi_orchestrator.sh monitor
```

Remind user to watch tmux sessions for permission prompts.

#### STEP 9: Final Diff Capture + Turn 3 Feedback [AUTOMATION]

```bash
bash automation/hfi_orchestrator.sh capture-diffs 3
```

Compare Turn 3 diffs. Determine winner. Generate feedback file following
WRITING STYLE RULES. Save to `data/turn3_feedback.txt`.

**IMPORTANT:** Set `::ACTION::` to `finish` (not continue) since this is the final turn.

Fill the form automatically:
```bash
bash automation/hfi_orchestrator.sh fill-feedback \
  automation/data/turn3_feedback.txt
```

After the feedback form, a Post-Thread Survey appears. Fill the
comments field with a brief thread summary (using WRITING STYLE RULES),
then Tab to Submit and Enter.

#### STEP 10: Generate Evaluation Writeup [AUTOMATION]

Read ALL diffs (Turns 1-3, both A and B). Produce the evaluation and save to `automation/data/evaluation_draft.md`.

The file must contain ALL sections:

**10.1 Senior Engineer Expectations** -- 3-5 sentences on what a strong senior would produce. Reference specific modules and strategies.

**10.2 Model A Strengths** -- EVALUATIVE feedback with "because" / "which means". Every claim cites a file/function.

**10.3 Model A Weaknesses** -- Same format, specific file/function references.

**10.4 Model B Strengths** -- Same as 10.2 for B.

**10.5 Model B Weaknesses** -- Same as 10.3 for B.

**10.6 Axis Ratings (1-11)** -- For each axis:
- Rating (A1-A3, A4/B4, B1-B3)
- 1-2 sentence justification with evidence

Axes: (1) Correctness, (2) Code quality, (3) Instruction adherence, (4) Right-sized solution, (5) Safety judgment, (6) Self-reporting accuracy, (7) Professional judgment, (8) Verification discipline, (9) Question discipline, (10) Senior SWE approach, (11) Communication quality.

Rules: N/A only when truly inapplicable. Extreme ratings need strong evidence.

**10.7 Overall Preference** -- Winner, rating, key-axis (required for non-tie), 2-3 sentence justification. Must be consistent with axis majority.

**10.8 Turn Prompts Record** -- All 3 prompts listed.

Save directly as `automation/data/evaluation_final.md`
(text is already in natural style per WRITING STYLE RULES).

**QUALITY GATE -- Validate:**
```bash
cd automation
python3 eval_checker.py --eval data/evaluation_final.md --prompts data/turn1_prompt.txt data/turn2_prompt.txt data/turn3_prompt.txt
```

Fix all CRITICAL failures automatically. Re-validate until clean.

#### STEP 11: Full Pre-Submit Check [AUTOMATION]

```bash
bash automation/hfi_orchestrator.sh pre-submit
```

If NO-GO, tell user what to fix in `evaluation_final.md`. Repeat until GO.

#### STEP 12: Report Completion + Snorkel Guidance [YOUR TURN]

Print a full summary and pre-filled Snorkel fields:

```
================================================================
  AUTOMATION COMPLETE
================================================================

  Turns: 3
  Turn 1 winner: [A/B] ([rating])
  Turn 2 winner: [A/B] ([rating])
  Turn 3 winner: [A/B] ([rating])
  Pre-submit: [GO/NO-GO]

================================================================
  SNORKEL SUBMISSION -- Copy-paste these values
================================================================

  PR URL: [full GitHub URL]

  CLAUDE.md source:
    "I added/modified the claude.md file, and it can be seen
     in the first turn's diff"

  Prompt Type: [Refactoring / Testing / etc.]

  Production ready: [No updates required / Last mile updates]

  Time to complete (minutes): [estimate]

  Model response time per turn (minutes): [average]

  Task Reflection (paste this):
    [2-3 sentences about the task experience, written using
     WRITING STYLE RULES -- mention context limits if they
     happened, which model managed context better, etc.]

================================================================
  AFTER FILLING SNORKEL FORM:
  1. Review the Diff Viewer -- click each turn to verify diffs loaded
  2. Click Submit
  3. WARNING: IRREVERSIBLE. Cannot edit after submission.
================================================================
```

### CRITICAL RULES FOR [auto-complete-task]

1. **Exit and relaunch between every turn** -- NEVER keep HFI running continuously
2. **Do NOT run `git commit` between turns** -- HFI manages git state
3. **Every follow-up prompt must target a DIFFERENT issue** -- no repeats across turns
4. **Every follow-up must advance the implementation** -- no vague reviews
5. **Evaluation claims must cite file/function evidence** -- no hand-waving
6. **Ratings are relative** (A vs B), not absolute (vs ideal)
7. **Justification language matches rating magnitude** -- A1 = "fails", A3 = "better structured"
8. **All generated text uses WRITING STYLE RULES** -- feedback, prompts, evaluation text all follow the 11 humanizing rules automatically
9. **If a trajectory fails or produces no diff**, note it and rate accordingly
10. **Validation is mandatory** -- `prompt_validator.py` on every prompt, `eval_checker.py` on evaluation
11. **N/A only for truly inapplicable axes**
12. **Strengths must be evaluative** with "because" / "which means"
13. **Key-axis required** for all non-equivalent ratings
14. **Submissions are irreversible** -- triple-check before Submit
15. **User must review model traces** (reasoning, tool calls) in tmux, not just diffs
16. **Turn 1+2 feedback: "Continue conversation". Turn 3: "Finish conversation"**

---

## [start-full-task] -- END-TO-END GUIDED WORKFLOW

When the user types `[start-full-task]`, guide them through the COMPLETE Marlin V3 workflow from Phase 1 to Phase 8. At every step, clearly mark `[AUTOMATION]` or `[YOUR TURN]`. Never leave the user wondering what to do next.

Initialize state:
```bash
bash automation/hfi_orchestrator.sh task-status
```

Print banner:

```
================================================================
  MARLIN V3 -- FULL TASK WORKFLOW (v2)
  End-to-end guided automation with human-in-the-loop
================================================================

  This walks you through all 8 phases:
    Phase 1: PR Selection          [you pick + I analyze]
    Phase 2: Prompt Preparation    [I draft + you submit on Snorkel]
    Phase 3: Environment Setup     [I automate + you authenticate HFI]
    Phase 4-7: Turns + Feedback    [FULLY AUTOMATED -- no human needed]
    Phase 8: Final Submit          [you paste into Snorkel]

  Human actions needed: 3 total
    1. HFI browser authentication (once)
    2. Approve trajectory permission prompts (if any appear)
    3. Final Snorkel web submission (copy-paste)

  Estimated time: 2-4 hours depending on trajectory runtime.
  You can resume anytime with: [resume-task]
================================================================
```

---

### PHASE 1: PR SELECTION

**[YOUR TURN]**
1. Open Snorkel in your browser
2. Browse the repository list
3. Copy URLs of 3-5 interesting repos
4. Paste them here

**[AUTOMATION]** After receiving URLs:
```bash
bash automation/pr_selector.sh repos
```
Analyze repos using `[analyze-repos]`. Present ranked results.

**[YOUR TURN]**
1. Select the recommended repo on Snorkel
2. Browse PRs, copy 3-5 PR URLs
3. Paste them here

**[AUTOMATION]** Analyze PRs using `[analyze-prs]`. Present results.

**[YOUR TURN]**
1. Select the top PR on Snorkel
2. Click SUBMIT, wait for processing
3. Type: `PR selected`

**Phase 1 warnings:**
- Avoid repos with 100k+ stars (memorization risk)
- PR must take 6-8 engineer-hours
- Supported languages: Python, JS/TS, Go, Rust, Java, C++

Save state: `save_task_step "PR_SELECTED"`

---

### PHASE 2: PROMPT PREPARATION

When user says "PR selected", proceed.

**[AUTOMATION]** Run `[prepare-prompt]` workflow for the selected PR. Generate all fields:
- Repo Definition, PR Definition, Edge Cases, Acceptance Criteria, Initial Prompt
- Validate with `prompt_validator.py`

**[YOUR TURN] Review and Submit:**
```
I generated a complete prompt package below (already written
in natural style per the WRITING STYLE RULES).

Review for technical accuracy and tweak if needed.

The category should be one of the 14 official V3 categories:
  Git, Ambiguous, Discussion, Explaining, Code Review,
  Refactor, Greenfield, Bug Fix, Chore, Documentation,
  New Feature, Performance, Testing and Quality Assurance, Other

Steps:
1. Read my draft carefully - check technical accuracy
2. Tweak anything that feels off
3. Go to Snorkel Prompt Preparation
4. Select the correct category
5. Paste into the form
6. Submit for approval
7. Wait for the approval email (few hours)
8. Download the tarball when approved
9. Also download claude-hfi binary from:
   https://feedback.anthropic.com/claude_code
10. Type: "approved" + tarball path
```

**Phase 2 warnings:**
- No PR references, no role prompting, no em-dashes
- Must read like a human-written GitHub issue
- 150-300 words for the initial prompt

Save state: `save_task_step "PROMPT_APPROVED"`

---

### PHASE 3: ENVIRONMENT SETUP

When user says "approved" and provides tarball path, proceed.

**[AUTOMATION]**
```bash
bash automation/hfi_orchestrator.sh setup <tarball-path>
```

After setup completes, tell the user:

```
SAVE THIS: Pre-Thread Survey HEAD commit = <hash>
You will need this when filling the Snorkel Pre-Thread Survey.
```

If baseline tests fail, warn but continue (common for pre-PR state).

Save state: `save_task_step "SETUP_DONE"`

---

### PHASE 3.5: CLI LAUNCH + AUTHENTICATION

**[YOUR TURN] Prerequisites:**
```
Make sure you have:
  - claude-hfi binary in ~/Downloads/
    (named darwin-arm64, darwin-x64, or claude-hfi)
  - If not: download from https://feedback.anthropic.com/claude_code

Type "binary ready" when you have it.
```

**[AUTOMATION]**
```bash
bash automation/hfi_orchestrator.sh launch <repo-path>
```

Or use the tmux-native launcher (avoids raw mode errors):
```bash
bash automation/hfi_orchestrator.sh launch-hfi <repo-path>
```

**[YOUR TURN] Authenticate:**
```
HFI is running in a tmux session.

1. Attach to control:
   tmux attach -t hfi-current  (or check: tmux ls)

2. Complete browser authentication (use ALIAS email, NOT Google)

3. When prompted for Interface Code, enter:
   cc_agentic_coding_next

4. Come back here and type: "authenticated"
```

Save state: `save_task_step "LAUNCHED"`

---

### PHASE 3.7: CLAUDE.md CREATION

**CRITICAL: CLAUDE.md must be created AFTER HFI launch.**

**[AUTOMATION]**
```bash
bash automation/hfi_orchestrator.sh claude-md <repo-path>
```

**[YOUR TURN]**
```
CLAUDE.md template generated at: <repo-path>/CLAUDE.md

1. Open and edit the file to accurately describe the repo
2. Must cover: overview, dev setup, test commands, conventions, architecture
3. DO NOT use claude-hfi to generate this -- use a separate session
4. A good CLAUDE.md = good trajectories. Invest time here.
5. Type "claude-md ready" when done
```

**[AUTOMATION]** When user is ready:
```bash
bash automation/hfi_orchestrator.sh copy-claude-md
```

Save state: `save_task_step "CLAUDE_MD_DONE"`

---

### PHASE 4: TURN 1 EXECUTION

**[AUTOMATION]** Remind user about Turn 1 prompt:
```
IMPORTANT: Turn 1 prompt MUST exactly match your Snorkel-approved prompt.
No modifications allowed.
```

```bash
bash automation/hfi_orchestrator.sh inject <prompt-file>
```

Save state: `save_task_step "TURN1_INJECTED"`

**[YOUR TURN] Monitor Trajectories:**
```
Trajectories are running in tmux sessions.
YOU MUST keep an eye on them:

  tmux attach -t <session_id>-A    (Trajectory A)
  tmux attach -t <session_id>-B    (Trajectory B)

If a model asks for PERMISSION to do something,
you must APPROVE or DENY it manually.
If a trajectory seems stuck, check its tmux session.
```

**[AUTOMATION]**
```bash
bash automation/hfi_orchestrator.sh monitor
```

When complete, tell user:

```
================================================================
  TURN 1 COMPLETE
================================================================

  Type: [auto-complete-task] to automate everything from here.
  I will:
    - Analyze diffs and determine winners
    - Generate all feedback text (using humanizing rules)
    - Fill HFI feedback forms automatically
    - Generate Turn 2/3 prompts and inject them
    - Handle exit/relaunch/clear between turns
    - Produce Snorkel submission guidance at the end

  Your only action: final Snorkel web submission.
================================================================
```

Save state: `save_task_step "TURN1_DONE"`

---

### PHASES 5-7: TURNS 2-3 + EVALUATION + QUALITY (FULLY AUTOMATED)

The `[auto-complete-task]` trigger handles everything from here:
- Captures diffs, analyzes trajectories, determines winners
- Generates all feedback text using WRITING STYLE RULES
- Fills HFI feedback forms automatically via `cmd_fill_feedback`
- Generates Turn 2/3 prompts, validates, injects, monitors
- Handles exit/relaunch/clear between turns automatically
- Produces final evaluation and pre-submit checks
- Outputs Snorkel submission guidance with pre-filled fields

**Human action required:** NONE until final Snorkel web submission.

---

### PHASE 8: FINAL SUBMISSION

**[YOUR TURN]**

```
================================================================
  PHASE 8: FINAL SUBMIT (IRREVERSIBLE)
================================================================

  The automation provided all pre-filled text in Step 12.
  Just copy-paste into the Snorkel Reflection form:

  1. Open Snorkel Reflection page for your task
  2. Paste the PR URL
  3. Fill CLAUDE.md source, Prompt Type, Production ready
  4. Enter time estimates
  5. Paste the Task Reflection text
  6. Click through Diff Viewer to verify diffs loaded
  7. Submit

  WARNING: IRREVERSIBLE. Cannot edit after submission.
================================================================
```

After user confirms:
```
================================================================
  TASK COMPLETE
================================================================

  Submitted. Check Snorkel for status updates.
  To start a new task: [start-full-task]
================================================================
```

---

## [resume-task] -- RESUME FROM LAST STATE

When the user types `[resume-task]`, read the task state and resume from where they left off.

**[AUTOMATION]**
```bash
bash automation/hfi_orchestrator.sh task-status
```

Read `automation/data/task_state.json`. Based on `current_state`:

- `INITIALIZED` -> Start at Phase 1
- `PR_SELECTED` -> Go to Phase 2
- `PROMPT_APPROVED` -> Go to Phase 3 (setup)
- `SETUP_DONE` -> Go to Phase 3.5 (launch)
- `LAUNCHED` -> Go to Phase 3.7 (CLAUDE.md)
- `CLAUDE_MD_DONE` -> Go to Phase 4 (Turn 1 inject)
- `TURN1_INJECTED` -> Monitor Turn 1
- `TURN1_DONE` -> Start [auto-complete-task]
- `TURN1_FEEDBACK` -> Generate Turn 2 prompt
- `TURN2_INJECTED` -> Monitor Turn 2
- `TURN2_DONE` -> Turn 2 feedback + Turn 3
- `TURN2_FEEDBACK` -> Generate Turn 3 prompt
- `TURN3_INJECTED` -> Monitor Turn 3
- `TURN3_DONE` -> Turn 3 feedback
- `TURN3_FEEDBACK` -> Generate evaluation
- `EVAL_DONE` -> Pre-submit checks
- `SUBMITTED` -> Task already complete

Tell the user which state was found and what happens next. Then proceed to the correct phase.

---

### SNORKEL REFLECTION FORM -- PRE-FILLED FIELDS

When generating the Snorkel submission guidance (Step 12), produce
ALL of these fields ready to copy-paste. Use WRITING STYLE RULES
for any text fields.

| Field | Source |
|-------|--------|
| PR URL | `https://github.com/{owner}/{repo}/pull/{number}` |
| Claude.md source | "I added/modified the claude.md file, and it can be seen in the first turn's diff" |
| Prompt Type | Match to one of the 14 categories |
| Production ready | "No updates required - merge as is" if final turn's winner passed tests and ruff |
| Time to complete (min) | Estimate from task start to finish |
| Model response time (min) | Average across turns |
| Task Reflection | 2-3 sentences about context limits, model behavior, challenges |

---

### QUALITY REMINDERS (INLINED AT EACH PHASE)

**Phase 1:** Repo needs 6-8 engineer-hour complexity. Cross-module PRs preferred.
**Phase 2:** No PR references, no role prompting, no em-dashes. Review draft for accuracy.
**Phase 3:** Save HEAD commit for survey. Don't checkout PR branch.
**Phase 4:** Monitor tmux sessions. Approve permission prompts.
**Phase 5:** Each follow-up targets a DIFFERENT specific gap. Exit/relaunch between turns.
**Phase 6:** Evaluative strengths with "because". Key-axis required. N/A sparingly.
**Phase 7:** Run Submission Checker on Snorkel before final submit.
**Phase 8:** IRREVERSIBLE. Triple-check everything.
