# Text Replacement Sync - Windows App

Syncs macOS text replacements to Windows AutoHotkey via iCloud Drive.

## Prerequisites

1. **AutoHotkey** - Download from https://www.autohotkey.com/
2. **iCloud for Windows** - Download from Microsoft Store or Apple
3. **.NET 8 SDK** - Download from https://dotnet.microsoft.com/download

## Building the App

### Option 1: Using Visual Studio

1. Open `TextReplacementSync.csproj` in Visual Studio 2022
2. Build → Build Solution (or press F6)
3. Run the app (press F5)

### Option 2: Using Command Line

```cmd
cd C:\path\to\WindowsSync
dotnet build
dotnet run
```

### Option 3: Create Standalone Executable

```cmd
cd C:\path\to\WindowsSync
dotnet publish -c Release -r win-x64 --self-contained
```

The executable will be in: `bin\Release\net8.0-windows\win-x64\publish\TextReplacementSync.exe`

## Setup

1. **Launch the app**
2. **Configure paths**:
   - JSON Path: Should auto-detect `%USERPROFILE%\iCloudDrive\text-replacements.json`
   - AutoHotkey Script: Defaults to `%USERPROFILE%\Documents\TextReplacements.ahk`
3. **Click "Start Watching"**
4. **Minimize to tray** to keep it running in the background

## Auto-Start with Windows

1. Press `Win + R`, type `shell:startup`, press Enter
2. Create a shortcut to `TextReplacementSync.exe` in this folder
3. Also create a shortcut to `Documents\TextReplacements.ahk`

Both will now start when Windows boots!

## How It Works

1. Mac exports text replacements to iCloud Drive every 5 minutes
2. Windows app watches the JSON file for changes
3. When changed, generates new AutoHotkey script
4. Automatically restarts AutoHotkey to load new replacements
5. Your shortcuts now work on Windows!

## Testing

1. On Mac: Add a new text replacement (e.g., `test` → `This is a test`)
2. Wait for Mac to export (or manually export)
3. Windows app should detect change and sync
4. Type `test` followed by space in any Windows app
5. Should expand to "This is a test"

## Troubleshooting

**App won't start:**
- Make sure .NET 8 Runtime is installed
- Check if Visual C++ Redistributable is installed

**iCloud path not found:**
- Verify iCloud Drive is installed and syncing
- Check path: `%USERPROFILE%\iCloudDrive`
- Manually browse to the JSON file location

**AutoHotkey not working:**
- Make sure AutoHotkey is installed
- Check if script file was created in Documents folder
- Manually run the .ahk file to test

**Changes not syncing:**
- Verify Mac is exporting to iCloud Drive
- Check if iCloud is syncing (look for cloud icons on files)
- Manually trigger a change to test file watcher
