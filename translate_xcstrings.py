import json
import time
import sys
from pathlib import Path
try:
    from deep_translator import GoogleTranslator
except ImportError:
    print("Install deep-translator first.")
    sys.exit(1)

LANGUAGES = {
    "hi": "Hindi",
    "fr": "French",
    "ar": "Arabic",
    "es": "Spanish",
}
TRANSLATE_DELAY = 0.35

def _string_unit(value: str, state: str = "translated") -> dict:
    return {"stringUnit": {"state": state, "value": value}}

def main():
    xcstrings_path = Path('NexusRetail/Localizable.xcstrings')
    data = json.loads(xcstrings_path.read_text(encoding='utf-8'))
    
    strings = data.get('strings', {})
    total = len(strings)
    translated_count = 0
    
    # We will iterate through all keys
    for i, (key, entry) in enumerate(strings.items(), 1):
        if key in ['•', '·', '🌍', ''] or key.startswith('%') or '\n' in key or '\\n' in key:
            continue  # skip weird keys
            
        print(f"[{i}/{total}] Checking {key!r}...")
        
        locs = entry.get('localizations', {})
        if 'en' not in locs:
            locs['en'] = _string_unit(key)
            
        for lang_code, lang_name in LANGUAGES.items():
            # Check if this language is translated and has a valid value
            has_translation = False
            if lang_code in locs:
                unit = locs[lang_code].get('stringUnit', {})
                if 'value' in unit and unit['value'].strip():
                    has_translation = True
                    
            if not has_translation:
                print(f"  -> Translating into {lang_name}...")
                try:
                    translated = GoogleTranslator(source="en", target=lang_code).translate(key)
                except Exception as e:
                    print(f"  FAILED: {e}")
                    continue
                    
                locs[lang_code] = _string_unit(translated)
                translated_count += 1
                time.sleep(TRANSLATE_DELAY)
                
        entry['localizations'] = locs
        
        # Save every 20 translations to avoid losing progress
        if translated_count > 0 and translated_count % 20 == 0:
            xcstrings_path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')
            
    # Final save
    xcstrings_path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding='utf-8')
    print(f"Done. Translated {translated_count} new strings.")

if __name__ == '__main__':
    main()
