; =============================================================================
; Text Replacement Sync - One-Time Generator
; =============================================================================
; This script reads the JSON file ONCE and generates the AutoHotkey shortcuts
; Then exits. No background monitoring needed.
;
; Requirements: AutoHotkey v2.0+ (download from autohotkey.com)
; =============================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; Configuration
global JsonPath := A_ScriptDir "\text-replacements.json"
global ReplacementsFile := A_MyDocuments "\TextReplacements.ahk"

; Run once and exit
GenerateReplacements()
ExitApp

GenerateReplacements() {
    if !FileExist(JsonPath) {
        MsgBox("JSON file not found!`n`nExpected: " JsonPath "`n`nMake sure text-replacements.json is in the same folder as this script.", "Error", 16)
        return
    }
    
    try {
        ; Use PowerShell to parse JSON (works on all Windows versions)
        psCommand := "powershell -NoProfile -Command `"$json = Get-Content '" . JsonPath . "' -Raw -Encoding UTF8 | ConvertFrom-Json; $json.replacements | ForEach-Object { Write-Output ($_.shortcut + '|' + $_.phrase) }`""
        
        replacements := []
        shell := ComObject("WScript.Shell")
        exec := shell.Exec(psCommand)
        
        ; Read output
        output := exec.StdOut.ReadAll()
        
        ; Parse lines
        Loop Parse, output, "`n", "`r" {
            if (A_LoopField = "")
                continue
            
            parts := StrSplit(A_LoopField, "|", , 2)
            if (parts.Length >= 2) {
                replacement := {shortcut: parts[1], phrase: parts[2]}
                replacements.Push(replacement)
            }
        }
        
        if (replacements.Length = 0) {
            MsgBox("No replacements found in JSON file!", "Error", 16)
            return
        }
        
        ; Generate AutoHotkey script
        script := "; ============================================`n"
        script .= "; Auto-generated Text Replacements`n"
        script .= "; Generated: " FormatTime(, "yyyy-MM-dd HH:mm:ss") "`n"
        script .= "; Source: macOS Text Replacements`n"
        script .= "; Total: " replacements.Length " shortcuts`n"
        script .= "; ============================================`n`n"
        
        script .= "#Requires AutoHotkey v2.0`n"
        script .= "#Hotstring EndChars -()[]{}:;'`"/\,.?!`n`s`t`n"
        script .= "#Hotstring O`n"
        script .= "#SingleInstance Force`n`n"
        
        ; Add replacements
        for replacement in replacements {
            shortcut := replacement.shortcut
            phrase := replacement.phrase
            
            ; Escape for AutoHotkey
            phrase := EscapeForAHK(phrase)
            
            script .= "::" shortcut "::" phrase "`n"
        }
        
        script .= "`n; Notification`n"
        script .= "TrayTip('Text Replacements Active', '" replacements.Length " shortcuts loaded from Mac', 2)`n"
        
        ; Write script file
        if FileExist(ReplacementsFile)
            FileDelete(ReplacementsFile)
        FileAppend(script, ReplacementsFile, "UTF-8")
        
        ; Show success message
        MsgBox("✅ Success!`n`n" replacements.Length " text replacements generated`n`nOutput: " ReplacementsFile "`n`nThe shortcuts script will now start automatically.", "Text Replacement Sync", 64)
        
        ; Start the replacements script
        Run(ReplacementsFile)
        
    } catch as err {
        MsgBox("Error: " err.Message "`n`nLine: " err.Line, "Text Replacement Sync", 16)
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
