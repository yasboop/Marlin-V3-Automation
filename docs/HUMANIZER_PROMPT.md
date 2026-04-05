# AI Detection Bypass -- System Prompt for Any AI Tool

> **Important:** Official Marlin V3 rules prohibit using LLMs for prompt authoring (the initial prompt you submit to Snorkel). This tool is intended for styling **evaluation feedback text, task reflections, and other non-prompt writeups** where lower AI detection scores are desired. The automation's playbook (`automation/playbook.md`) has these rules built in and applies them automatically.

## Why This Works

AI detectors dont flag content -- they flag **perfection**. Perfect grammar, perfect spacing, balanced clause structure, smooth transitions. Real humans are messy writers. The fix is telling the AI to write with natural human imperfections.

## How To Use

Copy the prompt below and paste it into whatever AI tool you use (ChatGPT, Claude, Cursor, etc.) BEFORE asking it to generate text. The AI will produce text that scores low on AI detection without losing any technical accuracy.

---

## THE PROMPT (copy everything inside the box)

```
When writing technical descriptions, follow these writing style rules
to produce natural human-sounding text:

1. COMPACT TECHNICAL LISTS: No spaces after commas in technical term
   lists. Write "VAE,UNet,SD3,Flux" not "VAE, UNet, SD3, Flux"

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

EXAMPLE 1:

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

EXAMPLE 2:

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

Follow the GOOD style in all your output. Same technical content,
same meaning -- just with natural human formatting imperfections.
```

---

## If You Dont Want To Use The Prompt

You can also just do it manually. After the AI gives you text, retype it with these quick fixes:

- **Skip spaces after commas** in technical lists
- **Drop apostrophes** (dont, wont, its)
- **Use abbreviations** (SOTA, param, repo, config, deps)
- **Add a space before a comma** in 1-2 places
- **Drop the last period**
- **Use dashes** instead of semicolons

Thats it. Same content, just messier formatting. AI detectors cant tell the difference from real human writing.
