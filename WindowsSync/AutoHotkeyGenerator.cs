using System.Text;
using System.Text.Json;

namespace TextReplacementSync
{
    public class AutoHotkeyGenerator
    {
        public static void GenerateScript(List<TextReplacement> replacements, string outputPath)
        {
            var sb = new StringBuilder();
            sb.AppendLine("; ============================================");
            sb.AppendLine("; Auto-generated Text Replacements");
            sb.AppendLine($"; Generated: {DateTime.Now:yyyy-MM-dd HH:mm:ss}");
            sb.AppendLine($"; Total replacements: {replacements.Count}");
            sb.AppendLine("; ============================================");
            sb.AppendLine();
            sb.AppendLine("; Settings");
            sb.AppendLine("#Hotstring EndChars -()[]{}:;'\"/\\,.?!`n`s`t");
            sb.AppendLine("#Hotstring O  ; Omit the ending character");
            sb.AppendLine("#SingleInstance Force");
            sb.AppendLine();
            sb.AppendLine("; Replacements");
            sb.AppendLine();

            foreach (var replacement in replacements.OrderBy(r => r.Shortcut))
            {
                // Escape special AutoHotkey characters
                string phrase = EscapeForAutoHotkey(replacement.Phrase);
                sb.AppendLine($"::{replacement.Shortcut}::{phrase}");
            }
            
            sb.AppendLine();
            sb.AppendLine("; Show notification on load");
            sb.AppendLine($"TrayTip, Text Replacements Loaded, {replacements.Count} shortcuts active, 3");

            File.WriteAllText(outputPath, sb.ToString(), Encoding.UTF8);
        }

        private static string EscapeForAutoHotkey(string text)
        {
            return text
                .Replace("`", "``")      // Escape backtick
                .Replace(";", "`;")      // Escape semicolon
                .Replace("\n", "`n")     // Line feed
                .Replace("\r", "")       // Remove carriage return
                .Replace("\t", "`t")     // Tab
                .Replace("!", "{!}")     // Escape exclamation
                .Replace("^", "{^}")     // Escape caret
                .Replace("+", "{+}")     // Escape plus
                .Replace("#", "{#}");    // Escape hash
        }

        public static void RestartAutoHotkey(string scriptPath)
        {
            try
            {
                // Kill any running AutoHotkey processes with this script
                var processes = System.Diagnostics.Process.GetProcessesByName("AutoHotkey");
                foreach (var proc in processes)
                {
                    try
                    {
                        if (proc.MainModule?.FileName?.Contains("AutoHotkey") == true)
                        {
                            proc.Kill();
                            proc.WaitForExit(1000);
                        }
                    }
                    catch { }
                }

                // Start the new script
                if (File.Exists(scriptPath))
                {
                    System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo
                    {
                        FileName = scriptPath,
                        UseShellExecute = true
                    });
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error restarting AutoHotkey: {ex.Message}");
            }
        }
    }
}
