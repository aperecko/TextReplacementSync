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
        data := JSON.Parse(jsonText)
        
        ; Generate AutoHotkey script
        script := "; ============================================`n"
        script .= "; Auto-generated Text Replacements`n"
        script .= "; Generated: " FormatTime(, "yyyy-MM-dd HH:mm:ss") "`n"
        script .= "; Source: macOS Text Replacements`n"
        script .= "; Total: " data["replacements"].Length " shortcuts`n"
        script .= "; ============================================`n`n"
        
        script .= "#Requires AutoHotkey v2.0`n"
        script .= "#Hotstring EndChars -()[]{}:;'`"/\,.?!`n`s`t`n"
        script .= "#Hotstring O`n"  ; Omit ending character
        script .= "#SingleInstance Force`n`n"
        
        ; Add replacements
        count := 0
        for replacement in data["replacements"] {
            shortcut := replacement["shortcut"]
            phrase := EscapeForAHK(replacement["phrase"])
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

EscapeForAHK(text) {
    text := StrReplace(text, "``", "````")  ; Escape backtick
    text := StrReplace(text, "`n", "``n")   ; Line feed
    text := StrReplace(text, "`r", "")      ; Remove CR
    text := StrReplace(text, "`t", "``t")   ; Tab
    text := StrReplace(text, "`;", "```;")  ; Semicolon
    return text
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
