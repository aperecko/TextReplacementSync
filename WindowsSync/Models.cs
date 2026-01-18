using System.Text.Json.Serialization;

namespace TextReplacementSync
{
    public class TextReplacement
    {
        [JsonPropertyName("shortcut")]
        public string Shortcut { get; set; } = "";
        
        [JsonPropertyName("phrase")]
        public string Phrase { get; set; } = "";
        
        [JsonPropertyName("timestamp")]
        public DateTime Timestamp { get; set; }
    }

    public class ReplacementExport
    {
        [JsonPropertyName("exportDate")]
        public DateTime ExportDate { get; set; }
        
        [JsonPropertyName("replacements")]
        public List<TextReplacement> Replacements { get; set; } = new();
        
        [JsonPropertyName("version")]
        public string Version { get; set; } = "";
    }
}
