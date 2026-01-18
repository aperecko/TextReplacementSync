using System.Text.Json;

namespace TextReplacementSync
{
    public class FileWatcherService
    {
        private FileSystemWatcher? watcher;
        private DateTime lastProcessed = DateTime.MinValue;
        private readonly string jsonPath;
        private readonly string ahkScriptPath;
        private readonly Action<string> logCallback;

        public FileWatcherService(string jsonPath, string ahkScriptPath, Action<string> logCallback)
        {
            this.jsonPath = jsonPath;
            this.ahkScriptPath = ahkScriptPath;
            this.logCallback = logCallback;
        }

        public void Start()
        {
            string directory = Path.GetDirectoryName(jsonPath) ?? "";
            string fileName = Path.GetFileName(jsonPath);

            if (!Directory.Exists(directory))
            {
                Directory.CreateDirectory(directory);
            }

            // Initial sync if file exists
            if (File.Exists(jsonPath))
            {
                ProcessReplacements();
            }

            // Set up file watcher
            watcher = new FileSystemWatcher(directory, fileName)
            {
                NotifyFilter = NotifyFilters.LastWrite | NotifyFilters.Size
            };
            
            watcher.Changed += OnChanged;
            watcher.Created += OnChanged;
            watcher.EnableRaisingEvents = true;

            logCallback("✅ File watcher started");
        }

        public void Stop()
        {
            if (watcher != null)
            {
                watcher.EnableRaisingEvents = false;
                watcher.Dispose();
                watcher = null;
            }
        }

        private void OnChanged(object sender, FileSystemEventArgs e)
        {
            // Debounce - only process if at least 2 seconds have passed
            if ((DateTime.Now - lastProcessed).TotalSeconds < 2)
                return;

            lastProcessed = DateTime.Now;
            
            // Wait for file to be fully written
            Thread.Sleep(500);
            
            logCallback($"🔔 File changed: {Path.GetFileName(e.FullPath)}");
            ProcessReplacements();
        }

        private void ProcessReplacements()
        {
            try
            {
                string jsonContent = File.ReadAllText(jsonPath);
                var export = JsonSerializer.Deserialize<ReplacementExport>(jsonContent, 
                    new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

                if (export?.Replacements == null)
                {
                    logCallback("❌ Invalid JSON format");
                    return;
                }

                AutoHotkeyGenerator.GenerateScript(export.Replacements, ahkScriptPath);
                AutoHotkeyGenerator.RestartAutoHotkey(ahkScriptPath);
                
                logCallback($"✅ Synced {export.Replacements.Count} replacements at {DateTime.Now:HH:mm:ss}");
                logCallback($"   Export date: {export.ExportDate:yyyy-MM-dd HH:mm:ss}");
            }
            catch (Exception ex)
            {
                logCallback($"❌ Error: {ex.Message}");
            }
        }
    }
}
