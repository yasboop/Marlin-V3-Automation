#!/usr/bin/env python3
"""
MARLIN V3 -- Submission Quality Validator

Validates a complete submission package (evaluation writeup + turn prompts)
against all known rejection reasons and quality criteria.

Usage:
    python3 eval_checker.py --eval data/evaluation_final.md
    python3 eval_checker.py --eval data/evaluation_final.md --prompts data/turn1_prompt.txt data/turn2_prompt.txt data/turn3_prompt.txt
    python3 eval_checker.py --eval data/evaluation_final.md --prompts-dir data/

Checks:
    1. Structural completeness (5 text fields, 11 axes, overall preference, turn record)
    2. Rating consistency (language vs magnitude, overall vs axis majority, prose vs rating)
    3. Content quality (evaluative Solution Quality/Agency/Communication, code references, justification depth)
    4. Cross-turn validation (prompt similarity, scope drift)
    5. Anti-rejection (PR refs, role prompting, em-dashes, LLM words, turn count)
"""

import re
import sys
from pathlib import Path
from collections import Counter

from prompt_validator import (
    check_em_dashes,
    check_pr_references,
    check_role_prompting,
    check_llm_signature_words,
)

# ---------------------------------------------------------------------------
# Rating definitions
# ---------------------------------------------------------------------------

RATING_PATTERN = re.compile(r'\b([AB][1-4])\b')

RATING_REQUIRED_LANGUAGE = {
    "A1": ["fails", "incorrect", "broken", "missing entirely", "does not work"],
    "B1": ["fails", "incorrect", "broken", "missing entirely", "does not work"],
    "A2": ["substantially better", "significantly better", "missing key", "major gap"],
    "B2": ["substantially better", "significantly better", "missing key", "major gap"],
    "A3": ["better structured", "tighter scope", "better overall", "more complete", "cleaner"],
    "B3": ["better structured", "tighter scope", "better overall", "more complete", "cleaner"],
    "A4": ["minor difference", "effectively equivalent", "comparable", "similar"],
    "B4": ["minor difference", "effectively equivalent", "comparable", "similar"],
}

EVALUATIVE_MARKERS = [
    "because", "which means", "critical for", "matters because",
    "this is important", "which prevents", "which avoids", "which ensures",
    "resulting in", "leading to", "this matters", "this helps",
    "which allows", "which enables", "impact on", "necessary for",
    "so that", "which is why", "the reason",
]

CODE_REF_PATTERN = re.compile(
    r'`[a-zA-Z_]\w*(?:\.\w+)*(?:\(\))?`'   # backtick-quoted identifiers
    r'|[a-zA-Z_]\w*\.[a-z]{1,4}\b'          # file.ext patterns
    r'|`[^`]{3,60}`'                          # any backtick-quoted reference
)

VAGUE_FOLLOWUP_PATTERNS = [
    r'(?i)\breview everything\b',
    r'(?i)\bmake sure .{0,20} works?\b',
    r'(?i)\bcheck for (?:any )?bugs?\b',
    r'(?i)\bplease (?:double[- ]?)?check\b',
    r'(?i)\bverify (?:the |that )?(?:everything|implementation)\b',
    r'(?i)\bensure (?:everything|the implementation)\b',
    r'(?i)\blook over\b',
]

# ---------------------------------------------------------------------------
# Section parsing
# ---------------------------------------------------------------------------

EXPECTED_SECTIONS = {
    "senior_expectations": [
        r'senior\s+engineer\s+expect',
        r'10\.1',
        r'ideal\s+baseline',
    ],
    "model_a_solution_quality": [
        r'model\s*a.*solution\s+quality',
        r'10\.2',
        r'trajectory\s*a.*solution',
        r'model\s*a\s+strength',
    ],
    "model_a_agency": [
        r'model\s*a.*agency',
        r'10\.3',
        r'trajectory\s*a.*agency',
    ],
    "model_a_communication": [
        r'model\s*a.*communication',
        r'10\.4',
        r'trajectory\s*a.*communication',
    ],
    "model_b_solution_quality": [
        r'model\s*b.*solution\s+quality',
        r'10\.5',
        r'trajectory\s*b.*solution',
        r'model\s*b\s+strength',
    ],
    "model_b_agency": [
        r'model\s*b.*agency',
        r'10\.6',
        r'trajectory\s*b.*agency',
    ],
    "model_b_communication": [
        r'model\s*b.*communication',
        r'10\.7',
        r'trajectory\s*b.*communication',
    ],
    "axis_ratings": [
        r'axis\s+rating',
        r'10\.8',
        r'6\.1\s+through\s+6\.11',
        r'6\.1.*6\.11',
    ],
    "overall_preference": [
        r'overall\s+preference',
        r'10\.9',
        r'overall\s+winner',
    ],
    "turn_prompts": [
        r'turn\s+prompt',
        r'10\.8',
        r'prompts?\s+record',
    ],
}


def find_section(text: str, patterns: list[str]) -> str | None:
    """Find a section in the evaluation text by header patterns."""
    lines = text.split('\n')
    for i, line in enumerate(lines):
        for pat in patterns:
            if re.search(pat, line, re.IGNORECASE):
                content_lines = []
                for j in range(i + 1, len(lines)):
                    if lines[j].startswith('#'):
                        break
                    content_lines.append(lines[j])
                return '\n'.join(content_lines).strip()
    return None


def extract_axis_ratings(text: str) -> list[tuple[int, str, str]]:
    """Extract (axis_number, rating, justification) tuples from axis section."""
    results = []
    lines = text.split('\n')
    current_num = 0

    for line in lines:
        num_match = re.search(r'(?:^|\b)(\d{1,2})[\.\):\s]', line)
        rating_match = RATING_PATTERN.search(line)

        if num_match:
            n = int(num_match.group(1))
            if 1 <= n <= 11:
                current_num = n

        if rating_match and current_num > 0:
            rating = rating_match.group(1)
            justification = line[rating_match.end():].strip(' -:,.')
            if not justification:
                idx = lines.index(line)
                if idx + 1 < len(lines):
                    justification = lines[idx + 1].strip()
            results.append((current_num, rating, justification))
            current_num = 0

    if not results:
        for line in lines:
            rating_match = RATING_PATTERN.search(line)
            if rating_match:
                rating = rating_match.group(1)
                justification = line[rating_match.end():].strip(' -:,.')
                results.append((len(results) + 1, rating, justification))

    return results


def extract_overall_rating(text: str) -> str | None:
    """Extract the overall preference rating from the section."""
    match = RATING_PATTERN.search(text)
    return match.group(1) if match else None


# ---------------------------------------------------------------------------
# Check functions
# ---------------------------------------------------------------------------

def check_structural_completeness(eval_text: str) -> list[dict]:
    """Check all required sections exist and are non-empty."""
    results = []

    for section_name, patterns in EXPECTED_SECTIONS.items():
        content = find_section(eval_text, patterns)
        label = section_name.replace('_', ' ').title()

        if content is None:
            results.append({
                "check": f"Section: {label}",
                "status": "FAIL",
                "severity": "CRITICAL",
                "message": f"Section not found. Add a header matching: {patterns[0]}",
            })
        elif len(content.strip()) < 20:
            results.append({
                "check": f"Section: {label}",
                "status": "FAIL",
                "severity": "CRITICAL",
                "message": f"Section is too short ({len(content.strip())} chars). Must have substantive content.",
            })
        else:
            results.append({
                "check": f"Section: {label}",
                "status": "PASS",
                "severity": "OK",
                "message": f"Present ({len(content.split())} words)",
            })

    axis_content = find_section(eval_text, EXPECTED_SECTIONS["axis_ratings"])
    if axis_content:
        axes = extract_axis_ratings(axis_content)
        if len(axes) < 11:
            results.append({
                "check": "Axis count",
                "status": "FAIL",
                "severity": "CRITICAL",
                "message": f"Only {len(axes)} of 11 axis ratings found. All 11 are required.",
            })
        else:
            results.append({
                "check": "Axis count",
                "status": "PASS",
                "severity": "OK",
                "message": "All 11 axis ratings present",
            })

    pref_content = find_section(eval_text, EXPECTED_SECTIONS["overall_preference"])
    if pref_content:
        rating = extract_overall_rating(pref_content)
        if not rating:
            results.append({
                "check": "Overall rating",
                "status": "FAIL",
                "severity": "CRITICAL",
                "message": "No rating (A1-B4) found in overall preference section.",
            })
        elif rating not in ("A4", "B4"):
            if not re.search(r'(?i)key[- ]?axis', pref_content):
                results.append({
                    "check": "Key-axis field",
                    "status": "FAIL",
                    "severity": "CRITICAL",
                    "message": f"Rating is {rating} (non-equivalent) but key-axis designation is missing.",
                })
            else:
                results.append({
                    "check": "Key-axis field",
                    "status": "PASS",
                    "severity": "OK",
                    "message": "Key-axis present for non-equivalent rating",
                })

    # Check for raw axis numbers in text (signals template usage)
    raw_axis_refs = re.findall(r'\b6\.(?:1[01]?|[2-9])\b', eval_text)
    if raw_axis_refs:
        results.append({
            "check": "Raw axis number references",
            "status": "FAIL",
            "severity": "CRITICAL",
            "message": f"Found raw axis numbers in text: {', '.join(set(raw_axis_refs))}. Use axis NAMES (Correctness, Code quality, Instruction adherence, etc.) instead. Raw numbers signal template usage and trigger rejection.",
        })

    return results


def check_rating_consistency(eval_text: str) -> list[dict]:
    """Check ratings use correct language and are internally consistent."""
    results = []

    axis_content = find_section(eval_text, EXPECTED_SECTIONS["axis_ratings"])
    if not axis_content:
        return results

    axes = extract_axis_ratings(axis_content)

    for num, rating, justification in axes:
        if not justification or len(justification.split()) < 5:
            results.append({
                "check": f"Axis {num} justification depth",
                "status": "WARN",
                "severity": "WARNING",
                "message": f"Axis {num} ({rating}): justification is too brief ({len(justification.split())} words). Minimum 15 words recommended.",
            })

        if rating in RATING_REQUIRED_LANGUAGE and justification:
            required = RATING_REQUIRED_LANGUAGE[rating]
            just_lower = justification.lower()
            has_required = any(phrase in just_lower for phrase in required)
            if not has_required:
                full_context = axis_content.lower()
                axis_block = re.search(
                    rf'(?:^|\n).*?\b{num}\b.*?(?=\n.*?\b(?:{num+1})\b|\Z)',
                    full_context, re.DOTALL
                )
                if axis_block:
                    has_required = any(phrase in axis_block.group() for phrase in required)

            if not has_required:
                results.append({
                    "check": f"Axis {num} language match",
                    "status": "WARN",
                    "severity": "WARNING",
                    "message": f"Axis {num} rated {rating} but justification does not use expected language. {rating} needs words like: {', '.join(required[:3])}",
                })

    # Check for blanket identical ratings (all axes same rating = lazy evaluation)
    if len(axes) >= 11:
        ratings_only = [r for _, r, _ in axes]
        unique_ratings = set(ratings_only)
        if len(unique_ratings) == 1:
            results.append({
                "check": "Blanket rating detection",
                "status": "FAIL",
                "severity": "CRITICAL",
                "message": f"All 11 axes rated identically ({ratings_only[0]}). This signals lazy/biased evaluation and will be rejected. Even when one trajectory clearly wins, individual axes should vary (e.g., the loser may still have good code quality or communication).",
            })
        elif len(unique_ratings) <= 2 and all(r in ('A1', 'A2') or r in ('B1', 'B2') for r in unique_ratings):
            results.append({
                "check": "Near-blanket rating detection",
                "status": "WARN",
                "severity": "WARNING",
                "message": f"Only {len(unique_ratings)} distinct ratings used across 11 axes ({', '.join(unique_ratings)}). Consider whether some axes genuinely warrant different ratings for a more balanced evaluation.",
            })

    # Check overall preference aligns with axis majority
    pref_content = find_section(eval_text, EXPECTED_SECTIONS["overall_preference"])
    if pref_content and axes:
        overall = extract_overall_rating(pref_content)
        if overall:
            a_count = sum(1 for _, r, _ in axes if r.startswith('A') and r != 'A4')
            b_count = sum(1 for _, r, _ in axes if r.startswith('B') and r != 'B4')

            if overall.startswith('A') and overall != 'A4' and b_count > a_count:
                results.append({
                    "check": "Overall vs axis alignment",
                    "status": "FAIL",
                    "severity": "CRITICAL",
                    "message": f"Overall is {overall} (favors A) but {b_count}/{len(axes)} axes favor B vs {a_count} for A. Ratings contradictory.",
                })
            elif overall.startswith('B') and overall != 'B4' and a_count > b_count:
                results.append({
                    "check": "Overall vs axis alignment",
                    "status": "FAIL",
                    "severity": "CRITICAL",
                    "message": f"Overall is {overall} (favors B) but {a_count}/{len(axes)} axes favor A vs {b_count} for B. Ratings contradictory.",
                })
            else:
                results.append({
                    "check": "Overall vs axis alignment",
                    "status": "PASS",
                    "severity": "OK",
                    "message": f"Overall {overall} aligns with axis majority (A:{a_count} B:{b_count} Tie:{len(axes)-a_count-b_count})",
                })

    return results


def check_content_quality(eval_text: str) -> list[dict]:
    """Check Solution Quality/Agency/Communication are evaluative, references are specific, justifications are deep."""
    results = []

    na_matches = re.findall(r'\bN/?A\b', eval_text)
    if na_matches:
        results.append({
            "check": "N/A usage",
            "status": "FAIL",
            "severity": "CRITICAL",
            "message": f"Found {len(na_matches)} instance(s) of 'N/A' in evaluation text. Never use N/A. Always provide a substantive answer even if a trajectory failed completely.",
        })

    for section_key in ["model_a_solution_quality", "model_b_solution_quality",
                        "model_a_agency", "model_b_agency",
                        "model_a_communication", "model_b_communication"]:
        content = find_section(eval_text, EXPECTED_SECTIONS[section_key])
        label = section_key.replace('_', ' ').title()
        if not content:
            continue

        has_evaluative = any(marker in content.lower() for marker in EVALUATIVE_MARKERS)
        if not has_evaluative:
            results.append({
                "check": f"{label}: evaluative depth",
                "status": "WARN",
                "severity": "WARNING",
                "message": f"{label} appears descriptive, not evaluative. Explain WHY things matter, not just WHAT was done. Use phrases like 'because', 'which means', 'critical for'.",
            })
        else:
            results.append({
                "check": f"{label}: evaluative depth",
                "status": "PASS",
                "severity": "OK",
                "message": "Contains evaluative language",
            })

    for section_key in ["model_a_solution_quality", "model_a_agency", "model_a_communication",
                        "model_b_solution_quality", "model_b_agency", "model_b_communication"]:
        content = find_section(eval_text, EXPECTED_SECTIONS[section_key])
        label = section_key.replace('_', ' ').title()
        if not content:
            continue

        refs = CODE_REF_PATTERN.findall(content)
        if len(refs) < 2:
            results.append({
                "check": f"{label}: code references",
                "status": "WARN",
                "severity": "WARNING",
                "message": f"{label} has only {len(refs)} code reference(s). Every claim should cite a specific file, function, or test.",
            })
        else:
            results.append({
                "check": f"{label}: code references",
                "status": "PASS",
                "severity": "OK",
                "message": f"{len(refs)} code references found",
            })

    axis_content = find_section(eval_text, EXPECTED_SECTIONS["axis_ratings"])
    if axis_content:
        axes = extract_axis_ratings(axis_content)
        short_count = sum(1 for _, _, j in axes if len(j.split()) < 15)
        if short_count > 3:
            results.append({
                "check": "Axis justification depth",
                "status": "WARN",
                "severity": "WARNING",
                "message": f"{short_count} of {len(axes)} axis justifications are under 15 words. Add more specific evidence.",
            })

    return results


def check_cross_turn(prompts: list[str]) -> list[dict]:
    """Check turn prompts are different from each other and meet quality bars."""
    results = []

    if len(prompts) < 3:
        results.append({
            "check": "Turn count",
            "status": "FAIL",
            "severity": "CRITICAL",
            "message": f"Only {len(prompts)} turn prompt(s) found. Minimum 3 meaningful turns required.",
        })
    else:
        results.append({
            "check": "Turn count",
            "status": "PASS",
            "severity": "OK",
            "message": f"{len(prompts)} turns recorded",
        })

    def word_overlap(a: str, b: str) -> float:
        words_a = set(a.lower().split())
        words_b = set(b.lower().split())
        if not words_a or not words_b:
            return 0.0
        intersection = words_a & words_b
        smaller = min(len(words_a), len(words_b))
        return len(intersection) / smaller if smaller > 0 else 0.0

    for i in range(len(prompts)):
        for j in range(i + 1, len(prompts)):
            overlap = word_overlap(prompts[i], prompts[j])
            if overlap > 0.7:
                results.append({
                    "check": f"Turn {i+1} vs Turn {j+1} similarity",
                    "status": "FAIL",
                    "severity": "CRITICAL",
                    "message": f"Turn {i+1} and Turn {j+1} are {overlap:.0%} similar. Follow-ups must request different things.",
                })
            elif overlap > 0.5:
                results.append({
                    "check": f"Turn {i+1} vs Turn {j+1} similarity",
                    "status": "WARN",
                    "severity": "WARNING",
                    "message": f"Turn {i+1} and Turn {j+1} share {overlap:.0%} of words. Ensure they target different issues.",
                })

    for i, prompt in enumerate(prompts[1:], start=2):
        for vague_pat in VAGUE_FOLLOWUP_PATTERNS:
            if re.search(vague_pat, prompt):
                match = re.search(vague_pat, prompt).group()
                results.append({
                    "check": f"Turn {i} specificity",
                    "status": "FAIL",
                    "severity": "CRITICAL",
                    "message": f"Turn {i} contains vague language: \"{match}\". Follow-ups must name a specific file+function+issue.",
                })
                break

    return results


def check_anti_rejection(eval_text: str, prompts: list[str]) -> list[dict]:
    """Run all anti-rejection checks across the full submission."""
    results = []
    all_text = eval_text + "\n" + "\n".join(prompts)

    em_issues = check_em_dashes(all_text)
    if em_issues:
        results.append({
            "check": "Em-dashes",
            "status": "FAIL",
            "severity": "CRITICAL",
            "message": f"Em/en-dashes found: {em_issues[0]}. Replace with '--' or commas.",
        })
    else:
        results.append({
            "check": "Em-dashes",
            "status": "PASS",
            "severity": "OK",
            "message": "No em-dashes found",
        })

    for i, prompt in enumerate(prompts):
        pr_issues = check_pr_references(prompt)
        if pr_issues:
            results.append({
                "check": f"Turn {i+1}: PR references",
                "status": "FAIL",
                "severity": "CRITICAL",
                "message": f"Turn {i+1} prompt references the PR: {pr_issues[0]}",
            })

        role_issues = check_role_prompting(prompt)
        if role_issues:
            results.append({
                "check": f"Turn {i+1}: Role prompting",
                "status": "FAIL",
                "severity": "CRITICAL",
                "message": f"Turn {i+1} has role-based prompting: {role_issues[0]}",
            })

    llm_issues = check_llm_signature_words(all_text)
    if llm_issues:
        results.append({
            "check": "LLM signature words",
            "status": "WARN",
            "severity": "WARNING",
            "message": f"{len(llm_issues)} LLM signature word(s) detected. Replace with simpler alternatives.",
        })
        for issue in llm_issues[:3]:
            results.append({
                "check": "LLM word detail",
                "status": "WARN",
                "severity": "WARNING",
                "message": f"  {issue}",
            })
    else:
        results.append({
            "check": "LLM signature words",
            "status": "PASS",
            "severity": "OK",
            "message": "No LLM signature words found",
        })

    return results


# ---------------------------------------------------------------------------
# Main validation
# ---------------------------------------------------------------------------

def validate_submission(eval_text: str, prompts: list[str] | None = None) -> dict:
    """Run all checks and return structured results."""
    if prompts is None:
        prompts = []

    # Try to extract prompts from eval text if not provided separately
    if not prompts:
        turn_section = find_section(eval_text, EXPECTED_SECTIONS["turn_prompts"])
        if turn_section:
            turn_blocks = re.split(r'(?i)turn\s*\d+\s*:', turn_section)
            prompts = [b.strip() for b in turn_blocks if b.strip()]

    all_results = []
    all_results.extend(check_structural_completeness(eval_text))
    all_results.extend(check_rating_consistency(eval_text))
    all_results.extend(check_content_quality(eval_text))
    all_results.extend(check_cross_turn(prompts))
    all_results.extend(check_anti_rejection(eval_text, prompts))

    fail_count = sum(1 for r in all_results if r["status"] == "FAIL")
    warn_count = sum(1 for r in all_results if r["status"] == "WARN")
    pass_count = sum(1 for r in all_results if r["status"] == "PASS")

    return {
        "results": all_results,
        "fail_count": fail_count,
        "warn_count": warn_count,
        "pass_count": pass_count,
        "submission_ready": fail_count == 0,
    }


def print_report(report: dict):
    """Print a structured pass/fail report."""
    print(f"\n{'=' * 64}")
    print(f"  MARLIN V3 -- SUBMISSION QUALITY VALIDATOR")
    print(f"{'=' * 64}")
    print(f"  PASS: {report['pass_count']}  |  WARN: {report['warn_count']}  |  FAIL: {report['fail_count']}")
    print(f"  Verdict: {'GO -- Submission ready' if report['submission_ready'] else 'NO-GO -- Fix issues before submitting'}")
    print(f"{'=' * 64}\n")

    for severity_group, label in [("CRITICAL", "CRITICAL FAILURES"), ("WARNING", "WARNINGS"), ("OK", "PASSED")]:
        items = [r for r in report["results"] if r["severity"] == severity_group]
        if not items:
            continue

        if severity_group == "OK":
            print(f"  --- {label} ({len(items)}) ---")
            for r in items:
                print(f"  [PASS] {r['check']}")
        elif severity_group == "CRITICAL":
            print(f"  --- {label} ({len(items)}) ---")
            for r in items:
                print(f"  [FAIL] {r['check']}")
                print(f"         {r['message']}")
        else:
            print(f"  --- {label} ({len(items)}) ---")
            for r in items:
                print(f"  [WARN] {r['check']}")
                print(f"         {r['message']}")
        print()

    if report["submission_ready"]:
        print("  All critical checks passed. Review warnings, then submit.\n")
    else:
        print(f"  {report['fail_count']} critical failure(s) must be fixed before submission.\n")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Marlin V3 Submission Quality Validator")
    parser.add_argument("--eval", required=True, help="Path to evaluation markdown file")
    parser.add_argument("--prompts", nargs="*", help="Paths to turn prompt files (turn1.txt turn2.txt turn3.txt)")
    parser.add_argument("--prompts-dir", help="Directory containing turn*_prompt*.txt files")
    args = parser.parse_args()

    eval_path = Path(args.eval)
    if not eval_path.exists():
        print(f"Error: {eval_path} not found")
        sys.exit(1)

    eval_text = eval_path.read_text()

    prompts = []
    if args.prompts:
        for p in args.prompts:
            pp = Path(p)
            if pp.exists():
                prompts.append(pp.read_text())
            else:
                print(f"Warning: prompt file {p} not found, skipping")
    elif args.prompts_dir:
        pdir = Path(args.prompts_dir)
        prompt_files = sorted(pdir.glob("turn*_prompt*.txt"))
        for pf in prompt_files:
            prompts.append(pf.read_text())

    report = validate_submission(eval_text, prompts if prompts else None)
    print_report(report)
    sys.exit(0 if report["submission_ready"] else 1)
