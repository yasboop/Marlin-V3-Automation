#!/usr/bin/env python3
"""
MARLIN V3 -- Prompt Quality Validator

Checks a prompt against Marlin V3 quality rules and flags violations.
Can be run standalone or imported.

Usage:
    python3 prompt_validator.py "Your prompt text here"
    python3 prompt_validator.py --file path/to/prompt.txt

Checks:
    1. Em-dash detection (Unicode U+2014 and double-hyphen patterns)
    2. PR reference detection (#digits, pull/digits, "this PR", branch names)
    3. Role-based prompting detection ("you are a", "act as", etc.)
    4. Over-prescriptive pattern detection ("on line N", "change X to Y")
    5. LLM signature word detection ("leverage", "utilize", "delve", etc.)
    6. Word count check (target: 150-300 words)
    7. Sentence variety check
"""

import re
import sys


def check_em_dashes(text: str) -> list[str]:
    """Detect em-dash characters and patterns."""
    issues = []

    if "\u2014" in text:
        count = text.count("\u2014")
        positions = [i for i, c in enumerate(text) if c == "\u2014"]
        issues.append(f"Em-dash character (U+2014) found {count} time(s) at positions: {positions}")

    if "\u2013" in text:
        count = text.count("\u2013")
        issues.append(f"En-dash character (U+2013) found {count} time(s) - replace with regular hyphen")

    double_hyphens = re.findall(r'(?<!\w)--(?!\w)', text)
    if double_hyphens:
        issues.append(f"Double-hyphen ('--') found {len(double_hyphens)} time(s) - this is an LLM signature. Use commas, periods, or single hyphens instead")

    return issues


def check_pr_references(text: str) -> list[str]:
    """Detect references to PRs, branches, or PR numbers."""
    issues = []

    pr_number_pattern = re.findall(r'#\d{3,6}', text)
    if pr_number_pattern:
        issues.append(f"PR number references found: {pr_number_pattern}")

    pull_pattern = re.findall(r'pull/\d+', text, re.IGNORECASE)
    if pull_pattern:
        issues.append(f"Pull URL references found: {pull_pattern}")

    pr_label_pattern = re.findall(r'PR[\s-]?\d+', text, re.IGNORECASE)
    if pr_label_pattern:
        issues.append(f"PR label references found: {pr_label_pattern}")

    phrase_patterns = [
        (r'\bthis pr\b', "this pr"),
        (r'\bthe pr\b(?!\w)', "the pr"),
        (r'\bthis pull request\b', "this pull request"),
        (r'\bthe pull request\b', "the pull request"),
        (r'\bin the pr\b', "in the pr"),
        (r'\bfrom the pr\b', "from the pr"),
        (r'\bpr changes\b', "pr changes"),
        (r'\bpr description\b', "pr description"),
    ]
    text_lower = text.lower()
    for pattern, label in phrase_patterns:
        if re.search(pattern, text_lower):
            context = re.search(pattern, text_lower)
            start = max(0, context.start() - 10)
            end = min(len(text_lower), context.end() + 10)
            snippet = text_lower[start:end]
            if "project" not in snippet and "process" not in snippet and "program" not in snippet and "problem" not in snippet and "protocol" not in snippet and "property" not in snippet and "practice" not in snippet and "procedure" not in snippet:
                issues.append(f"PR phrase found: \"{label}\"")

    return issues


def check_role_prompting(text: str) -> list[str]:
    """Detect role-based prompting patterns."""
    issues = []

    patterns = [
        (r'(?i)you are a[n]?\s+(senior|expert|experienced|skilled|seasoned)', "Role assignment"),
        (r'(?i)act as a[n]?\s+(senior|expert|experienced|developer|engineer)', "Role assignment"),
        (r'(?i)imagine you are', "Role assignment"),
        (r'(?i)as a senior', "Role reference"),
        (r'(?i)as an expert', "Role reference"),
        (r'(?i)pretend you', "Role assignment"),
        (r'(?i)your role is', "Role assignment"),
        (r'(?i)you\'re a[n]?\s+(senior|expert)', "Role assignment"),
    ]

    for pattern, label in patterns:
        matches = re.findall(pattern, text)
        if matches:
            issues.append(f"{label}: pattern \"{pattern}\" matched")

    return issues


def check_over_prescriptive(text: str) -> list[str]:
    """Detect over-prescriptive instruction patterns.
    
    V3 guidance: describe the PROBLEM and what SUCCESS looks like.
    Do not hand-hold through every file, function, and design decision.
    Over-prescriptive prompts are a rejection reason.
    Target: 6-8 engineer-hours of complexity.
    """
    issues = []

    hard_patterns = [
        (r'(?i)on line \d+', "Line number reference"),
        (r'(?i)at line \d+', "Line number reference"),
        (r'(?i)line \d+ of', "Line number reference"),
        (r'(?i)step \d+:', "Numbered step-by-step instructions"),
    ]

    for pattern, label in hard_patterns:
        matches = re.findall(pattern, text)
        if matches:
            issues.append(f"{label}: \"{matches[0]}\"")

    file_ext_patterns = re.findall(
        r'(?i)(?:in|open|edit|modify|change|update)\s+\S+\.(?:py|rs|ts|js|go|java|cpp|c|rb|kt)\b',
        text
    )
    if len(file_ext_patterns) >= 4:
        issues.append(
            f"Found {len(file_ext_patterns)} file-specific instructions "
            f"(V3 says describe the problem, not which files to edit)"
        )

    rename_patterns = re.findall(
        r'(?i)\brename\s+\w+\s+to\s+\w+', text
    )
    change_patterns = re.findall(
        r'(?i)\bchange\s+(?:the\s+)?\w+\s+(?:field|method|function|variable|param|type)\s+(?:from|to)\b',
        text
    )
    exact_impl_count = len(rename_patterns) + len(change_patterns)
    if exact_impl_count >= 3:
        issues.append(
            f"Found {exact_impl_count} exact rename/change instructions. "
            f"V3 guidance: describe what success looks like, let the model "
            f"figure out implementation details"
        )

    type_sigs = re.findall(r'<[^>]*(?:\'[a-z]+|impl |dyn )[^>]*>', text)
    generic_sigs = re.findall(r'\w+<\w+(?:,\s*\w+)*>', text)
    if len(type_sigs) + len(generic_sigs) >= 4:
        issues.append(
            f"Found {len(type_sigs) + len(generic_sigs)} type signatures/generics. "
            f"Consider describing the desired behavior instead of exact types"
        )

    return issues


def check_llm_signature_words(text: str) -> list[str]:
    """Detect words commonly overused by LLMs."""
    issues = []

    signature_words = {
        "leverage": "use",
        "utilize": "use",
        "delve": "explore/examine",
        "tapestry": "remove",
        "multifaceted": "complex",
        "holistic": "complete/full",
        "synergy": "combination",
        "paradigm": "approach/model",
        "facilitate": "help/enable",
        "comprehensive": "complete/full",
        "robust": "strong/reliable",
        "seamless": "smooth",
        "cutting-edge": "modern/new",
        "state-of-the-art": "modern/current",
        "in conclusion": "remove",
        "it's worth noting": "remove",
        "it is important to note": "remove",
    }

    text_lower = text.lower()
    for word, replacement in signature_words.items():
        if word in text_lower:
            count = text_lower.count(word)
            issues.append(f"LLM signature word \"{word}\" found {count}x -- replace with \"{replacement}\"")

    return issues


def check_word_count(text: str) -> list[str]:
    """Check if word count is in the 150-300 target range."""
    issues = []
    words = text.split()
    count = len(words)

    if count < 100:
        issues.append(f"Word count: {count} -- too short (minimum ~150 for a substantive prompt)")
    elif count < 150:
        issues.append(f"Word count: {count} -- slightly short (target: 150-300 words)")
    elif count > 350:
        issues.append(f"Word count: {count} -- too long (target: 150-300 words, consider trimming)")
    elif count > 300:
        issues.append(f"Word count: {count} -- slightly long (target: 150-300 words)")

    return issues


def check_sentence_variety(text: str) -> list[str]:
    """Check for sentence length variety (sign of human writing)."""
    issues = []
    sentences = re.split(r'[.!?]+', text)
    sentences = [s.strip() for s in sentences if s.strip()]

    if len(sentences) < 3:
        return issues

    lengths = [len(s.split()) for s in sentences]
    avg = sum(lengths) / len(lengths)
    variance = sum((l - avg) ** 2 for l in lengths) / len(lengths)

    if variance < 4:
        issues.append(
            f"Low sentence length variance ({variance:.1f}) -- "
            f"all sentences are similar length (~{avg:.0f} words). "
            f"Mix short and long sentences for natural flow."
        )

    return issues


def validate_prompt(text: str) -> dict:
    """Run all checks and return results."""
    results = {
        "em_dashes": check_em_dashes(text),
        "pr_references": check_pr_references(text),
        "role_prompting": check_role_prompting(text),
        "over_prescriptive": check_over_prescriptive(text),
        "llm_signatures": check_llm_signature_words(text),
        "word_count": check_word_count(text),
        "sentence_variety": check_sentence_variety(text),
    }

    total_issues = sum(len(v) for v in results.values())
    results["total_issues"] = total_issues
    results["pass"] = total_issues == 0

    return results


def print_results(results: dict, text: str):
    """Print validation results in a readable format."""
    word_count = len(text.split())

    print(f"\n{'=' * 60}")
    print(f"  MARLIN V3 -- PROMPT QUALITY VALIDATOR")
    print(f"{'=' * 60}")
    print(f"  Word count: {word_count}")
    print(f"  Total issues: {results['total_issues']}")
    print(f"  Status: {'PASS' if results['pass'] else 'ISSUES FOUND'}")
    print(f"{'=' * 60}\n")

    checks = [
        ("Em-dashes", "em_dashes", "CRITICAL"),
        ("PR References", "pr_references", "CRITICAL"),
        ("Role-based Prompting", "role_prompting", "CRITICAL"),
        ("Over-prescriptive", "over_prescriptive", "WARNING"),
        ("LLM Signature Words", "llm_signatures", "WARNING"),
        ("Word Count", "word_count", "INFO"),
        ("Sentence Variety", "sentence_variety", "INFO"),
    ]

    for label, key, severity in checks:
        issues = results[key]
        if issues:
            print(f"  [{severity}] {label}:")
            for issue in issues:
                print(f"    - {issue}")
            print()
        else:
            print(f"  [OK] {label}")

    if results["pass"]:
        print(f"\n  All checks passed. Prompt is ready for submission.\n")
    else:
        critical = len(results["em_dashes"]) + len(results["pr_references"]) + len(results["role_prompting"])
        if critical > 0:
            print(f"\n  {critical} CRITICAL issue(s) found. Fix before submitting.\n")
        else:
            print(f"\n  Only non-critical issues found. Review and fix if possible.\n")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 prompt_validator.py \"Your prompt text\"")
        print("       python3 prompt_validator.py --file path/to/prompt.txt")
        sys.exit(1)

    if sys.argv[1] == "--file":
        if len(sys.argv) < 3:
            print("Error: --file requires a path argument")
            sys.exit(1)
        from pathlib import Path
        text = Path(sys.argv[2]).read_text()
    else:
        text = " ".join(sys.argv[1:])

    results = validate_prompt(text)
    print_results(results, text)
    sys.exit(0 if results["pass"] else 1)
