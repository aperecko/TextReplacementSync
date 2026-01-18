# Text Replacement Sync - Standalone Version

**No .NET SDK, No Visual Studio, No Compilation Required!**

Just AutoHotkey - that's it!

## Windows Setup (5 Minutes)

### Step 1: Install AutoHotkey v2

1. Download from: https://www.autohotkey.com/
2. Choose **AutoHotkey v2.0** (not v1.1)
3. Install with default settings

### Step 2: Install iCloud for Windows

1. Download from Microsoft Store or https://www.apple.com/icloud/
2. Sign in with your Apple ID
3. Enable **iCloud Drive**
4. Wait for initial sync to complete

### Step 3: Copy the Sync Script

1. Copy `TextReplacementSync.ahk` to your Windows computer
2. Double-click it to run
3. It will appear in your system tray (bottom-right)

### Step 4: Auto-Start with Windows

1. Press `Win + R`
2. Type: `shell:startup` and press Enter
3. Create a shortcut to `TextReplacementSync.ahk` in this folder
4. Done! It will start automatically when Windows boots

## How to Use

### Tray Menu Options:
- **Show Status** - See current sync status
- **Sync Now** - Force immediate sync
- **Open JSON Location** - Browse to iCloud file
- **Open Script Location** - Browse to generated script
- **Exit** - Stop the sync service

### The script will:
1. Watch `%USERPROFILE%\iCloudDrive\text-replacements.json`
2. Check for changes every 5 seconds
3. Auto-generate `%USERPROFILE%\Documents\TextReplacements.ahk`
4. Auto-reload your text replacements
5. Show notifications when synced

## Testing

1. **On Mac**: Add a text replacement (e.g., `hw` → `Hello World`)
2. **Mac exports** to iCloud Drive (every 5 minutes or manually)
3. **Windows detects** the change within 5 seconds
4. **Type `hw`** in any Windows app and press space
5. **Should expand** to "Hello World"

## File Locations

- **Sync Script**: Wherever you placed `TextReplacementSync.ahk`
- **JSON Source**: `%USERPROFILE%\iCloudDrive\text-replacements.json`
- **Generated Script**: `%USERPROFILE%\Documents\TextReplacements.ahk`

## Troubleshooting

**"JSON file not found"**
- Make sure iCloud Drive is installed and syncing
- Check if the path is: `C:\Users\YourName\iCloudDrive\`
- You can edit line 11 in the script to change the path

**No expansions working**
- Right-click tray icon → "Sync Now"
- Check if `Documents\TextReplacements.ahk` was created
- Try manually running that file

**Want different check interval?**
- Edit line 12: Change `5000` (5 seconds) to desired milliseconds
- Example: `10000` = 10 seconds, `30000` = 30 seconds

## Advantages of This Approach

✅ **No compilation needed** - just edit the .ahk file  
✅ **No .NET SDK required** - only AutoHotkey  
✅ **Easy to customize** - plain text script  
✅ **Lightweight** - runs in system tray  
✅ **Auto-updates** - checks every 5 seconds  
✅ **Built-in JSON parser** - no dependencies  

## Comparison

| Feature | C# App | AutoHotkey Script |
|---------|--------|-------------------|
| Requires .NET SDK | ✅ Yes | ❌ No |
| Requires Compilation | ✅ Yes | ❌ No |
| File Size | ~50MB | ~15KB |
| Easy to Edit | ❌ No | ✅ Yes |
| GUI | ✅ Full GUI | ❌ Tray only |
| Auto-start | Manual | Easy |

**Recommendation**: Use the AutoHotkey version! It's simpler and doesn't require any SDKs.
