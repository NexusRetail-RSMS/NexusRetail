#!/usr/bin/env python3
"""
localize_app.py

Scans a SwiftUI project for user-facing strings, translates them into
Hindi, French, Arabic, and Spanish, and writes/updates a
Localizable.xcstrings (Apple's String Catalog format) so Xcode picks
the translations up automatically.

------------------------------------------------------------------
WHAT IT SCANS FOR
------------------------------------------------------------------
- Text("Some string")
- Text("Some string", comment: "...")
- NSLocalizedString("Some string", comment: "...")
- String(localized: "Some string")
- .navigationTitle("Some string")
- Button("Some string") { ... }
- Label("Some string", systemImage: "...")
- .alert("Some string")
- placeholder: Text("Some string")

It does NOT blindly grab every quoted string — it only matches strings
that appear as the first literal argument to the SwiftUI / Foundation
APIs listed above, then filters out obvious non-UI strings (SF Symbol
names, asset names, URLs, empty strings, etc.).

------------------------------------------------------------------
USAGE
------------------------------------------------------------------
1. Install dependency (one-time):
       pip install deep-translator --break-system-packages

2. Extract candidate strings from your project:
       python3 localize_app.py extract \
           --project /path/to/NexusRetail/NexusRetail

   -> writes strings_to_translate.json in the current directory.

3. (Optional) Review strings_to_translate.json and remove any false
   positives (SF Symbol names or asset IDs that slipped through).

4. Translate + generate / merge the String Catalog:
       python3 localize_app.py translate \
           --input  strings_to_translate.json \
           --output /path/to/NexusRetail/NexusRetail/Localizable.xcstrings

   -> Writes / updates Localizable.xcstrings in-place.
      Existing translations are NEVER overwritten (safe to re-run).

5. Xcode picks up the updated catalog automatically on the next build.

------------------------------------------------------------------
NOTE ON MERGING
------------------------------------------------------------------
If Localizable.xcstrings already exists at --output, this script loads
it and only ADDS new keys / fills in missing language entries.  It will
NOT overwrite strings you have already translated by hand, so it is
safe to re-run any time you add new Text(...) calls to the app.

------------------------------------------------------------------
TRANSLATION ENGINE
------------------------------------------------------------------
Uses the free Google Translate endpoint via deep-translator.
  - Auto-throttles with a small delay to respect the free quota.
  - For production: have a native speaker review the output. Machine
    translation of UI strings frequently gets context, tone, or gender
    agreement wrong.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import time
from pathlib import Path

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

# Target languages: ISO-639-1 code -> display name
LANGUAGES: dict[str, str] = {
    "hi": "Hindi",
    "fr": "French",
    "ar": "Arabic",
    "es": "Spanish",
}

# Delay between translation API calls (seconds)
TRANSLATE_DELAY = 0.35

# ---------------------------------------------------------------------------
# Regex patterns — match the first string literal in each API call.
# Each pattern has exactly one capture group: the raw string content.
# ---------------------------------------------------------------------------

_RAW_PATTERNS: list[str] = [
    # SwiftUI views
    r'Text\(\s*"((?:[^"\\]|\\.)*)"',
    r'Button\(\s*"((?:[^"\\]|\\.)*)"',
    r'Label\(\s*"((?:[^"\\]|\\.)*)"',
    r'Toggle\(\s*"((?:[^"\\]|\\.)*)"',
    r'Section\(\s*"((?:[^"\\]|\\.)*)"',
    # Modifiers
    r'\.navigationTitle\(\s*"((?:[^"\\]|\\.)*)"',
    r'\.alert\(\s*"((?:[^"\\]|\\.)*)"',
    r'\.confirmationDialog\(\s*"((?:[^"\\]|\\.)*)"',
    # Placeholder shorthand
    r'placeholder:\s*Text\(\s*"((?:[^"\\]|\\.)*)"',
    # Foundation
    r'NSLocalizedString\(\s*"((?:[^"\\]|\\.)*)"',
    r'String\(\s*localized:\s*"((?:[^"\\]|\\.)*)"',
]

COMPILED_PATTERNS: list[re.Pattern] = [re.compile(p) for p in _RAW_PATTERNS]

# Strings matching these patterns are silently skipped (non-UI strings).
_SKIP_RAW: list[str] = [
    r"^\s*$",                # empty / whitespace-only
    r"^https?://",           # URLs
    r"^[a-z][a-z0-9_.]*$",  # SF Symbol names, asset IDs, identifiers
    r"^\d",                  # strings starting with a digit
]
_SKIP_COMPILED: list[re.Pattern] = [re.compile(p) for p in _SKIP_RAW]


def should_skip(s: str) -> bool:
    """Return True if s looks like a non-UI string that should not be translated."""
    if not s or not s.strip():
        return True
    for pat in _SKIP_COMPILED:
        if pat.match(s):
            return True
    return False


# ---------------------------------------------------------------------------
# Extraction
# ---------------------------------------------------------------------------


def extract_strings(project_dir: Path) -> dict[str, dict]:
    """Walk project_dir recursively and return a dict of candidate UI strings."""
    results: dict[str, dict] = {}

    swift_files = sorted(project_dir.rglob("*.swift"))
    if not swift_files:
        print(f"Warning: No .swift files found under: {project_dir}", file=sys.stderr)
        return results

    print(f"Scanning {len(swift_files)} .swift file(s) under {project_dir} ...")

    for swift_file in swift_files:
        try:
            text = swift_file.read_text(encoding="utf-8")
        except OSError as exc:
            print(f"  Warning: Skipping {swift_file} -- {exc}", file=sys.stderr)
            continue

        for pattern in COMPILED_PATTERNS:
            for match in pattern.finditer(text):
                raw = match.group(1)
                value: str = raw.replace('\\"', '"')
                if should_skip(value):
                    continue
                if value not in results:
                    results[value] = {
                        "source_file": str(swift_file.relative_to(project_dir)),
                        "value": value,
                    }

    return results


def cmd_extract(args: argparse.Namespace) -> None:
    project_dir = Path(args.project).resolve()
    if not project_dir.exists():
        print(f"Error: Project path does not exist: {project_dir}", file=sys.stderr)
        sys.exit(1)

    found = extract_strings(project_dir)
    out_path = Path(args.output)
    out_path.write_text(
        json.dumps(found, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    print(f"\nFound {len(found)} unique candidate string(s).")
    print(f"Written to: {out_path}")
    print(
        "\nReview this file before translating -- remove any false positives\n"
        "(e.g. SF Symbol names or asset IDs that slipped through)."
    )


# ---------------------------------------------------------------------------
# Catalog helpers
# ---------------------------------------------------------------------------


def load_existing_catalog(path: Path) -> dict:
    """Load an existing Localizable.xcstrings, or return a fresh skeleton."""
    if path.exists():
        try:
            catalog = json.loads(path.read_text(encoding="utf-8"))
            print(f"Loaded existing catalog: {path}  ({len(catalog.get('strings', {}))} keys)")
            return catalog
        except Exception as exc:
            print(
                f"Warning: Could not parse existing {path} ({exc}). Starting fresh.",
                file=sys.stderr,
            )
    return {
        "sourceLanguage": "en",
        "strings": {},
        "version": "1.0",
    }


def _string_unit(value: str, state: str = "translated") -> dict:
    return {"stringUnit": {"state": state, "value": value}}


# ---------------------------------------------------------------------------
# Translation
# ---------------------------------------------------------------------------


def translate_text(translator_cls, text: str, target_lang: str) -> str:
    translator = translator_cls(source="en", target=target_lang)
    return translator.translate(text)


def cmd_translate(args: argparse.Namespace) -> None:
    # 1. Import dependency
    try:
        from deep_translator import GoogleTranslator
    except ImportError:
        print(
            "Error: Missing dependency. Install it with:\n"
            "    pip install deep-translator --break-system-packages",
            file=sys.stderr,
        )
        sys.exit(1)

    # 2. Load extracted strings
    input_path = Path(args.input)
    if not input_path.exists():
        print(
            f"Error: Input file not found: {input_path}\n"
            "Run the 'extract' command first.",
            file=sys.stderr,
        )
        sys.exit(1)

    strings_to_translate: dict[str, dict] = json.loads(
        input_path.read_text(encoding="utf-8")
    )

    # 3. Load (or create) the catalog
    output_path = Path(args.output)
    catalog = load_existing_catalog(output_path)
    catalog.setdefault("strings", {})

    # 4. Iterate and translate
    total = len(strings_to_translate)
    translated_count = 0
    skipped_count = 0

    for i, (key, meta) in enumerate(strings_to_translate.items(), start=1):
        source_value: str = meta["value"]
        print(f"\n[{i}/{total}] {source_value!r}")

        entry = catalog["strings"].setdefault(
            key,
            {
                "extractionState": "manual",
                "localizations": {},
            },
        )
        entry.setdefault("localizations", {})

        # Always keep the English source present
        entry["localizations"].setdefault("en", _string_unit(source_value))

        for lang_code, lang_name in LANGUAGES.items():
            if lang_code in entry["localizations"]:
                print(f"  -> {lang_name}: already translated -- skipping")
                skipped_count += 1
                continue

            try:
                translated = translate_text(GoogleTranslator, source_value, lang_code)
            except Exception as exc:
                print(f"  FAILED {lang_name}: {exc}", file=sys.stderr)
                continue

            entry["localizations"][lang_code] = _string_unit(translated)
            print(f"  -> {lang_name}: {translated}")
            translated_count += 1
            time.sleep(TRANSLATE_DELAY)

    # 5. Write the catalog
    output_path.write_text(
        json.dumps(catalog, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    print(
        f"\nDone.\n"
        f"  New translations : {translated_count}\n"
        f"  Skipped (existing): {skipped_count}\n"
        f"  Catalog written to: {output_path}\n"
        "\nIMPORTANT: Have a native speaker review machine-translated strings "
        "before shipping to the App Store."
    )


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Extract and translate SwiftUI app strings into a Localizable.xcstrings catalog.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    sub = parser.add_subparsers(dest="command", required=True)

    # --- extract ---
    p_extract = sub.add_parser(
        "extract",
        help="Scan .swift files and extract user-facing UI strings.",
    )
    p_extract.add_argument(
        "--project",
        required=True,
        metavar="DIR",
        help="Path to your Xcode project source folder (scanned recursively).",
    )
    p_extract.add_argument(
        "--output",
        default="strings_to_translate.json",
        metavar="FILE",
        help="Where to write the extracted strings JSON. (default: strings_to_translate.json)",
    )
    p_extract.set_defaults(func=cmd_extract)

    # --- translate ---
    p_translate = sub.add_parser(
        "translate",
        help="Translate extracted strings and generate / merge a String Catalog.",
    )
    p_translate.add_argument(
        "--input",
        default="strings_to_translate.json",
        metavar="FILE",
        help="Extracted strings JSON produced by the 'extract' step.",
    )
    p_translate.add_argument(
        "--output",
        default="Localizable.xcstrings",
        metavar="FILE",
        help="Output .xcstrings file -- merged non-destructively if it already exists.",
    )
    p_translate.set_defaults(func=cmd_translate)

    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
