; =============================================================================
; Text Replacement Sync - Standalone AutoHotkey Version
; =============================================================================
; This script watches the iCloud JSON file and automatically updates
; text replacements without needing any .NET SDK or compilation.
;
; Requirements: AutoHotkey v2.0+ (download from autohotkey.com)
; =============================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; Configuration
global JsonPath := A_MyDocuments "\..\iCloudDrive\text-replacements.json"
global ReplacementsFile := A_MyDocuments "\TextReplacements.ahk"
global CheckInterval := 5000  ; Check every 5 seconds
global LastModified := ""
global TrayIcon := A_ScriptDir "\icon.ico"

; Setup System Tray
TraySetIcon(FileExist(TrayIcon) ? TrayIcon : A_WinDir "\System32\shell32.dll", 174)
A_IconTip := "Text Replacement Sync`nWatching for changes..."

; Create Tray Menu
A_TrayMenu.Delete()
A_TrayMenu.Add("Show Status", ShowStatus)
A_TrayMenu.Add("Sync Now", SyncNow)
A_TrayMenu.Add("Open JSON Location", OpenJsonLocation)
A_TrayMenu.Add("Open Script Location", OpenScriptLocation)
A_TrayMenu.Add()
A_TrayMenu.Add("Exit", ExitApp)
A_TrayMenu.Default := "Show Status"

; Initial sync
SyncNow()

; Start watching
SetTimer(CheckForChanges, CheckInterval)

ShowStatus(*) {
    if FileExist(JsonPath) {
        FileGetTime(modified, JsonPath, "M")
        status := "Status: Active`n"
        status .= "JSON File: " JsonPath "`n"
        status .= "Last Modified: " modified "`n"
        status .= "Output Script: " ReplacementsFile
    } else {
        status := "Status: Waiting for JSON file`n"
        status .= "Expected Location: " JsonPath "`n"
        status .= "`nMake sure iCloud Drive is syncing!"
    }
    MsgBox(status, "Text Replacement Sync", "Icon64 T5")
}

CheckForChanges() {
    if !FileExist(JsonPath)
        return
    
    FileGetTime(modified, JsonPath, "M")
    if (modified != LastModified) {
        LastModified := modified
        SyncNow()
    }
}

SyncNow(*) {
    if !FileExist(JsonPath) {
        TrayTip("JSON file not found!", "Check iCloud Drive sync", 1)
        return
    }
    
    try {
        ; Read JSON file
        jsonText := FileRead(JsonPath, "UTF-8")
        data := JSON.Parse(jsonText)
        
        ; Generate AutoHotkey script
        script := "; ============================================`n"
        script .= "; Auto-generated Text Replacements`n"
        script .= "; Generated: " FormatTime(, "yyyy-MM-dd HH:mm:ss") "`n"
        script .= "; Source: macOS Text Replacements`n"
        script .= "; Total: " data["replacements"].Length " shortcuts`n"
        script .= "; ============================================`n`n"
        
        script .= "#Requires AutoHotkey v2.0`n"
        script .= "#Hotstring EndChars -()[]{}:;'\"/\,.?!`n`s`t`n"
        script .= "#Hotstring O  ; Omit ending character`n"
        script .= "#SingleInstance Force`n`n"
        
        ; Add replacements
        for replacement in data["replacements"] {
            shortcut := replacement["shortcut"]
            phrase := EscapeForAHK(replacement["phrase"])
            script .= "::" shortcut "::" phrase "`n"
        }
        
        script .= "`n; Notification`n"
        script .= "TrayTip('Text Replacements Active', '" data["replacements"].Length " shortcuts loaded', 1)`n"
        
        ; Write script file
        FileDelete(ReplacementsFile)
        FileAppend(script, ReplacementsFile, "UTF-8")
        
        ; Reload the replacements script
        ReloadReplacements()
        
        TrayTip("Synced!", data["replacements"].Length " text replacements updated", 2)
        
    } catch as err {
        TrayTip("Sync Error", err.Message, 3)
    }
}

EscapeForAHK(text) {
    text := StrReplace(text, "``", "````")  ; Escape backtick
    text := StrReplace(text, "`n", "``n")   ; Line feed
    text := StrReplace(text, "`r", "")      ; Remove CR
    text := StrReplace(text, "`t", "``t")   ; Tab
    text := StrReplace(text, "`;", "```;")  ; Semicolon
    return text
}

ReloadReplacements() {
    ; Close any existing replacements script
    DetectHiddenWindows(true)
    try {
        if WinExist("ahk_exe AutoHotkey64.exe ahk_class AutoHotkey") {
            WinClose("ahk_exe AutoHotkey64.exe ahk_pid " . ProcessExist("AutoHotkey64.exe"))
        }
    }
    
    ; Start new instance
    if FileExist(ReplacementsFile) {
        Run(ReplacementsFile)
    }
}

OpenJsonLocation(*) {
    if FileExist(JsonPath)
        Run('explorer.exe /select,"' JsonPath '"')
    else
        Run('explorer.exe "' A_MyDocuments '\..\iCloudDrive"')
}

OpenScriptLocation(*) {
    if FileExist(ReplacementsFile)
        Run('explorer.exe /select,"' ReplacementsFile '"')
    else
        Run('explorer.exe "' A_MyDocuments '"')
}

ExitApp(*) {
    ExitApp()
}

; =============================================================================
; JSON Parser for AutoHotkey v2
; =============================================================================
class JSON {
    static Parse(jsonStr) {
        jsonStr := Trim(jsonStr)
        if (SubStr(jsonStr, 1, 1) = "{")
            return JSON.ParseObject(jsonStr)
        else if (SubStr(jsonStr, 1, 1) = "[")
            return JSON.ParseArray(jsonStr)
        return ""
    }
    
    static ParseObject(str) {
        obj := Map()
        str := Trim(SubStr(str, 2, -1))  ; Remove { }
        
        Loop {
            if (str = "")
                break
            
            ; Parse key
            keyEnd := InStr(str, '"', , 2)
            key := SubStr(str, 2, keyEnd - 2)
            str := Trim(SubStr(str, keyEnd + 1))
            str := Trim(SubStr(str, InStr(str, ":") + 1))
            
            ; Parse value
            if (SubStr(str, 1, 1) = '"') {
                valueEnd := InStr(str, '"', , 2)
                value := SubStr(str, 2, valueEnd - 2)
                str := Trim(SubStr(str, valueEnd + 1))
            } else if (SubStr(str, 1, 1) = "{") {
                braceCount := 0
                Loop Parse str {
                    if (A_LoopField = "{")
                        braceCount++
                    else if (A_LoopField = "}")
                        braceCount--
                    if (braceCount = 0) {
                        value := JSON.ParseObject(SubStr(str, 1, A_Index))
                        str := Trim(SubStr(str, A_Index + 1))
                        break
                    }
                }
            } else if (SubStr(str, 1, 1) = "[") {
                bracketCount := 0
                Loop Parse str {
                    if (A_LoopField = "[")
                        bracketCount++
                    else if (A_LoopField = "]")
                        bracketCount--
                    if (bracketCount = 0) {
                        value := JSON.ParseArray(SubStr(str, 1, A_Index))
                        str := Trim(SubStr(str, A_Index + 1))
                        break
                    }
                }
            } else {
                commaPos := InStr(str, ",")
                bracePos := InStr(str, "}")
                valueEnd := (commaPos > 0 && commaPos < bracePos) ? commaPos - 1 : bracePos - 1
                value := Trim(SubStr(str, 1, valueEnd))
                str := Trim(SubStr(str, valueEnd + 1))
            }
            
            obj[key] := value
            
            if (SubStr(str, 1, 1) = ",")
                str := Trim(SubStr(str, 2))
            else
                break
        }
        
        return obj
    }
    
    static ParseArray(str) {
        arr := []
        str := Trim(SubStr(str, 2, -1))  ; Remove [ ]
        
        Loop {
            if (str = "")
                break
            
            if (SubStr(str, 1, 1) = "{") {
                braceCount := 0
                Loop Parse str {
                    if (A_LoopField = "{")
                        braceCount++
                    else if (A_LoopField = "}")
                        braceCount--
                    if (braceCount = 0) {
                        arr.Push(JSON.ParseObject(SubStr(str, 1, A_Index)))
                        str := Trim(SubStr(str, A_Index + 1))
                        break
                    }
                }
            } else {
                commaPos := InStr(str, ",")
                bracketPos := InStr(str, "]")
                valueEnd := (commaPos > 0 && commaPos < bracketPos) ? commaPos - 1 : bracketPos - 1
                value := Trim(SubStr(str, 1, valueEnd))
                arr.Push(value)
                str := Trim(SubStr(str, valueEnd + 1))
            }
            
            if (SubStr(str, 1, 1) = ",")
                str := Trim(SubStr(str, 2))
            else
                break
        }
        
        return arr
    }
}
