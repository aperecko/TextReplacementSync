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
        ; Read JSON file
        jsonText := FileRead(JsonPath, "UTF-8")
        
        ; Parse JSON using COM (JScript)
        data := ParseJSON(jsonText)
        
        ; Generate AutoHotkey script
        script := "; ============================================`n"
        script .= "; Auto-generated Text Replacements`n"
        script .= "; Generated: " FormatTime(, "yyyy-MM-dd HH:mm:ss") "`n"
        script .= "; Source: macOS Text Replacements`n"
        script .= "; ============================================`n`n"
        
        script .= "#Requires AutoHotkey v2.0`n"
        script .= "#Hotstring EndChars -()[]{}:;'`"/\,.?!`n`s`t`n"
        script .= "#Hotstring O`n"
        script .= "#SingleInstance Force`n`n"
        
        ; Add replacements
        count := 0
        for replacement in data.replacements {
            shortcut := replacement.shortcut
            phrase := replacement.phrase
            
            ; Unescape Unicode sequences
            phrase := UnescapeUnicode(phrase)
            
            ; Escape for AutoHotkey
            phrase := EscapeForAHK(phrase)
            
            script .= "::" shortcut "::" phrase "`n"
            count++
        }
        
        script .= "`n; Notification`n"
        script .= "TrayTip('Text Replacements Active', '" count " shortcuts loaded from Mac', 2)`n"
        
        ; Write script file
        if FileExist(ReplacementsFile)
            FileDelete(ReplacementsFile)
        FileAppend(script, ReplacementsFile, "UTF-8")
        
        ; Show success message
        MsgBox("✅ Success!`n`n" count " text replacements generated`n`nOutput: " ReplacementsFile "`n`nThe shortcuts script will now start automatically.", "Text Replacement Sync", 64)
        
        ; Start the replacements script
        Run(ReplacementsFile)
        
    } catch as err {
        MsgBox("Error: " err.Message, "Text Replacement Sync", 16)
    }
}

ParseJSON(json) {
    ; Use Windows JScript engine to parse JSON
    sc := ComObject("ScriptControl")
    sc.Language := "JScript"
    sc.ExecuteStatement("obj = " json)
    return sc.Eval("obj")
}

UnescapeUnicode(text) {
    ; Convert \Uxxxx format to actual Unicode characters
    while (pos := InStr(text, "\U")) {
        hexCode := SubStr(text, pos + 2, 8)
        if (StrLen(hexCode) >= 4) {
            charCode := "0x" SubStr(hexCode, 1, 8)
            try {
                char := Chr(Integer(charCode))
                text := SubStr(text, 1, pos - 1) char SubStr(text, pos + 10)
            } catch {
                break
            }
        } else {
            break
        }
    }
    return text
}

EscapeForAHK(text) {
    text := StrReplace(text, "``", "````")  ; Escape backtick
    text := StrReplace(text, "`n", "``n")   ; Line feed
    text := StrReplace(text, "`r", "")      ; Remove CR
    text := StrReplace(text, "`t", "``t")   ; Tab
    text := StrReplace(text, "`;", "```;")  ; Semicolon
    return text
}
