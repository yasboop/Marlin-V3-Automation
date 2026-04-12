# AI Text Humanizer

> These are the writing style rules that the automation applies to ALL
> generated text at every stage (prompts, feedback, evaluations,
> reflections, follow-up prompts). The playbook references these rules
> and enforces them automatically during text generation.
>
> This file can also be shared with others to copy-paste into any AI
> tool (ChatGPT, Claude, Cursor, etc.) for standalone use.

## THE PROMPT 

```
The main goal is to beat AI detection software for the text provided.

PRIMARY APPROACH:
Rephrase every sentence in the paragraph into 3 alternate options in
your head and choose the one that you think would be the least
characteristic to the signatures that an AI would leave and should
highly show the language that some professional Indian developer or
coder wrote all of it.

This is NOT about making it informal or casual. It should read exactly
like how PR descriptions, GitHub issues, and Jira tickets are written
by Indian coders, technically precise, but with the natural phrasing
patterns and word choices that are common in Indian developer English.
Keep all technical meaning and identifiers intact. The result should
be a high quality professional text.

Think deeply and properly about everything and take all the time you
need. We have to make sure that there is absolutely no AI detection
whatsoever. If you properly apply all the rules we will succeed.

Also make sure the LLM signatures like gaps, spacing, common LLM
words, etc you already dont use.

Include a lot of variety and uncommon words that AI would generally
not use and an Indian coder would highly use. Act mostly on the filler
words and make sure the intent, technical meaning, motive and integrity
are kept as it is. Only act on the words and phrases.

SECONDARY RULES:
- Occasional space before comma: ",both are sitting" -- about 1 in 4
- No trailing period on the last sentence
- No double hyphens (--) or single hyphens (-) ever. Use commas instead
- Run-on sentences with comma splices instead of always starting new ones
- No em-dashes ever

PHRASING PATTERNS TO USE:

- "as of now" instead of "currently"
- "right now" instead of "at present"
- Present continuous tense: "is mixing" not "couples",
  "ends up creating" not "produces", "are being reported"
  not "are reported"
- "whichever X you pick" instead of "every X"
- "whoever is calling" instead of "the caller"
- "X is all it needs" instead of "only needs X"
- "basically irrelevant" instead of "unnecessary"
- "the whole X" instead of "full X" or "entire X"
- "carrying X around" instead of "containing X"
- "those should go" instead of "can be removed"
- "without issues" instead of "successfully"
- "should just keep collecting" instead of "should accumulate"
- "at that point" / "over there" / "from there" as spatial refs
- "for diagnostics purpose" -- add "purpose" or "part" after
  technical nouns
- "For X" to open a sentence about a topic: "For the trait solver",
  "For the opaque type path"
- "itself" for emphasis: "not the engine itself"
- "ends up" / "it ends up creating" instead of "produces"
- Simpler verbs: "give" not "emit", "controlling" not "governs",
  "keep collecting" not "accumulate", "holding" not "containing",
  "packed together with" not "bundled with"
- Simpler adjectives: "not needed anymore" not "unnecessary",
  "spot" not "point", "the fix" not "the solution"
- Natural fillers: "basically", "just", "actually" placed where
  a real person would put them. "should just keep collecting",
  "just a Span", "basically irrelevant"
- Natural elaboration: "both are sitting in the same path",
  "thats where callers actually need it" -- add small clauses
  that a person would naturally say
- No imperative commands: instead of "Refactor X", write
  "X needs to work with..." or "For X ,switch the input..."
  Instead of "Push X out" write "X should move outward"
  Instead of "Clean up X" write "X that are not needed ,those
  should go"


STRUCTURE FIXES (apply on top of phrasing):

- Never write "currently X but should Y". Just state the new state:
  "has X right now, switch to Y"
- Never start sentences with "This couples...", "This ensures..."
- Drop "The" before technical nouns when natural: "Solver only uses"
- Use sentence fragments: "Same for register_hidden_type."
  "Span in, goals out." AI never writes fragments
- Drop filler qualifiers: remove "only", "effectively", "essentially"
  when they dont change meaning
- Use "/" for paired concepts: "ScalarPair/Immediate"
- Vary openers on consecutive items -- never start 3 in a row the
  same way

Apply all of the above to any text I give you. Keep all technical
content and identifiers intact. The output should read like a real
Indian developer typed it in a GitHub issue.

here is the text -
```

---

