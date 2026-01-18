#!/usr/bin/env python3
# =============================================================================
# Export macOS Text Replacements to JSON
# =============================================================================

import subprocess
import json
import plistlib
from datetime import datetime
import os

def get_text_replacements():
    """Get text replacements from macOS preferences"""
    try:
        # Try reading from UserDefaults
        result = subprocess.run(
            ['defaults', 'read', '-g', 'NSUserDictionaryReplacementItems'],
            capture_output=True,
            text=True,
            check=False
        )
        
        if result.returncode != 0:
            print("⚠️  No text replacements found in preferences")
            return []
        
        # Convert plist XML to dict
        plist_data = result.stdout.encode('utf-8')
        
        # Parse as plist
        try:
            items = plistlib.loads(plist_data)
        except:
            # If that fails, try using plutil
            temp_file = '/tmp/text-replacements.plist'
            with open(temp_file, 'w') as f:
                f.write(result.stdout)
            
            result2 = subprocess.run(
                ['plutil', '-convert', 'json', '-o', '-', temp_file],
                capture_output=True,
                text=True
            )
            items = json.loads(result2.stdout)
        
        replacements = []
        for item in items:
            if isinstance(item, dict):
                replacement = {
                    "shortcut": item.get("replace", ""),
                    "phrase": item.get("with", ""),
                    "timestamp": datetime.now().isoformat()
                }
                replacements.append(replacement)
        
        return replacements
        
    except Exception as e:
        print(f"❌ Error reading text replacements: {e}")
        return []

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_file = os.path.join(script_dir, "WindowsSync", "text-replacements.json")
    
    print("📝 Exporting macOS Text Replacements...")
    print()
    
    # Get replacements
    replacements = get_text_replacements()
    
    # Create export structure
    export = {
        "exportDate": datetime.now().isoformat(),
        "replacements": replacements,
        "version": "1.0"
    }
    
    # Ensure directory exists
    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    
    # Write JSON
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(export, f, indent=2, ensure_ascii=False)
    
    print(f"✅ Exported {len(replacements)} text replacements")
    print(f"📄 Output: {output_file}")
    print()
    
    # Show first few examples
    if replacements:
        print("Examples:")
        for r in replacements[:5]:
            print(f"  '{r['shortcut']}' → '{r['phrase']}'")
        if len(replacements) > 5:
            print(f"  ... and {len(replacements) - 5} more")
    
    print()
    print("Next steps:")
    print("1. Copy the entire WindowsSync folder to your Windows PC")
    print("2. Run TextReplacementSync.ahk on Windows")
    print("3. Your shortcuts will work!")

if __name__ == "__main__":
    main()
