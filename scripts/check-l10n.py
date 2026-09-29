#!/usr/bin/env python3
"""Localization completeness check for Savely/Resources/Localizable.xcstrings.

Fails (exit 1) when:
  * a key that is not `extractionState: "stale"` has no es-419 value in the
    `translated` state (plain stringUnit, every plural/device variation, and
    every substitution variation all count), or
  * an es-419 value uses a different multiset of format-specifier types than
    the English source (`%1$@` counts as `%@`, `%#@name@` resolves to its
    substitution's specifier, `%%` is a literal).

Stdlib only, so it runs on any CI image: `python3 scripts/check-l10n.py`.
"""

import json
import re
import sys
from collections import Counter
from pathlib import Path

CATALOG = Path(__file__).resolve().parent.parent / "Savely" / "Resources" / "Localizable.xcstrings"
TARGET = "es-419"

# %%  |  %#@name@  |  %[n$][flags][width][.precision][length]conversion
TOKEN = re.compile(
    r"%%"
    r"|%#@(?P<sub>\w+)@"
    r"|%(?:\d+\$)?[-+ #0']*(?:\d+|\*)?(?:\.(?:\d+|\*))?"
    r"(?P<len>hh|h|ll|l|q|L|z|t|j)?(?P<conv>[@dDiuUxXoOfFeEgGcCsSpaA])"
)


def specifiers(text, substitutions=None):
    """Multiset of specifier types in `text`, e.g. Counter({'lld': 1, '@': 2})."""
    found = Counter()
    for match in TOKEN.finditer(text):
        if match.group(0) == "%%":
            continue
        if match.group("sub"):
            sub = (substitutions or {}).get(match.group("sub"))
            spec = sub.get("formatSpecifier") if sub else None
            found[spec or "?" + match.group("sub")] += 1
            continue
        found[(match.group("len") or "") + match.group("conv")] += 1
    return found


def leaves(node):
    """Yield every stringUnit under a localization (plain or variations)."""
    if "stringUnit" in node:
        yield node["stringUnit"]
    for kinds in node.get("variations", {}).values():
        for variant in kinds.values():
            yield from leaves(variant)


def english_source(key, entry):
    unit = entry.get("localizations", {}).get("en", {}).get("stringUnit")
    return unit["value"] if unit and "value" in unit else key


def check(catalog):
    problems = []
    for key, entry in catalog["strings"].items():
        if entry.get("extractionState") == "stale" or entry.get("shouldTranslate") is False:
            continue
        label = repr(key)
        loc = entry.get("localizations", {}).get(TARGET)
        if not loc:
            problems.append(f"{label}: no {TARGET} localization")
            continue

        units = list(leaves(loc))
        subs = loc.get("substitutions", {})
        for sub in subs.values():
            units.extend(leaves(sub))
        if not units:
            problems.append(f"{label}: {TARGET} has no stringUnit")
            continue
        untranslated = [u for u in units if u.get("state") != "translated"]
        if untranslated:
            problems.append(f"{label}: {TARGET} state is {untranslated[0].get('state')!r}, not 'translated'")
            continue

        expected = specifiers(english_source(key, entry))
        if "stringUnit" in loc:
            got = specifiers(loc["stringUnit"]["value"], subs)
            if got != expected:
                problems.append(
                    f"{label}: format specifiers differ — en {dict(expected)} vs {TARGET} {dict(got)}"
                )
        for kind, variants in loc.get("variations", {}).items():
            for name, variant in variants.items():
                for unit in leaves(variant):
                    got = specifiers(unit["value"], subs)
                    # A 'zero'/'one' form may spell the number out; it may not add specifiers.
                    ok = got == expected or (name in ("zero", "one") and not (got - expected))
                    if not ok:
                        problems.append(
                            f"{label} [{kind}.{name}]: format specifiers differ — "
                            f"en {dict(expected)} vs {TARGET} {dict(got)}"
                        )
        for name, sub in subs.items():
            for unit in leaves(sub):
                if specifiers(unit["value"].replace("%arg", "")):
                    problems.append(f"{label} [substitution {name}]: unexpected specifier in {unit['value']!r}")
    return problems


def main():
    try:
        catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        print(f"check-l10n: cannot read {CATALOG}: {error}", file=sys.stderr)
        return 2
    problems = check(catalog)
    total = sum(1 for e in catalog["strings"].values() if e.get("extractionState") != "stale")
    if problems:
        print(f"check-l10n: {len(problems)} problem(s) in {CATALOG.name}:", file=sys.stderr)
        for problem in problems:
            print(f"  - {problem}", file=sys.stderr)
        return 1
    print(f"check-l10n: OK — {total} keys, all translated to {TARGET} with matching format specifiers.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
