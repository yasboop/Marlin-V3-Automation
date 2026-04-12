# MARLIN V3 — CURSOR-NATIVE AUTOMATION (FULL WORKFLOW)

> Operational playbook for ALL Marlin V3 phases (1-8).
> For the complete reference of official rules, see `docs/reference/marlin_v3_guide.md`.
> This playbook adds automation commands, grounding rules, scenario handbook, and Cursor-native workflows on top of the official rules.
> Python is used only for clipboard capture and prompt validation. All GitHub data fetching and analysis is done by Cursor via `gh` CLI.

---

## START HERE

**If you are new to Marlin V3**, read these sections in order before starting a task:

1. **Marlin V3 Rules** (next section) - the hard rules. Violating any of these = task rejection or program removal. Skim the full list, focus on "Program-Level Rules" and "LLM Detection Signals"
2. **Prompt Strategy** - the divergence-completion principle and 3-Turn Funnel. This determines how your prompts should be structured
3. **Writing Style Rules** - how to humanize all text you generate. Reference `docs/HUMANIZER_PROMPT.md` for the full rephrase approach
4. **Scenario Handbook** - what to do when things go wrong (identical outputs, one model fails, etc.)

**When you are ready to start a task**, jump to the **END-TO-END GUIDED WORKFLOW** at the bottom of this file. It walks you through all 8 phases with clear human/automation checkpoints.

**Key checklists** (use these at the point of output, not before):
- **PROMPT PREPARATION CHECKLIST** (after section 3E) - run before/after writing all prompt prep fields
- **TURN 2/3 PROMPT CHECKLIST** (after Turn 2/3 templates) - run before writing follow-up prompts
- **FEEDBACK GENERATION CHECKLIST** (in FULL MULTI-TURN AUTOMATION) - run before/after writing feedback files

**Quick navigation:**

| Section | What it covers | Line |
|---------|---------------|------|
| Rules | Hard rules, LLM detection, grounding | Top |
| Prompt Strategy | 3-Turn Funnel, divergence principle | After rules |
| Scenario Handbook | Edge cases, troubleshooting, category guidance | After strategy |
| Phase 2 - Prompt Prep | How to fill Snorkel fields | Middle |
| Phase 3-4 Automation | Orchestrator commands, workflow cheat sheets | After Phase 2 |
| Full Multi-Turn Automation | Detailed post-Turn-1 procedure | After cheat sheets |
| End-to-End Guided Workflow | Complete Phase 1-8 for new tasks | Bottom |

---

## MARLIN V3 RULES (CONSOLIDATED FROM ALL DOCS)

These rules are extracted from all official training documentation. Violations of any = task rejection.

### Program-Level Rules (violation = removal from program)
- **DO NOT push work to public repositories.** All work must remain private. This applies to ALL task types including Greenfield. Violations may result in removal from the program.
- **DO NOT use external LLMs or AI tools** outside the provided platform to analyze code, write prompts, review outputs, or draft explanations. Submissions showing signs of heavy or direct LLM usage may be rejected.
- **Dispute process:** V3 disputes go to Marlin-Submission-Disputes-V3 in Linear. 2-Dispute Denial Limit goes into effect April 11, 2026. After that date, if 2 disputes are denied, further consequences apply. The dispute form includes a version toggle so reviewers know which guidelines version was used.

### Prompt Rules
- NO em-dashes (Unicode U+2014) and NO double-hyphens ("--") in any generated text. Use commas, periods, or single hyphens instead. Both are LLM signatures.
- NO PR references (#number, pull/number, "this PR", branch names).
- NO role-based prompting ("You are a senior engineer", "Act as an expert").
- NO over-prescriptive instructions ("on line 47, change X to Y").
- NO LLM signature words: leverage, utilize, delve, comprehensive, robust, streamline, facilitate, encompass, pivotal, intricate, nuanced, paradigm.
- Word count: 80-200 words for initial prompt. Shorter is better for divergence. (Note: official PDFs specify "6-8 engineer-hours of complexity" without a word count. This is our custom guideline.)
- Must read like a human-written GitHub issue, not an AI spec.
- **Phased implementation:** The initial prompt is NOT required to include the full scope. Core logic in Turn 1, remaining related functionality (edge cases, tests, secondary features) in later turns is acceptable, as long as each turn advances the implementation concretely.
- **Verifiable prompts:** Strongly encouraged but not mandatory. If open-ended, the acceptance criteria field must explicitly describe expected behaviour, signals for judging correctness, and what counts as incomplete. Open-ended does NOT mean lazy -- reviewers closely check the "What is the ideal response?" field.
- Turn 1 prompt MUST exactly match the Snorkel-approved prompt. No modifications.
- **Purpose of the PR in writing your prompt:** The PR exists for three reasons: (1) creativity hurdle -- helps get past the challenge of coming up with a unique prompt, (2) prompt diversity -- keeps prompts varied, (3) historical repo state -- allows working off a historical state of a repo. Your prompt scope does not have to match the PR scope exactly. You are encouraged to veer away from it.

### Multi-Turn Rules
- Minimum 3 meaningful turns required. Non-meaningful follow-ups = rejection.
- DO NOT run `git commit` between turns. HFI manages git state.
- Each follow-up must target a DIFFERENT specific file/function gap.
- Never ask to "review everything" or "check for bugs" -- too vague.
- After Turn 1 & 2 feedback: select "Continue conversation".
- After Turn 3 feedback: select "Finish conversation".
- If both trajectories produce identical/near-identical output, lean towards one model. Do not rate A4/B4 just because output is similar -- pick the one with better trace behavior (test execution, scope discipline, communication).

### Grounding Rules (CRITICAL -- violations caused task rejection)
- **Every factual claim in feedback MUST be verifiable in the saved diff files.** Before writing "Model B removed X from Y", confirm X and Y actually appear in Model B's diff.
- **Cross-model verification:** Before claiming something is UNIQUE to one model, check the other model's diff for the same change. Both models often make similar changes.
- **Scope deviation detection:** Flag any files changed by a trajectory that are NOT related to the prompt's scope. Submodule pointer changes (e.g. library/backtrace, library/stdarch) are a common source of out-of-scope noise.
- **Evidence grounding:** Never cite specific test files, line numbers, or compilation errors in feedback unless they are directly visible in the diff or trace output. Do not relay model claims without verifying them.
- **Trace-vs-diff reconciliation:** If a model's trace says "I ran tests and they pass", verify the trace output actually shows test execution. If a model says "I changed function X", verify X appears in the diff.
- **Pre-submission diff audit:** Before submitting any feedback, re-read the relevant diff sections for every claim in your feedback text. If a claim cannot be traced to a specific diff hunk, remove or rewrite it.

### CLAUDE.md Rules
- Create AFTER the initial commit but BEFORE launching HFI (`touch CLAUDE.md`, edit contents, then launch).
- DO NOT use claude-hfi to generate CLAUDE.md.
- Since CLAUDE.md exists in the repo before HFI starts, both trajectories automatically see it. No manual copy to worktree caches needed.
- A bad CLAUDE.md leads to bad trajectories.
- **GITIGNORE CHECK:** If CLAUDE.md doesnt appear in the trajectory VSCode/tmux windows, check if the repo has a `.gitignore` entry for CLAUDE.md. If so: remove the CLAUDE.md file, remove the .gitignore entry, do another commit, re-create CLAUDE.md, then relaunch HFI.
- **CLAUDE_ENV_FILE:** If the project uses conda/virtualenv/nvm, create an env activation script and `export CLAUDE_ENV_FILE=./env-setup.sh` before launching HFI. This ensures both trajectories have the correct environment.

### Feedback Form Rules
- V3 (April 2026): Per-turn fields are now **Solution Quality**, **Agency**, and **Communication** for each model. The old Strengths/Weaknesses format is retired.
  - **Solution Quality**: correctness, code quality, edge cases, tests. For Discussion/Ambiguous/Code Review: quality of reasoning. Maps to SxS 5.1, 5.2, 5.3, 5.4, 5.8.
  - **Agency**: independent agent behavior -- risky actions, judgment, clarification seeking. Must cite transcript evidence. Maps to SxS 5.5, 5.7, 5.9.
  - **Communication**: clarity, honesty about what it did/didnt do, documentation. Maps to SxS 5.6.
- All fields must be EVALUATIVE, not descriptive. Use "because" / "which means" to explain impact.
  - **Weak (descriptive):** "Model A added tests"
  - **Strong (evaluative):** "Model A added regression coverage for the non-ASCII query path. Without this test, a future refactor could silently reintroduce the bug." (Only cite specific filenames if they appear in the diff.)
- **Evaluate each model independently** in the per-model fields (Solution Quality, Agency, Communication). Focus on what that model did on its own. Save all A-vs-B comparison for the overall preference justification and key-axis field.
- **Build observations while reviewing**, not after. Take notes as you go through diffs and traces. Do not review both trajectories and then try to remember what you saw.
- **Only note observations relevant to the rated axes.** Do not pad fields with irrelevant things like response time or number of tool calls. Every observation should map to one of the 11 axes or the Solution Quality/Agency/Communication fields.
- **Overall justification must be self-contained.** Assume the reader has no access to your per-model fields. Resurface the key points that drove the preference. Do not say "as mentioned above" -- restate the evidence.
- Always use the exact terms **"Model A"** and **"Model B"**. Not "the first model", "one of them", "the other one", or "it".
- **Write feedback externally, paste into the CLI.** Writing directly in the tmux feedback form leads to rushed, thin feedback. Write in a text editor first, then paste into the HFI form. Slow down.
- **Magnitude shifts with scrutiny.** What looks like "model failed completely" at first glance might be a minor issue when you read the code (correct implementation but spawned at wrong coordinates). What looks like "73 great test cases" might be garbage when you check what they actually test. Always go deeper than the surface before rating.
- **Write the evidence directly, not vague labels.**
  - **Bad:** "Model B has better error handling and more robust edge case coverage."
  - **Good:** "Model B wraps the getQuote and addPromoCode calls in try/catch with distinct error messages that use the logger. Model A adds try/catch but does not parse the error object from the upstream 200 response."
- **Check HOW, not just WHAT.** If both models ran the linter, check how each ran it. One might have used the wrong command, applied autofixing that created undesirable extra changes, or added comments documenting turn-level changes that a real contributor would not write. The difference between a lazy and thorough evaluation is whether you actually opened the diff.
- NEVER use N/A for any axis or feedback field. Always provide a substantive answer even if one trajectory failed completely.
- Key-axis REQUIRED for all non-equivalent ratings (A1-A3, B1-B3).
- Key-axis field MUST use the axis NAME (e.g. "Correctness", "Code quality"), NEVER raw numbers (e.g. "6.1", "6.2"). Raw numbers signal template usage and trigger rejection.
- **Key-axis calibration**: do NOT default to correctness. Pick the axis that actually decided the preference. If scope control, testing discipline, or self-reporting honesty was the real driver, use that.
- Extreme ratings (A1/B1) require strong evidence ("fails", "broken", "incorrect").
- DO NOT use blanket extreme ratings (all 11 axes the same). If the "losing" trajectory completed partial work, some axes MUST reflect that work (use A3/B3 or A4/B4 on those axes).
- Overall preference must be consistent with axis ratings majority.
- Rating language: A1/B1 = "fails/broken", A2/B2 = "substantially better", A3/B3 = "better structured", A4/B4 = "minor differences only".

### Submission Rules
- Submissions are IRREVERSIBLE. Cannot edit after clicking Submit.
- Run Snorkel Submission Checker before final submit (see details below).
- Review model traces (reasoning, tool calls) in tmux sessions, not just code diffs.
- Pre-Thread Survey HEAD commit = the base repository commit from `git init && git add . && git commit` on the pre-PR tarball. This is the code BEFORE the PR changes, NOT the commit at the tip of the PR branch.
- If you see unexpectedly large diffs touching many files, you likely ran the CLI without initializing the repo first. Must run `git init && git add . && git commit` before launching.

**Submission Checker Tool (optional but recommended):**
1. Go to Snorkel -> Marlin-Submission-Checker-V3
2. Fill in fields per turn: prompt, Model A/B Solution Quality/Agency/Communication, SxS ratings
3. Hit feedback button to run checks
4. It flags: justification/SxS mismatch, unexplained ratings, PR references in prompts, repeated follow-ups
5. Multi-turn tab: paste prompts across turns, flags redundant requests or scope drift
6. Flagged issues are a preview of what reviewers look for. Getting green = good sign.
7. Copy clean values into the CLI submission

**Accidental early submission recovery:**
If you submit too early, the recovery path is:
1. Skip the task
2. Restart the entire workflow from Phase 1
3. Get new Prompt Prep approval
4. Use the NEW tarball (do NOT reuse old tarball)
5. Re-run the CLI

### Environment Rules
- Interface code for V3: `cc_agentic_coding_next`
- Use ALIAS email for auth, not Google account.
- If repo has virtual env/conda/nvm, create an activation script and `export CLAUDE_ENV_FILE=./env-setup.sh` before launching HFI. HFI sources this before every Bash command in both trajectories.
- Keep tmux trajectory sessions visible - approve permission prompts manually.
- **Dev environment MUST be fully configured before Turn 1**: install deps, set up venvs, verify baseline tests pass. Do NOT penalize models for env failures if setup wasnt done.

### LLM Detection Rules (from official training)

The review team uses a **beyond-reasonable-doubt** standard. Rejection requires:
- **3-4 cumulative distinct repeated signals**, OR
- **One critical signal** (hallucination or chat-log leak)

Not all suspected LLM content should be rejected. The totality of the writing sample along with these flags are considered together.

**Two categories of LLM signals:**
1. **Unnaturally "over-correct" writing** that a human would be unlikely to write
2. **Hallucinations or contrived mistakes** from LLMs attempting to mimic natural writing

**Five specific patterns that get flagged:**

| Signal | Example |
|--------|---------|
| **Hallucinations** (citing nonexistent functions/files) | "Correctly handles datetime objects by calling isinstance() early, reusing the to_iso_string() utility..." (to_iso_string() does not exist) |
| **Uncommon ASCII** (em-dashes, arrows used consistently) | "fastapi/params.py -- Add a scope field. fastapi/types.py -- Change the cache key." (Seven bullets each using a perfectly formatted em-dash) |
| **Random markdown/bolding** (bolded with no reason) | "The **core behavior** seems solid. It stayed scoped to `pricing/discounts.py` which is what we want. Run **pytest** to verify." |
| **Grammar too perfect** (zero casual phrasing, zero typos) | Two full paragraphs of evaluation with zero contractions, zero hedging, every sentence reads like edited prose |
| **Batched parallel lists** (multiple parallel reasons) | "Solution Quality (B): Leverages the validate_format_chain() helper... The formats list is passed through DATE_FORMAT_REGISTRY... Correctly handles datetime objects... Adds implicit support for timezone-aware strings..." (Four justifications with equal weight and perfect parallel structure) |

### Official V3 Prompt Categories (14)

| # | Category | Description |
|---|----------|-------------|
| 1 | Git | Tasks involving git operations (branch, merge, rebase, etc.) |
| 2 | Ambiguous | Prompt where a good model should ask for clarification first |
| 3 | Discussion | Answer questions about code without producing code. Reasoning through problems or tradeoffs. |
| 4 | Explaining | Walk through / narrate how existing code works. Distinct from Discussion: Explaining is asking how existing code or a change works, Discussion is reasoning through tradeoffs. |
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

**Reviewer category enforcement:**
- Reviewer verifies selected category matches prompt
- **Severe mismatch**: Reviewer will reject
- **Partial match**: Reviewer may modify rather than reject
- Reviewers can add or change categories at the end to reflect the full conversation
- Category can evolve across turns (Turn 1 = Discussion, Turn 2 = Code Review). You only declare the initial category.
- If one category gets flooded, Snorkel may temporarily disable it until submissions balance out.

---

## PROMPT STRATEGY (FROM TOP PERFORMERS)

This section captures experiential knowledge from consistently accepted submissions. These are not official rules but proven patterns that bridge the gap between "what the rules say" and "how to actually get accepted."

### The Divergence-Completion Principle

Your task must satisfy two constraints simultaneously:
1. **Divergence**: Model A and B must produce meaningfully different outputs (at least A3/B3 on key axes)
2. **Completion**: By the final turn, the code must be production-ready within the PR scope

Both constraints must hold. Divergence without completion = rejected for "stopped short." Completion without divergence = weak evaluation with A4/B4 across axes, hard to justify ratings.

### The 3-Turn Funnel

Structure your turns as a narrowing funnel:

| Turn | Scope | Prompt Style | Target Completion |
|------|-------|-------------|-------------------|
| **Turn 1** | Wide | Describe the problem and desired outcome. Leave HOW to the model. ~80-150 words. | Core implementation done |
| **Turn 2** | Narrower | React to the winner's actual diff. Target 2-3 specific gaps you found. | Most gaps addressed |
| **Turn 3** | Narrowest | Integration verification, cleanup, final edge cases. | Production-ready |

**Why this works:**
- Open Turn 1 forces models to make their own engineering decisions (which files first, what pattern to use, test early or late). Those independent choices create natural A3/B3+ differences.
- Specific Turn 2/3 are grounded in real output, so they are easy to write, impossible to be "non-meaningful", and impossible to be "over-prescriptive."
- 3 turns hits the minimum requirement without wasting time.

### What Creates Divergence (A3/B3+ differences)

- Open-ended Turn 1 where models make their own architectural decisions
- Tasks with multiple valid implementation approaches
- Problems requiring exploration of the codebase before acting
- Tasks where ordering of changes matters (which module first)

### What Kills Divergence (the A4/B4 trap)

- **Too detailed Turn 1**: Both models follow the same recipe step by step, produce near-identical output. The 6-item numbered list problem.
- **Too simple task**: Both models solve it instantly the same way. Trivial fix, trivial scope.
- **Prescriptive instructions**: No room for independent judgment, both models converge.

If your Turn 1 produces near-identical outputs from A and B, your prompt was either too detailed or too simple. Next time, describe less HOW and more WHAT.

### PR Scope Sizing (the missing lever)

PR scope determines whether you can satisfy both constraints. Pick wrong and no prompt strategy saves you.

| Scope Problem | Symptom | Fix |
|--------------|---------|-----|
| **Too big** | Turn 1 barely scratches the surface. Not production-ready by Turn 3. | Pick a narrower slice of the PR. Focus on one logical change. |
| **Too small** | Turn 1 finishes almost everything. Nothing meaningful for Turn 2/3. | Pick a broader PR or add related complexity. |
| **Sweet spot** | Turn 1 gets the core done. Clear gaps visible in diff for Turn 2/3. Code is production-ready after Turn 3. | This is what you want. |

### Turn 1 Prompt Guidance

The Turn 1 prompt should read like a brief GitHub issue, NOT a detailed implementation spec:

**Too detailed (kills divergence):**
> "Refactor the serialization module to: 1. Define explicit data classes for X, Y, Z. 2. Consolidate computation into a single module that walks A, queries B, builds C. 3. Add reconstruction path. 4. Introduce facade. 5. Remove old utilities. 6. Update tests."

**Right level (creates divergence):**
> "The serialization logic in this repo is scattered across multiple utility modules with no clear ownership. Consolidate it into a clean data pipeline with proper serialization boundaries, a reconstruction path for cached metadata, and test coverage for the new data shapes. The old scattered utilities should be removed. Code must be production-ready."

Same scope, but the second version lets the model decide HOW to structure the solution. Two models will make different choices, giving you real differences to evaluate.

---

## WRITING STYLE RULES (APPLY TO ALL GENERATED TEXT)

When generating any text that the user will paste into Snorkel or submit,
read and follow the writing style rules in `docs/HUMANIZER_PROMPT.md`.
That file is the single source of truth for all humanizing rules.

The rules cover three layers:
- Layer 1 (formatting): compact lists, dropped apostrophes, spacing quirks
- Layer 2 (structure): killed contrasts, fragments, dev shorthand
- Layer 3 (phrasing): natural developer phrasing patterns (7% AI detection)

Apply ALL three layers to every piece of generated text: prompts,
feedback, evaluations, reflections, follow-up prompts, edge cases,
acceptance criteria, repo definitions, PR definitions - everything.

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
- Agency/Communication of failed trajectory: never write "N/A". Instead write something like "Model produced no code changes but its initial approach of reading the codebase structure before diving in showed reasonable intent"
- Key-axis: use the AXIS NAME (e.g. "Correctness"), never raw numbers like "6.1"
- The winner's changes get synced to main repo for the next turn

### When one trajectory completes partially (CRITICAL -- most common scenario)
This is the case reviewers flag most often. Both trajectories produced SOME
work but one did more. DO NOT blanket all 11 axes to one extreme rating.

- Compare what EACH trajectory actually accomplished (count completed sub-tasks)
- The winner gets favorable ratings on axes where they genuinely outperformed
- The loser STILL gets credit on axes where they did real work
- Example: if prompt had 5 sub-tasks, A completed all 5, B completed 3:
  - Correctness: A2 (A did more, but B wasnt wrong on what it did)
  - Code quality: A3 or A4 (both may have written clean code)
  - Instruction adherence: A2 (A followed more of the prompt)
  - Verification: could be B3 if B ran tests but A didnt
  - Communication: A4 if both communicated clearly
- The justification MUST acknowledge what the loser accomplished
- NEVER rate all 11 axes identically -- this signals lazy evaluation

### When both trajectories produce identical/near-identical output
- Do NOT default to A4/B4. You MUST lean towards one model.
- Run `bash automation/hfi_orchestrator.sh compare-diffs` to confirm similarity.
- Differentiate based on TRACE behavior: which model ran tests, which explored the codebase first, which communicated better, which stayed on scope.
- If traces are also identical, pick the one with better process (explored first, tested after, committed cleanly) and rate A3/B3.

### When both trajectories fail
- Rate A4/B4 ("minor differences only" -- both produced nothing)
- Document both failures in Solution Quality / Agency fields
- You can still continue with Turn 2 -- the prompt might be too broad
- Consider a more focused Turn 2 prompt targeting a specific sub-task

### When a trajectory changes files outside the prompt scope (submodules, vendored code)
- This is common with Rust repos (library/backtrace, library/stdarch submodule pointers)
- Also happens with vendored dependencies, lock files, or auto-generated code
- Run `bash automation/hfi_orchestrator.sh compare-diffs` which flags these automatically
- Flag it as a weakness: "Model X modified files outside the task scope (library/backtrace, library/stdarch) which are submodule pointers unrelated to the refactoring task"
- Do NOT dismiss these as "just a technical glitch" -- they indicate the model made uncontrolled changes

### Greenfield tasks (Category 7 -- building from scratch)

Greenfield is fundamentally different from all other categories. There is no PR, no existing codebase, no tarball.

**What makes Greenfield different:**
- Task starts from an EMPTY repository. You create the repo yourself.
- You do NOT need to select a PR on Snorkel. You can use your own creativity or draw inspiration from an existing PR.
- For Greenfield submissions you may not use a PR at all (per the official Prompt Preparation guide).
- All work MUST remain in a private repository. Never push to public repos.
- Everything else still applies: 3+ meaningful turns, CLAUDE.md, evaluation writeup, all grounding rules.

**Setup flow for Greenfield (replaces the standard tarball flow):**
1. Create a new empty directory for your project
2. `git init && git commit --allow-empty -m "Initial commit"` (or create a minimal scaffold and commit)
3. Create `CLAUDE.md` describing what you want built: architecture, tech stack, testing strategy, conventions
4. Launch HFI as normal (the repo is empty but initialized)
5. Your Turn 1 prompt describes what to build from scratch

**Prompt writing for Greenfield:**
- Describe what you want built, not how to build it (still no over-prescriptive instructions)
- Include: what the application/library does, key components, success criteria, testing expectations
- Still target 6-8 engineer-hours of complexity
- Think of it as writing a technical spec / RFC, not a tutorial
- Example: "Build a CLI tool that manages local development environments for multiple languages. It should detect project type from config files, install deps into isolated environments, and provide commands to switch between projects. Support at minimum Python (venv), Node (nvm/volta), and Rust (rustup). Include unit tests for project detection and integration tests for the full switch workflow. The tool should handle edge cases like missing config files, corrupted environments, and concurrent access gracefully."

**CLAUDE.md for Greenfield:**
Since theres no existing codebase, your CLAUDE.md sets the entire context:
- Describe what is being built and why
- Specify language, framework, and dependency choices
- Define directory structure expectations
- Describe testing framework and conventions
- List any architectural constraints

**Evaluation differences for Greenfield:**
- Solution Quality focuses on: does the built solution work, is the architecture sound, are there tests
- Agency focuses on: did the model make reasonable architectural decisions, did it set up the project structure well
- The "did it follow codebase conventions" axis (6.2) becomes "did it establish and follow consistent conventions"
- Scope control (6.4) is about whether it built what was asked vs overbuilt/underbuilt

**Greenfield vs New Feature distinction:**
- Greenfield = empty repo, building from nothing
- New Feature = existing repo, adding entirely new functionality
- If there's already code in the repo, it's New Feature, not Greenfield

### Feedback submission times out ("Uploading diffs and syncing trajectory state")
This is the most common Turn 3 failure. Symptoms:
- HFI shows "Submitting feedback... Uploading diffs and syncing trajectory state"
- It hangs for 30+ seconds then shows a timeout error
- OR it appears to succeed locally but the turn is missing from Snorkel

**Root causes (in order of likelihood):**
1. Context overflow -- trajectories accumulated too much context across turns,
   producing corrupted or oversized diffs that timeout during upload
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

| #    | Question | What to Write |
|------|----------|---------------|
| 6.1  | Did it get the right answer? | What was implemented; whether it matches required behaviour; where it still fails; how you verified. |
| 6.2  | Is code well-structured / consistent? | What files changed; whether helpers match existing patterns; naming, structure, error handling follow conventions. |
| 6.3  | Did it follow directions + CLAUDE.md? | Whether it followed prompt constraints; avoided forbidden behaviour; any justified deviations. |
| 6.4  | Did it right-size the solution? | Did it overbuild or underdeliver? Did it change unrelated files? |
| 6.5  | Did it confirm before destructive actions? | List risky actions and whether it asked first. If none, state that explicitly. |
| 6.6  | Did it accurately report what it did? | Compare model claims vs actual diffs. Call out false claims. |
| 6.7  | Professional judgment (not sycophantic)? | Did it challenge bad assumptions? Suggest alternatives? Proceed when it should have asked? |
| 6.8  | Did it check its work (tests/edges)? | What tests were run or not; failures fixed or suppressed; edge cases covered. |
| 6.9  | Did it ask questions only when ambiguous? | Which questions asked; whether needed; whether discoverable by reading code. |
| 6.10 | Senior SWE-like approach? | Sound engineering process: planning, exploring before acting, verifying assumptions. |
| 6.11 | Communication clear and concise? | Easy to understand, appropriately concise, professional tone. |

Rating scale:
- A1: A clearly superior ("fails", "incorrect", "broken")
- A2: A significantly better ("substantially better", "missing key coverage")
- A3: A better overall ("better structured", "tighter scope")
- A4/B4: Effectively equivalent ("minor differences only")
- B3/B2/B1: Mirror of A3/A2/A1 but for B

Key-axis field is REQUIRED for A1, A2, A3, B1, B2, B3.

**Key-axis calibration (April 2026 update):** Do NOT default to correctness. Choose the axis that actually decided the preference. If the deciding factor was tighter scope control, better testing discipline, or more accurate/honest self-reporting, select that axis directly. One sentence is sufficient.

---

## TURN 2/3 PROMPT TEMPLATES

**Note:** These are structural starting points. For Turn 1, see "Prompt Strategy" above, keep it shorter and more open-ended (~80-200 words, describe problem + desired outcome) to create divergence between models. Turn 2/3 templates below are fine as-is since they are naturally specific.

### Turn 2 template (edge cases / hardening)
```
Review the [module] changes from the previous turn. I found these gaps:

1. [Specific gap, e.g. "When X has zero dependencies, the lookup
   produces a KeyError because the key was never initialized."]
   Add a guard and a test case.

2. [Second gap, e.g. "The serializer does not handle empty mappings."]
   Add a test that round-trips an empty mapping.

3. [Third gap, e.g. "Method X calls list.index() which is O(n)."]
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

#### TURN 2/3 PROMPT CHECKLIST (run before writing each follow-up prompt)

**STRATEGY**

- [ ] You are reacting to the WINNER's actual diff from the previous turn, not writing from scratch
- [ ] Turn 2 = narrower scope: target 2-3 specific gaps you found in the winner's code
- [ ] Turn 3 = narrowest scope: integration verification, cleanup, final edge cases
- [ ] Each turn advances the implementation concretely (not "review everything")

**CONTENT**

- [ ] Names specific file(s) and function(s) where the gap exists
- [ ] Describes the exact issue (not a vague concern)
- [ ] Requests a concrete change (not "make sure it works")
- [ ] 2-4 sentences maximum per gap
- [ ] Gaps are grounded in what you actually saw in the diff, not hypothetical

**HUMANIZATION**

- [ ] No em-dashes or double hyphens
- [ ] No LLM signature words (leverage, utilize, delve, etc.)
- [ ] No role-based prompting
- [ ] Reads like a dev filing a follow-up issue, not a polished specification
- [ ] Varied sentence structure if listing multiple gaps

**DETECTION**

- [ ] No PR references (#digits, "this PR", branch names)
- [ ] No over-prescriptive line-by-line instructions
- [ ] Prompt is distinct from Turn 1 (different structure, different framing)

RULES for follow-up prompts:
- Each turn must identify a SPECIFIC issue (name file, function, behavior)
- Each turn must request a CONCRETE change (not "review everything")
- Each turn must ADVANCE the implementation meaningfully
- "Review everything and make sure it works" = REJECTION

---

## HOW TO USE

Just talk to Cursor naturally. The AI recognizes what you need from context:

| What you say | Phase | What happens |
|---|---|---|
| "analyze these repos", "check these repos" | 1 | Reads `live_repos.json`, fetches repo data via `gh`, ranks repos |
| "analyze these PRs", "check these PRs" | 1 | Reads `live_prs.json`, fetches PR data via `gh`, ranks PRs |
| "analyze both repos and PRs" | 1 | Both repo + PR analysis sequentially |
| "generate the prompt", "prepare the prompt" | 2 | Fetches PR diff + code, generates all prompt fields |
| "lets start a task", "new task", "start" | All | End-to-end guided workflow from Phase 1 to 8 |
| "continue from where we left off", "resume" | Any | Resumes from last saved state |

---

## STEP 1: REPO ANALYSIS

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

## STEP 2: PR ANALYSIS

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
2. **6-8 engineer-hours of effort** — complex enough for a senior engineer to spend 6-8 hours on
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
| 7 | Greenfield | **Building from scratch in empty repo (no PR needed)** |
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

# PHASE 2 - PROMPT PREPARATION

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

**Run the PROMPT PREPARATION CHECKLIST (section 3E/3F boundary) before and after writing all fields.**

**CRITICAL: Apply humanizer rules (docs/HUMANIZER_PROMPT.md) to ALL text
fields below, not just the Initial Prompt.** Repo Definition, PR Definition,
Edge Cases, Acceptance Criteria, Effort and Complexity all get pasted into
Snorkel where reviewers can see them. If these fields read like polished
AI output (identical openers, perfect parallel structure, zero hedging,
no contractions, no fragments) they contribute to LLM detection signals.

Anti-patterns to avoid across ALL fields:
- Starting 3+ numbered items with the same word/phrase ("Done when...", "When the...", "The model...")
- Perfect parallel sentence structure across all items in a list
- Zero casual language in multi-sentence prose fields
- Grammar that is too clean (no contractions, no fragments, no hedging)
- Using double hyphens in any field

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
**Apply humanizer rules.** This should sound like a dev describing
a repo to a teammate, not a Wikipedia article or README blurb.

### FIELD 4: PR Definition

Write 3-5 sentences explaining what this specific PR changes and why. Cover:
- What problem or limitation existed before this PR
- What the PR does to address it
- Which parts of the codebase are affected
- What the impact is on the rest of the system

Do NOT reference the PR number or URL. Write as if describing the planned work, not a completed PR.
**Apply humanizer rules.** No polished corporate prose. Write like
a dev would actually explain this change in a standup or Slack message.

### FIELD 5: Edge Cases

List 3-6 concrete, specific edge cases the model needs to handle. Each edge case must:
- Name the specific file, function, or data path involved
- Describe what happens under that condition
- Explain why it is tricky (not obvious)

**Apply humanizer rules here.** Vary your sentence structure across items.
Do not start all items with "When..." or any repeated opener. Mix up how
you phrase each one. No double hyphens.

Bad edge case: "Handle empty input"
Good edge case: "Asset specs with zero dependencies cause a KeyError in the downstream adjacency lookup inside the compute function, the key never gets initialized in the mapping so it blows up. Need to guard against that and initialize empty sets for those assets"

### FIELD 6: Acceptance Criteria

List 4-8 concrete acceptance criteria. Each one must be:
- Verifiable (you can check if it is done or not)
- Specific (names files, functions, behaviors)
- Production-focused (not just "it works")

**DO NOT use the "Done when..." template for every item.** Starting all
criteria with the same phrase creates a batched parallel list, which is
a flagged LLM detection signal. Instead, vary your openers naturally.
Write each criterion as a different kind of statement. Mix fragments,
conditions, and plain descriptions. Apply humanizer rules.

Example (notice varied openers):
- "Serializable data classes should roundtrip cleanly through the serdes framework without dropping fields"
- "The sensor module delegates to the facade instead of computing its own data at that point"
- "Old utility module is fully removed, no imports reference it anywhere"
- "Existing tests still pass and new tests cover the restructured data shapes"

### FIELD 7: Effort and Complexity (V3 REQUIREMENT)

2-4 sentences explaining WHY this task is non-trivial. This is NOT a restatement of the task. Focus on:
- Number of files/modules touched and cross-component dependencies
- Subtle interactions that require careful analysis
- Edge cases where naive approaches break
- Why a competent engineer would need 6-8 hours

**Apply humanizer rules.** This should read like a dev explaining why
something is hard to a teammate, not like a polished paragraph from
a technical document.

Bad: "This task requires changing 17 files across 4 crates."
Good: "The trait gets implemented by 6 different type relations spread across 4 compiler crates and each one has its own constraints on how goals flow through the system. The opaque type handling path converts between Goal and Obligation at multiple boundaries, getting any one of those wrong silently breaks downstream diagnostic reporting. A naive search and replace misses the cases where the cause has to be preserved for error messages"

### FIELD 8: Testing Setup

Output: "Yes" or "No"

This depends on whether the user has actually set up the repo locally. If unknown, output "Yes" with a note that the user must verify this before submitting.

### FIELD 9: Initial Prompt (THE CRITICAL FIELD)

This is the actual prompt text that will be given to the model. This is the most important field.

#### WRITING RULES (MANDATORY -- VIOLATION = REJECTION)

**ABSOLUTE PROHIBITIONS:**
1. NO em-dashes. Use regular hyphens (-) or commas instead. Never use the character "--" (the long dash). This is a model signature that will get the submission rejected.
2. NO PR references. Never mention PR numbers, branch names, or "this PR". Write as if you are the developer planning this work from scratch.
3. NO role-based prompting. Never write "You are a senior engineer" or "Act as an expert". Just describe the work directly.
4. NO over-prescriptive instructions (V3 REJECTION REASON). Do NOT say "on line 47, change X to Y" or "rename function bar to baz in file foo.py". Do NOT specify exact method renames, type signatures, or field changes. Describe the PROBLEM and what SUCCESS looks like. Let the model figure out implementation details. Think: "what would I write in a GitHub issue?" not "what would I write in a code review comment."
5. NO hand-holding. Do not walk the model through every step or every file. A good prompt targets 6-8 engineer-hours of complexity. If you find yourself listing more than 3-4 specific functions/methods to change, you are being too prescriptive.
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
- Total length: 80-200 words. Shorter prompts produce better divergence. Long enough to set direction, short enough to leave room for the model.

**GOOD EXAMPLE (from the Marlin guide):**
"Gaphor's property editor currently mixes model-level and diagram-level behavior for UML Dependency elements and it needs to be separated properly. The Dependency model objects should get their own property page showing Source and Target when selected from the model tree, and the existing diagram item editor needs to be pulled out into a separate item-specific page with updated identifiers. There's also the isFinalSpecialization attribute on classifiers that isn't exposed anywhere right now, so that needs a toggle in the classifier property editor with proper transaction handling. GTK UI definitions will need updating to match, and unit tests should cover both the Dependency property visibility and classifier specialization updates. Everything should follow the UML spec and be production ready when done."

Notice: no em-dashes, no role-based prompting, names exact components, verifiable outcomes, reads like a real issue, human-sounding. Varied sentence structure, not a list of imperative commands.

**OVER-PRESCRIPTIVE vs APPROPRIATELY SCOPED (V3 critical distinction):**

Models are capable of significant independent engineering judgment.
Prompts that micromanage every implementation step deprive reviewers
of the ability to evaluate that capability, and push submissions
towards a style that can appear LLM-generated. Describe the problem
clearly and state what success looks like - but do not hand-hold
the model through every file, function, and design decision. Leave
space for the model to figure things out.

Over-prescriptive (AVOID - rejection reason):
"In api/search.py, on line 47, change the call from decode('ascii') to
decode('utf-8'). Then open tests/test_search.py and add a test named
test_non_ascii_query..."

Appropriately scoped (AIM FOR):
"Requests to /api/search return 500 when the query contains non-ASCII
characters. Fix the encoding/decoding path so unicode queries work
correctly and add regression test coverage."

**HOW TO CONVERT A PRESCRIPTIVE PROMPT TO APPROPRIATELY SCOPED:**

You CAN and SHOULD name exact components, identifiers, subsystems from
the codebase. The good example from the Marlin guide names exact things:
"isFinalSpecialization attribute", "classifier property editor",
"UML Dependency elements", "GTK UI definitions". Naming things is NOT
prescriptive. What IS prescriptive is telling the model exactly HOW to
change them step by step.

The distinction: use identifiers to describe the CURRENT STATE and
WHAT IS WRONG, not to give step-by-step implementation instructions.
Think "what would I write in a GitHub issue?" not "what would I write
in a code review telling someone exactly what to change."

Prescriptive patterns to convert:

  "Rename X to Y"
  --> describe why X is a problem, let model figure out the rename

  "Change field from TypeA to TypeB"
  --> describe what behavior the component should have instead

  "Add method foo that does bar"
  --> describe what capability is needed without naming the method

  "In file.rs, change call from A to B"
  --> name the logical layer/boundary, not the file

  "Update all call sites across crate1, crate2, crate3"
  --> delete, the model will find call sites on its own

  "Remove the XAlias type alias from module/mod.rs"
  --> "clean up whatever aliases become unnecessary"

  3+ specific functions doing similar work listed individually
  --> merge into one concept phrase ("the opaque type handling path")

REAL EXAMPLE (Rust compiler prompt):

Before (prescriptive - lists exact renames and type changes):
"Refactor the ObligationEmittingRelation trait. Rename the trait to
PredicateEmittingRelation. Change register_obligations to register_goals
accepting Goal<'tcx, ty::Predicate<'tcx>>. In CombineFields change the
obligations field from Vec<PredicateObligation> to Vec<Goal>. Add an
into_obligations method on CombineFields. Update handle_opaque_type in
InferCtxt to accept Span instead of &ObligationCause."

After (appropriately scoped - describes problem and desired outcome):
"The type relation layer in rustc_infer is mixing solver concerns with
diagnostics concerns. Every relation operation produces full Obligation
objects with ObligationCause, but the solver only needs predicate and
param_env. The trait controlling how relations give their output needs
to work with Goal objects instead of carrying the whole Obligation
around. ObligationCause attachment should move outward to the public
API boundary. The combine-fields machinery should collect goals
internally, conversion to obligations should happen only when results
are being surfaced. The opaque type handling path should take Span
instead of a full cause and return goals. Whatever type aliases become
unnecessary after this, clean those up. Compiler bootstrap and tests
must pass, diagnostics output stays the same."

Notice: the "after" version still names ObligationEmittingRelation,
ObligationCause, Goal, CombineFields, Span - real identifiers from the
codebase. But it describes WHAT the current state is and WHAT the end
state should be, not HOW to get there step by step.

---

## 3D. Snorkel Grammar Feedback Fix

Snorkel runs an automated grammar checker on submissions. If it flags issues,
fix ONLY the specific items mentioned. Common fixes:
- Add spaces after commas everywhere: "(subtyping, equating, LUB, GLB)" not "(subtyping,equating,LUB,GLB)"
- Add articles back where flagged ("The solver" not "Solver")
- Add commas before "and" in compound sentences
- Break long run-on sentences into shorter ones with periods
- Fix awkward phrasing ("causes get constructed" not "cause gets constructed")
- Add proper spacing around parentheticals

IMPORTANT: Snorkel's grammar checker conflicts with humanizing rules 1, 3, and 10
(compact lists, spacing quirks, compact parentheticals). When Snorkel flags these,
fix them. Keep the OTHER humanizing rules that Snorkel doesnt flag: dropped
apostrophes, code identifiers, terse phrasing, sentence fragments it accepts,
no logical connectors, dev shorthand.

---

## 3E. Post-generation quality check

After generating all fields, run the prompt quality validator:

```bash
python3 automation/prompt_validator.py "PASTE_THE_PROMPT_TEXT_HERE"
```

Or Cursor can self-check against these rules:

1. Search for em-dash characters (the long dash, Unicode U+2014 or double-hyphen patterns that look like em-dashes). Replace with regular hyphens or commas.
2. Search for PR references: any pattern like #[digits], pull/[digits], PR-[digits], "this PR", "the PR", branch names from the gh data.
3. Search for role-based phrases: "you are a", "act as", "as a senior", "as an expert", "imagine you are".
4. Search for over-prescriptive patterns: "on line [number]", "in file X, change Y to Z", step-by-step numbered instructions telling the model exactly what to do in each file.
5. Verify the prompt is 80-200 words.
6. Verify it reads like a human-written GitHub issue, not an LLM-generated specification.

---

#### PROMPT PREPARATION CHECKLIST (run this before and after filling every field)

This checklist consolidates every rule from the playbook that applies when
generating prompt preparation fields. Go through it top to bottom. Do not skip items.

**STRATEGY CHECK (before writing anything)**

- [ ] Have you read the full PR diff, not just the description?
- [ ] Have you identified the core problem the PR solves, independent of the PR itself?
- [ ] Is the PR complex enough for 6-8 engineer-hours of work?
- [ ] Have you planned the 3-Turn Funnel? Turn 1 = wide/vague (problem + outcome), Turn 2 = specific gaps from Turn 1 winner, Turn 3 = integration/cleanup
- [ ] Does your Turn 1 prompt describe WHAT not HOW? No file paths, no line numbers, no step-by-step instructions
- [ ] Is your Turn 1 prompt 80-200 words? Shorter is better for divergence

**HUMANIZATION CHECK (apply to EVERY field, not just the prompt)**

- [ ] No double hyphens (--) anywhere in any field
- [ ] No em-dashes anywhere
- [ ] No LLM signature words: leverage, utilize, delve, comprehensive, robust, streamline, facilitate, encompass, pivotal, intricate, nuanced, paradigm
- [ ] No batched parallel lists (all items starting with the same word/pattern like "Done when...", "Add...", "Update...", "Ensure...")
- [ ] Varied sentence structure across items in every list. Mix fragments, conditions, and plain descriptions
- [ ] No perfect grammar everywhere. Drop some articles, use contractions, leave some rough edges
- [ ] No terminal periods on list items (unless a full multi-sentence paragraph)
- [ ] Reads like a dev writing to a teammate, not a polished doc or Wikipedia article
- [ ] No role-based prompting in the prompt field ("you are a...", "act as...")

**FIELD-SPECIFIC CHECKS**

- [ ] Repo Definition: sounds like a dev describing a repo to a teammate, not a README blurb
- [ ] PR Definition: sounds like a dev explaining a change in standup, not corporate prose
- [ ] Edge Cases: each item uses a different opener. No repeated "When..." pattern. Each references a specific file/function from the diff
- [ ] Acceptance Criteria: NO "Done when..." template. Vary openers across all items. Mix fragments, conditions, plain descriptions
- [ ] Effort and Complexity: explains WHY the task is hard, not WHAT the task is. References specific cross-module interactions and non-obvious complexity
- [ ] Initial Prompt: 80-200 words. Describes the problem and desired end-state. Does NOT prescribe implementation steps

**DETECTION CHECKS (after writing everything)**

- [ ] No PR references anywhere: no #digits, no "this PR", no "the PR", no branch names
- [ ] No em-dashes or double hyphens
- [ ] No role-based prompting
- [ ] Not over-prescriptive (no "on line X, change Y to Z")
- [ ] Prompt reads like a human-written GitHub issue
- [ ] All edge cases are grounded in actual diff content (specific files/functions visible in the diff)
- [ ] Acceptance criteria can be verified without reading the PR

---

## 3F. Output format

Present all fields in this exact structure (ready to copy-paste into Snorkel):

```
============================================================
MARLIN V3 - PROMPT PREPARATION (READY TO SUBMIT)
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
1. [verifiable criterion, vary openers, no "Done when" template]
2. [verifiable criterion, different sentence structure from #1]
3. [verifiable criterion, mix fragments and full sentences]
...

EFFORT AND COMPLEXITY:
[2-4 sentences explaining WHY this task is non-trivial. Include:
number of files/modules involved, cross-component interactions,
edge cases requiring careful analysis, why a competent engineer
would need 6-8 hours. This is NOT a restatement of the task -
it explains what makes it HARD.]

TESTING SETUP: [Yes/No]

------------------------------------------------------------
PROMPT DEFINITION
------------------------------------------------------------

INITIAL PROMPT:
[The actual prompt text, 80-200 words, human-sounding, no em-dashes,
no PR references, no role prompting, not over-prescriptive.
V3: describe the PROBLEM and SUCCESS criteria. Do NOT hand-hold
through every file/function/rename. Let the model figure out
implementation details.]

============================================================
QUALITY CHECK RESULTS
============================================================
- Em-dashes found: [Yes/No, if Yes list and fix them]
- PR references found: [Yes/No, if Yes list and fix them]
- Role-based prompting: [Yes/No, if Yes list and fix them]
- Over-prescriptive: [Yes/No, assessment per V3 guidance]
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
bash automation/hfi_orchestrator.sh setup ~/Downloads/repo.tar       # Unpack, git init, deps, tests
bash automation/hfi_orchestrator.sh claude-md /path/to/repo           # Generate CLAUDE.md (BEFORE launch)
bash automation/hfi_orchestrator.sh launch-hfi /path/to/repo           # Copy binary, start tmux session

# Phase 4: Task Execution
bash automation/hfi_orchestrator.sh inject prompt.txt                 # Paste prompt into control session
bash automation/hfi_orchestrator.sh monitor                           # Watch trajectories until done

# Multi-Turn
bash automation/hfi_orchestrator.sh capture-diffs [turn#]             # Save A/B diffs
bash automation/hfi_orchestrator.sh next-turn                         # Exit HFI + relaunch --continue
bash automation/hfi_orchestrator.sh inject turn2_prompt.txt           # Inject next turn prompt

# All-in-one
bash automation/hfi_orchestrator.sh full ~/Downloads/repo.tar prompt.txt

# Quality
bash automation/hfi_orchestrator.sh pre-submit                        # Full pre-submission check

# Utility
bash automation/hfi_orchestrator.sh status                            # Show current state
bash automation/hfi_orchestrator.sh set-session <id>                  # Manually set tmux session ID
```

### WHICH WORKFLOW TO FOLLOW

This playbook contains three workflow descriptions. They are NOT alternatives, they serve different purposes:

| Workflow | When to use | What it covers |
|----------|-------------|----------------|
| **Typical Workflow** (below) | Quick reference for experienced users | 14-step command cheat sheet, Phase 3-4 only |
| **FULL MULTI-TURN AUTOMATION** (next section) | After Turn 1 is done and you say "automate the rest" | Detailed steps for captures, feedback, turns 2-3, evaluation |
| **END-TO-END GUIDED WORKFLOW** (last section) | Starting a brand new task from scratch | Complete Phase 1-8 with banners and human checkpoints |

**If you are new:** Start with END-TO-END GUIDED WORKFLOW. It covers everything.
**If you have done tasks before:** Use Typical Workflow as a cheat sheet, FULL MULTI-TURN AUTOMATION for the detailed post-Turn-1 steps.

### Typical Workflow

1. Download tarball from email, download `darwin-arm64` from feedback.anthropic.com
2. `bash automation/hfi_orchestrator.sh setup ~/Downloads/repo.tar` -- unpack, git init, deps, tests
3. `bash automation/hfi_orchestrator.sh claude-md /path/to/repo` -- create CLAUDE.md BEFORE launch
4. `bash automation/hfi_orchestrator.sh launch-hfi /path/to/repo` -- launch HFI via tmux (proper TTY)
5. **[HUMAN]** Authenticate in browser, enter Interface Code: `cc_agentic_coding_next`
6. `bash automation/hfi_orchestrator.sh inject prompt.txt` -- submits your approved prompt (Turn 1)
8. `bash automation/hfi_orchestrator.sh monitor` -- wait for trajectories to complete
9. `bash automation/hfi_orchestrator.sh fill-feedback data/turn1_feedback.txt` -- automated form fill
10. `bash automation/hfi_orchestrator.sh next-turn` -- kill session, relaunch, /clear
11. `bash automation/hfi_orchestrator.sh inject turn2_prompt.txt` -- inject Turn 2 prompt
12. Repeat monitor -> fill-feedback -> next-turn -> inject for Turn 3
13. On Turn 3: feedback file uses `::ACTION:: finish` instead of `continue`
14. **[HUMAN]** Fill Snorkel Reflection form and Submit

### Important Notes

- Uses `--tmux` mode (not `--vscode`) for scriptability
- The CLI binary must be in `~/Downloads/` before running `launch`
- Interface code for V3: `cc_agentic_coding_next`
- Multi-turn: use `next-turn` between each turn to kill the session, relaunch, and clear context. This is the normal flow, not a recovery step.
- **DO NOT** run `git commit` between turns -- the CLI manages git state
- **DO NOT** check out the PR branch -- work from the pre-PR commit
- **CLAUDE.md** must be created BEFORE launch (after setup, before HFI starts)
- **DO NOT** use claude-hfi to generate CLAUDE.md
- Dev environment must be set up BEFORE launching the CLI

---

## FULL MULTI-TURN AUTOMATION

When the user says something like "automate the rest", "handle the remaining turns",
"continue with turns 2 and 3", or "take it from here" after Turn 1 is done,
orchestrate the complete remaining workflow: capture diffs, compare trajectories,
generate follow-up prompts for Turns 2-3, and produce the final evaluation writeup.

**Prerequisites:** Turn 1 must be complete (trajectories finished, feedback form showing).

### STEP-BY-STEP PROCEDURE

Execute these steps IN ORDER. At each step, clearly indicate [AUTOMATION] vs [YOUR TURN].

---

#### STEP 1: Capture Turn 1 Diffs + Traces [AUTOMATION]

```bash
bash automation/hfi_orchestrator.sh capture-diffs 1
bash automation/hfi_orchestrator.sh capture-traces 1
```

This saves:
- `automation/data/turn1_diff_A.txt` and `turn1_diff_B.txt` (code diffs)
- `automation/data/turn1_trace_A.txt` and `turn1_trace_B.txt` (500 lines of trajectory output)
- `automation/data/turn1_summary.txt` (file-level summary)

The `capture-traces` command also runs a quick scan and reports:
- Test-related lines (pytest, cargo test, etc.)
- Error/panic lines
- Permission prompts
- Git operations

Incorporate trace findings into the feedback text (Step 3).

**RATING BALANCE RULE:** Before generating ratings, count how many
sub-tasks/requirements each trajectory completed. If the "loser"
completed ANY sub-tasks, it MUST get partial credit on relevant axes.
Never use the same extreme rating (A1 or B1) across all 11 axes
unless the loser literally produced ZERO output. If the loser completed
3 out of 5 sub-tasks, axes like Code quality, Communication, and
Question discipline should reflect partial success (A3/B3 or A4/B4).

#### STEP 2: Compare A vs B (Turn 1) [AUTOMATION]

**FIRST: Run automated comparison:**
```bash
bash automation/hfi_orchestrator.sh compare-diffs 1
```
This outputs: shared files, unique files per trajectory, scope deviations
(files outside prompt scope), and diff similarity percentage. Read this
output BEFORE writing any feedback.

**THEN: Read both diff files completely.** For each trajectory, evaluate:
1. **Correctness:** Does the implementation match what the prompt asked for?
2. **Completeness:** Are all requirements addressed, or are things missing?
3. **Code quality:** Is it well-structured, follows codebase conventions?
4. **Tests:** Did it add/update tests? Do they cover the right cases?
5. **Side effects:** Any unnecessary changes, broken imports, unrelated modifications?
6. **Scope deviation:** Did it change files outside the prompt's expected scope? Check the `compare-diffs` output for flagged files. Submodule pointer changes (library/backtrace, library/stdarch, etc.) are common out-of-scope noise -- flag them.

**V3 TRACE REVIEW (Step 5 requirement):**
Also review model traces (from `capture-traces` output), not just diffs:
- Did the model actually RUN tests, or only claim it did?
- Did it investigate root cause, or just patch symptoms?
- Did it avoid risky actions (delete, force push, reset) without confirmation?
- Did it keep scope tight and avoid unrelated changes?
- Did it accurately report what it changed vs what actually changed in the diff?
- Did it stop to ask clarification when something was genuinely ambiguous?

Reference trace behavior in your Agency / Solution Quality text (e.g. "Model A ran the
full test suite and fixed 2 failures before declaring done, while Model B only
claimed tests pass without evidence in the trace").

**GROUNDING VERIFICATION (MANDATORY -- failure here caused task rejection):**
Before writing ANY feedback text, perform these checks:
1. For every claim about what a model did/didnt do, find the exact diff hunk or trace line.
2. Before saying "X is unique to Model B", search Model A's diff for X.
3. If the `compare-diffs` output flagged scope deviations, mention them in Solution Quality.
4. Do NOT cite specific test file names, line numbers, or compile errors unless they are literally visible in the diff or trace text.
5. Do NOT relay what a model claims it did in its trace -- verify against the actual diff.

**DEV ENVIRONMENT RULE (V3 requirement):**
Do NOT penalize either trajectory for failing to install dependencies, failing to
run tests due to missing packages, or environment configuration issues. If a model
fails because the dev environment wasnt set up beforehand, that is a SETUP issue -
not a model deficiency. Note it in your feedback but do not let it affect ratings.

Determine the winner (A or B). Write a brief justification (2-3 sentences).

#### FEEDBACK GENERATION CHECKLIST (run this before and after writing every feedback file)

This checklist consolidates every rule from the playbook that applies when
generating a feedback text file. Go through it top to bottom. Do not skip items.

**BEFORE WRITING (data gathering)**

- [ ] Read BOTH diff files completely (turn{N}_diff_A.txt, turn{N}_diff_B.txt)
- [ ] Read BOTH trace files completely (turn{N}_trace_A.txt, turn{N}_trace_B.txt)
- [ ] Run `compare-diffs` and note scope deviations, shared/unique files, similarity %
- [ ] Count sub-tasks completed by each trajectory (partial credit rule)
- [ ] Take notes per model INDEPENDENTLY while reviewing. Do not wait till the end to remember what you saw
- [ ] For each trajectory verify: did it actually RUN tests (check trace), or only claim it did?
- [ ] For each trajectory verify: did it investigate root cause or just patch symptoms?
- [ ] For each trajectory verify: did it do risky actions (delete, force push, reset) without confirmation?
- [ ] For each trajectory verify: does its self-reported summary match the actual diff?
- [ ] Check if dev environment failures affected either trajectory (do NOT penalize if setup wasnt done)

**WHILE WRITING EACH FIELD**

- [ ] **Evaluative not descriptive**: every sentence has "because" / "which means" / impact explanation. "Model A added tests" is weak. "Model A added regression coverage in tests/test_search.py::test_non_ascii_query, without this a future refactor could silently reintroduce the bug" is strong.
- [ ] **Per-model fields are independent**: Solution Quality, Agency, Communication for each model talk about THAT model only. No "compared to Model B" language in per-model fields. All comparison goes into justification and key-axis.
- [ ] **Every factual claim cites a specific file/function/diff hunk**: if you cannot point to where in the diff or trace you saw it, remove the claim.
- [ ] **Cross-model verification**: before writing "X is unique to Model A", search Model B's diff for X. Both models often make similar changes.
- [ ] **Scope deviation flagged**: if `compare-diffs` flagged out-of-scope files, mention them in Solution Quality.
- [ ] **Check HOW not just WHAT**: if both models ran the linter, check HOW each ran it. One might have used wrong command, applied autofixing that created undesirable changes, or added comments that a real contributor would not write.
- [ ] **Go deeper than surface**: "73 test cases" might be garbage when you actually check what they test. "Failed completely" might be a minor coordinate bug in otherwise correct implementation. Verify magnitude.
- [ ] **Only note observations relevant to rated axes**: do not pad fields with response time, number of tool calls, or other irrelevant things.
- [ ] **Evidence directly, not vague labels**: "Model B has better error handling" is bad. "Model B wraps the getQuote and addPromoCode calls in try/catch with distinct error messages using the logger, Model A adds try/catch but does not parse the error object from the upstream 200 response" is good.
- [ ] **Agency field cites specific transcript evidence**: mention actual trace behavior (ran test suite, explored codebase structure before diving in, asked clarification). Maps to SxS 5.5, 5.7, 5.9.
- [ ] **Communication field references actual model output**: clarity of reasoning, honesty about what it did/didnt do, documentation quality. Maps to SxS 5.6.

**RATING RULES**

- [ ] No blanket extreme ratings: if the loser completed partial work, some axes MUST reflect it (use A3/B3 or A4/B4 on those axes)
- [ ] Never rate all 11 axes identically, it signals lazy evaluation
- [ ] Rating language matches magnitude: A1/B1 = "fails/broken", A2/B2 = "substantially better", A3/B3 = "better structured", A4/B4 = "minor differences only"
- [ ] Overall preference is consistent with the majority direction of axis ratings
- [ ] Key-axis uses axis NAME (e.g. "Correctness", "Scope control"), NEVER raw numbers (e.g. "6.1"). Raw numbers signal template usage and trigger rejection.
- [ ] Key-axis calibration: do NOT default to correctness. If scope control, testing discipline, or self-reporting honesty was the real driver, use that axis.
- [ ] Extreme ratings (A1/B1) are backed by strong evidence ("fails", "broken", "incorrect")
- [ ] NEVER use N/A for any axis or field

**JUSTIFICATION AND KEY-AXIS**

- [ ] Justification is self-contained: assume the reader has NOT seen your per-model fields. Resurface key points that drove the preference. Do not say "as mentioned above".
- [ ] Justification is 2-3 sentences (concise, comparative, evidence-backed)
- [ ] Justification is comparative: this is where A-vs-B comparison belongs
- [ ] Key-axis identifies the single axis that ACTUALLY decided the preference

**AFTER WRITING ALL FIELDS (humanization and detection avoidance)**

- [ ] Apply `docs/HUMANIZER_PROMPT.md` to ALL text fields: rephrase every sentence into 3 options, pick the least AI-characteristic one
- [ ] Text reads like a professional Indian developer wrote it, technically precise but with natural Indian English phrasing patterns
- [ ] No em-dashes anywhere (use comma or period instead)
- [ ] No double hyphens used as em-dashes
- [ ] No trailing periods at end of bullet points or short statements
- [ ] No random bolding of words mid-sentence
- [ ] No batched parallel lists with equal-weight identical-structure items
- [ ] Grammar is NOT too perfect: include at least some natural phrasing like contractions, hedging, sentence fragments, or run-on sentences that a real developer would write
- [ ] No hallucinations: every function name, file name, class name you mention actually exists in the diff or trace
- [ ] No LLM signature words: avoid "leverage", "utilize", "comprehensive", "robust", "streamline", "facilitate", "optimal", "enhance", "furthermore", "additionally", "in conclusion", "it is worth noting"
- [ ] Read the final text out loud (mentally). Does it sound like a human developer typed it in a text editor, or like a polished AI response?

**FINAL PRE-SUBMISSION GATE**

- [ ] Re-read every claim in the feedback against the actual diff one more time. If a claim cannot be traced to a diff hunk, remove or rewrite it.
- [ ] Run Snorkel Submission Checker if available (Marlin-Submission-Checker-V3)
- [ ] Verify the ACTION field is correct: "continue" for Turns 1-2, "finish" for Turn 3

---

#### STEP 3: Generate + Submit Feedback (Turn 1) [AUTOMATION]

**Run the FEEDBACK GENERATION CHECKLIST above before and after writing.**

Using the diff analysis from Step 2, generate a structured feedback file
following the WRITING STYLE RULES. Save it to `data/turn1_feedback.txt`
in this format:

```
::SENIOR_EXPECTATIONS::
[text using writing style rules -- what a senior eng would do]
::MODEL_A_SOLUTION_QUALITY::
[correctness, code quality, edge cases, tests. For Discussion/Ambiguous/Code Review:
quality of reasoning/analysis. Evaluative with "because"/"which means" -- cite files/functions]
::MODEL_A_AGENCY::
[how model A behaved as independent agent: risky/destructive actions (or restraint),
independent judgment, when it sought clarification. Must cite specific transcript evidence.
Maps to SxS 5.5, 5.7, 5.9]
::MODEL_A_COMMUNICATION::
[quality of model A written output: clarity of reasoning and summary, honesty about
what it did and did not do, documentation and comments. Reference transcript.
Maps to SxS 5.6]
::MODEL_B_SOLUTION_QUALITY::
[same as Model A Solution Quality but for B]
::MODEL_B_AGENCY::
[same as Model A Agency but for B]
::MODEL_B_COMMUNICATION::
[same as Model A Communication but for B]
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
[Use the AXIS NAME, not the number. Write e.g. "Correctness:
the winning model produced working code while the other failed to
compile" NOT "6.1: ...". Reviewer must understand the axis
without referencing a template.
CALIBRATION: do NOT default to correctness. Pick the axis that actually
decided the preference. If scope control, testing discipline, or honest
self-reporting was the real driver, use that axis.]
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
python3 automation/prompt_validator.py --file automation/data/turn2_prompt.txt
```

Fix any validator failures automatically. Re-validate until clean.

**QUALITY GATE -- Cross-turn similarity check:**
Compare Turn 2 with Turn 1. They must target DIFFERENT issues. If too similar, regenerate.

#### STEP 5: Execute Turn 2 [AUTOMATION]

After "Continue conversation" is selected, the HFI session stays running
and accepts the next prompt directly. No exit/relaunch needed.

**5a. Inject Turn 2 prompt:**
```bash
bash automation/hfi_orchestrator.sh inject automation/data/turn2_prompt.txt
```

**5b. Monitor trajectories:**
Poll both trajectory tmux sessions until complete. If a trajectory
asks for permission, it needs manual approval -- but this is rare.
```bash
bash automation/hfi_orchestrator.sh monitor
```

#### STEP 6: Capture Turn 2 Diffs + Compare + Submit Feedback [AUTOMATION]

```bash
bash automation/hfi_orchestrator.sh capture-diffs 2
bash automation/hfi_orchestrator.sh capture-traces 2
bash automation/hfi_orchestrator.sh compare-diffs 2
```

Read `compare-diffs` output first. Then read diff files completely.
Perform GROUNDING VERIFICATION (same as Step 2) before writing any claims.
**Run the FEEDBACK GENERATION CHECKLIST (in Step 2) before and after writing.**
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

Same as Step 5. Inject prompt into the running session.

```bash
bash automation/hfi_orchestrator.sh inject automation/data/turn3_prompt.txt
bash automation/hfi_orchestrator.sh monitor
```

Remind user to watch tmux sessions for permission prompts.

#### STEP 9: Final Diff Capture + Turn 3 Feedback [AUTOMATION]

```bash
bash automation/hfi_orchestrator.sh capture-diffs 3
bash automation/hfi_orchestrator.sh capture-traces 3
bash automation/hfi_orchestrator.sh compare-diffs 3
```

Read `compare-diffs` output first. Then read diff files completely.
Perform GROUNDING VERIFICATION (same as Step 2) before writing any claims.
**Run the FEEDBACK GENERATION CHECKLIST (in Step 2) before and after writing.**
Determine winner. Generate feedback file following WRITING STYLE RULES.
Save to `data/turn3_feedback.txt`.

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

Read ALL diffs (Turns 1-3, both A and B). Produce the evaluation and save to `automation/data/evaluation_final.md`.

The file must contain ALL sections:

**10.1 Senior Engineer Expectations**: 3-5 sentences on what a strong senior would produce. Reference specific modules and strategies.

**10.2 Model A, Solution Quality**: Correctness, code quality, edge cases, tests. For non-code tasks: quality of reasoning/analysis. Evaluative with "because"/"which means". Every claim cites a file/function.

**10.3 Model A, Agency**: How it behaved as an independent agent: risky/destructive actions (or appropriate restraint), independent judgment, when it sought clarification, whether its engagement resembled a senior engineer. Must cite specific transcript evidence.

**10.4 Model A, Communication**: Quality of written output: clarity of reasoning and final summary, honesty about what it did and did not do, documentation and comments. Reference transcript.

**10.5 Model B, Solution Quality**: Same as 10.2 for B.

**10.6 Model B, Agency**: Same as 10.3 for B.

**10.7 Model B, Communication**: Same as 10.4 for B.

**10.8 Axis Ratings (1-11)**: For each axis:
- Rating (A1-A3, A4/B4, B1-B3)
- 1-2 sentence justification with evidence

Axes: (1) Correctness, (2) Code quality, (3) Instruction adherence, (4) Right-sized solution, (5) Safety judgment, (6) Self-reporting accuracy, (7) Professional judgment, (8) Verification discipline, (9) Question discipline, (10) Senior SWE approach, (11) Communication quality.

Rules: NEVER use N/A on any axis. Always rate and justify. Extreme ratings need strong evidence.

**10.9 Overall Preference**: Winner, rating, key-axis (required for non-tie), 2-3 sentence justification. Must be consistent with axis majority. Key-axis calibration: do NOT default to correctness, pick the axis that actually decided the preference.

**10.10 Turn Prompts Record**: All 3 prompts listed.

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
    "I created the CLAUDE.md file in the repo before launching
     the HFI tool. Both models had access to it from the start
     of the session."

  Prompt Type: [MUST match one of the 14 categories from Phase 2]

  Production ready: [No updates required / Last mile updates]

  Time to complete (minutes): [estimate]

  Model response time per turn (minutes): [average]

  Task Reflection (paste this):
    [2-3 sentences about the task experience, written using
     WRITING STYLE RULES -- mention context limits if they
     happened, which model managed context better, etc.]

================================================================
  BEFORE SUBMITTING -- VERIFY THESE FIELDS ARE FILLED:
  [ ] PR URL is pasted (full GitHub URL)
  [ ] CLAUDE.md source is filled (use text above)
  [ ] Prompt Type is SELECTED (dropdown -- not blank!)
  [ ] Production ready is selected
  [ ] Time estimates are entered
  [ ] Task Reflection is pasted
  [ ] Diff Viewer: click EACH turn to verify diffs loaded

  WARNING: IRREVERSIBLE. Cannot edit after submission.
================================================================
```

### CRITICAL RULES FOR MULTI-TURN AUTOMATION

1. **Do NOT run `git commit` between turns** -- HFI manages git state
2. **Every follow-up prompt must target a DIFFERENT issue** -- no repeats across turns
3. **Every follow-up must advance the implementation** -- no vague reviews
4. **Evaluation claims must cite file/function evidence** -- no hand-waving
5. **Ratings are relative** (A vs B), not absolute (vs ideal)
6. **Justification language matches rating magnitude** -- A1 = "fails", A3 = "better structured"
7. **NEVER use raw axis numbers (6.1, 6.2, etc.) in feedback or key-axis text** -- always use names: Correctness, Code quality, Instruction adherence, Right-sized solution, Safety judgment, Self-reporting accuracy, Professional judgment, Verification discipline, Question discipline, Senior SWE approach, Communication quality
8. **NEVER rate all 11 axes identically** -- even when one trajectory clearly wins, differentiate per-axis based on what each model actually did. If the "loser" completed some sub-tasks, acknowledge that with moderate ratings on relevant axes
9. **Prompt Type MUST be selected** on Snorkel -- verify before submitting
10. **CLAUDE.md source text must be accurate** -- CLAUDE.md was created before launching HFI, both models had it from the start
11. **All generated text uses WRITING STYLE RULES** -- feedback, prompts, evaluation text all follow the humanizing rules
12. **If a trajectory fails or produces no diff**, note it and rate accordingly
13. **Validation is mandatory** -- `prompt_validator.py` on every prompt, `eval_checker.py` on evaluation
14. **NEVER use N/A** on any axis, feedback field, or Solution Quality/Agency/Communication section. Always provide a real answer
15. **All evaluation fields must be evaluative** with "because" / "which means" -- explain WHY something matters, dont just describe that it happened
16. **Key-axis required** for all non-equivalent ratings -- do NOT default to correctness, pick the axis that actually decided the preference
17. **Submissions are irreversible** -- triple-check before Submit
18. **Review model traces** (reasoning, tool calls) in tmux, not just diffs
19. **Turn 1+2 feedback: "Continue conversation". Turn 3: "Finish conversation"**
20. **GROUNDING IS MANDATORY** -- every claim must be traceable to a diff hunk or trace output. See Grounding Rules above. This was the direct cause of a task rejection.
21. **Run `compare-diffs` before writing feedback** -- use `bash automation/hfi_orchestrator.sh compare-diffs <turn>` to get automated scope/similarity analysis before writing any feedback text
22. **If both models produce identical output**, lean towards one model based on trace behavior (test execution, scope discipline, communication). Do NOT default to A4/B4.

---

## END-TO-END GUIDED WORKFLOW

When the user wants to start a new task (says "lets start a task", "new task",
"start", or anything indicating they want to begin a Marlin V3 task), guide them
through the COMPLETE workflow from Phase 1 to Phase 8. At every step, clearly
mark what you handle automatically vs what they need to do. Never leave the user
wondering what to do next.

Initialize state:
```bash
bash automation/hfi_orchestrator.sh task-status
```

Print banner:

```
================================================================
  MARLIN V3 - FULL TASK WORKFLOW (v2)
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
  You can resume anytime by saying "resume" or "continue from where we left off"
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
Analyze repos using the repo analysis workflow (STEP 1). Present ranked results.

**[YOUR TURN]**
1. Select the recommended repo on Snorkel
2. Browse PRs, copy 3-5 PR URLs
3. Paste them here

**[AUTOMATION]** Analyze PRs using the PR analysis workflow (STEP 2). Present results.

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

**[AUTOMATION]** Run the prompt preparation workflow for the selected PR. Generate all fields:
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

### PHASE 3.5: CLAUDE.md CREATION (BEFORE LAUNCH)

**CRITICAL: CLAUDE.md must be created BEFORE launching HFI.**
Per official Snorkel training docs, the order is: setup -> CLAUDE.md -> launch.
This way both trajectories automatically see CLAUDE.md when HFI creates worktrees.

**[AUTOMATION]**
```bash
bash automation/hfi_orchestrator.sh claude-md <repo-path>
```

**[YOUR TURN]**
```
CLAUDE.md template generated at: <repo-path>/CLAUDE.md

1. Open and edit the file to accurately describe the repo
2. Must cover: overview, dev setup, test commands, conventions, architecture
3. DO NOT use claude-hfi to generate this
4. A good CLAUDE.md = good trajectories. Invest time here.
5. Type "claude-md ready" when done
```

**[AUTOMATION] Post-creation checks:**
```bash
# Check if repo .gitignore blocks CLAUDE.md
if grep -q 'CLAUDE.md' <repo-path>/.gitignore 2>/dev/null; then
  echo "WARNING: .gitignore contains CLAUDE.md entry!"
  echo "HFI trajectory windows will NOT see the file."
  echo "Fix: remove the CLAUDE.md line from .gitignore, commit, then re-create CLAUDE.md"
fi

# If project uses conda/virtualenv, set up CLAUDE_ENV_FILE
# echo 'conda activate myenv' > env-setup.sh
# export CLAUDE_ENV_FILE=./env-setup.sh
```

Save state: `save_task_step "CLAUDE_MD_DONE"`

---

### PHASE 3.7: LAUNCH HFI

**[AUTOMATION]**
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

  Say "automate the rest" or "take it from here" and I will:
    - Analyze diffs and determine winners
    - Generate all feedback text (using humanizing rules)
    - Fill HFI feedback forms automatically
    - Generate Turn 2/3 prompts and inject them
    - Run grounding verification on all claims before submitting
    - Produce Snorkel submission guidance at the end

  Your only action: final Snorkel web submission.
================================================================
```

Save state: `save_task_step "TURN1_DONE"`

---

### PHASES 5-7: TURNS 2-3 + EVALUATION + QUALITY (FULLY AUTOMATED)

The multi-turn automation handles everything from here:
- Captures diffs AND traces for each turn
- Runs `compare-diffs` for scope deviation and similarity analysis
- Performs grounding verification on all claims before writing feedback
- Generates all feedback text using WRITING STYLE RULES
- Fills HFI feedback forms automatically via `cmd_fill_feedback`
- Generates Turn 2/3 prompts, validates, injects, monitors
- Multi-turn happens within the same HFI session (no exit/relaunch needed)
- Produces final evaluation and pre-submit checks
- Logs all actions to the audit trail
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
  To start a new task, just say "lets start a new task"
================================================================
```

---

## RESUME FROM LAST STATE

When the user wants to resume (says "resume", "continue", "pick up where we left off",
or anything indicating they want to continue a previous task), read the task state
and resume from where they left off.

**[AUTOMATION]**
```bash
bash automation/hfi_orchestrator.sh task-status
```

Read `automation/data/task_state.json`. Based on `current_state`:

- `INITIALIZED` -> Start at Phase 1
- `PR_SELECTED` -> Go to Phase 2
- `PROMPT_APPROVED` -> Go to Phase 3 (setup)
- `SETUP_DONE` -> Go to Phase 3.5 (launch)
- `SETUP_DONE` -> Go to Phase 3.5 (CLAUDE.md creation)
- `CLAUDE_MD_DONE` -> Go to Phase 3.7 (Launch HFI)
- `LAUNCHED` -> Go to Phase 4 (Turn 1 inject)
- `TURN1_INJECTED` -> Monitor Turn 1
- `TURN1_DONE` -> Start multi-turn automation
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
| Claude.md source | "I created the CLAUDE.md file in the repo before launching the HFI tool. Both models had access to it from the start of the session." |
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
**Phase 5:** Each follow-up targets a DIFFERENT specific gap. Run grounding verification before every feedback submission.
**Phase 6:** Evaluative Solution Quality/Agency/Communication with "because". Key-axis required (dont default to correctness). Never use N/A.
**Phase 7:** Run Submission Checker on Snorkel before final submit.
**Phase 8:** IRREVERSIBLE. Triple-check everything.
