# Text Replacement Sync - Simple One-Time Setup

**No background processes! No monitoring! Just run once and you're done.**

## How It Works

1. **Mac**: Export your text replacements to JSON
2. **Copy**: Transfer to Windows
3. **Windows**: Run the script ONCE to generate shortcuts
4. **Done**: Shortcuts work forever (until you update them)

## Mac Setup (30 seconds)

### Export Your Text Replacements

```bash
cd /Users/test/Projects/TextReplacementSync
python3 export-to-windows.sh
```

This creates `WindowsSync/text-replacements.json` with all your Mac text replacements.

## Windows Setup (2 Minutes)

### Step 1: Copy the WindowsSync Folder

Copy the entire `WindowsSync` folder to your Windows PC anywhere you want:
- Desktop
- Documents  
- C:\TextReplacements\
- Literally anywhere!

Transfer methods:
- USB drive
- Email  
- Dropbox/OneDrive/Google Drive
- Network share

### Step 2: Install AutoHotkey v2

**PowerShell One-Liner (Run as Admin):**
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')); choco install autohotkey -y
```

**Or Manual Download:**
1. Go to https://www.autohotkey.com/
2. Download AutoHotkey v2.0
3. Install with default settings

### Step 3: Run the Generator Script

1. Navigate to your WindowsSync folder
2. **Double-click `TextReplacementSync.ahk`**
3. You'll see a success message
4. **Done!** The shortcuts are now active

The generator script:
- ✅ Reads the JSON file
- ✅ Creates `Documents\TextReplacements.ahk` with your shortcuts
- ✅ Starts the shortcuts script
- ✅ Exits (doesn't stay running)

### Step 4: Auto-Start the Shortcuts (Optional)

The shortcuts won't survive a reboot unless you add them to startup:

**PowerShell command:**
```powershell
$ahkScript = "$env:USERPROFILE\Documents\TextReplacements.ahk"; $WScriptShell = New-Object -ComObject WScript.Shell; $shortcut = $WScriptShell.CreateShortcut("$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\TextReplacements.lnk"); $shortcut.TargetPath = $ahkScript; $shortcut.Save()
```

**Or manually:**
1. Press `Win + R`, type `shell:startup`, press Enter
2. Create shortcut to `%USERPROFILE%\Documents\TextReplacements.ahk`

## Testing Your Shortcuts

1. Open Notepad or any text editor
2. Type one of your shortcuts (e.g., `ssresume`) and press **space**
3. It should expand to your full text!

Examples from your Mac:
- `ssresume` → "I'm working on SolidStack - read /Users/test/Projects/solidstack/context/QUICK-START.txt and start the session."
- `omw` → "On my way!"
- `chatg` → "chatGPT"
- `adr` → "237 Highland St"

## Updating Your Shortcuts

When you add/change text replacements on Mac:

### On Mac:
```bash
cd /Users/test/Projects/TextReplacementSync
python3 export-to-windows.sh
```

### On Windows:
1. Copy the new `text-replacements.json` to your WindowsSync folder
2. Double-click `TextReplacementSync.ahk` again
3. Your shortcuts are updated!

## File Structure

```
WindowsSync/
├── TextReplacementSync.ahk       ← Run this ONCE to generate shortcuts
├── text-replacements.json        ← Your Mac shortcuts (exported)
└── STANDALONE-README.md          ← This file

After running the generator:
%USERPROFILE%\Documents\
└── TextReplacements.ahk          ← The actual shortcuts (auto-generated)
```

## What's Different from Before?

**OLD VERSION (Complicated):**
- ❌ Runs constantly in background
- ❌ Checks for changes every 5 seconds  
- ❌ Uses system tray
- ❌ More complex

**NEW VERSION (Simple):**
- ✅ Run once and done
- ✅ No background processes
- ✅ No system tray icon
- ✅ Just generates the shortcuts file
- ✅ Shortcuts work immediately and forever

## Advantages

✅ **No background process** - doesn't use any system resources  
✅ **No monitoring** - run once and forget  
✅ **Simple** - just double-click when you need to update  
✅ **Portable** - works from anywhere on your PC  
✅ **No cloud sync needed** - simple file copy  
✅ **No compilation** - just AutoHotkey  

## Troubleshooting

**"JSON file not found"**
- Make sure `text-replacements.json` is in the same folder as `TextReplacementSync.ahk`

**Shortcuts not working**
- Check if `Documents\TextReplacements.ahk` was created
- Make sure AutoHotkey is running (look for green H icon in system tray)
- Try manually running `Documents\TextReplacements.ahk`

**Shortcuts stopped working after reboot**
- Add `TextReplacements.ahk` to Windows Startup (see Step 4 above)

**Want to see what shortcuts are active?**
- Right-click the green H icon in system tray
- Click "Open" to see the script

**Need to disable temporarily?**
- Right-click the green H icon in system tray  
- Click "Exit"
- Run `Documents\TextReplacements.ahk` again to re-enable

## Quick Reference

| Action | Command |
|--------|---------|
| Export from Mac | `python3 export-to-windows.sh` |
| Generate on Windows | Double-click `TextReplacementSync.ahk` |
| Active shortcuts file | `Documents\TextReplacements.ahk` |
| Add to startup | Create shortcut in `shell:startup` |

That's it! Simple and clean. 🎉
