using System.Text.Json;

namespace TextReplacementSync
{
    public partial class MainForm : Form
    {
        private FileWatcherService? watcherService;
        private NotifyIcon? trayIcon;
        private string jsonPath = "";
        private string ahkScriptPath = "";
        private bool isRunning = false;

        public MainForm()
        {
            InitializeComponent();
            InitializePaths();
            SetupTrayIcon();
            LoadSettings();
        }

        private void InitializeComponent()
        {
            this.Text = "Text Replacement Sync";
            this.Size = new Size(600, 500);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.FormBorderStyle = FormBorderStyle.FixedSingle;
            this.MaximizeBox = false;

            // Header
            var headerLabel = new Label
            {
                Text = "Text Replacement Sync for Windows",
                Font = new Font("Segoe UI", 16, FontStyle.Bold),
                Location = new Point(20, 20),
                Size = new Size(560, 35),
                TextAlign = ContentAlignment.MiddleCenter
            };
            this.Controls.Add(headerLabel);

            var subtitleLabel = new Label
            {
                Text = "Syncs macOS text replacements to AutoHotkey",
                Font = new Font("Segoe UI", 10),
                Location = new Point(20, 55),
                Size = new Size(560, 25),
                TextAlign = ContentAlignment.MiddleCenter,
                ForeColor = Color.Gray
            };
            this.Controls.Add(subtitleLabel);

            // JSON Path Group
            var jsonGroupBox = new GroupBox
            {
                Text = "iCloud JSON File",
                Location = new Point(20, 100),
                Size = new Size(560, 80)
            };

            var jsonPathTextBox = new TextBox
            {
                Name = "jsonPathTextBox",
                Location = new Point(15, 30),
                Size = new Size(420, 25),
                ReadOnly = true
            };
            jsonGroupBox.Controls.Add(jsonPathTextBox);

            var jsonBrowseButton = new Button
            {
                Text = "Browse...",
                Location = new Point(445, 28),
                Size = new Size(90, 28)
            };
            jsonBrowseButton.Click += BrowseJsonFile;
            jsonGroupBox.Controls.Add(jsonBrowseButton);

            this.Controls.Add(jsonGroupBox);

            // AutoHotkey Path Group
            var ahkGroupBox = new GroupBox
            {
                Text = "AutoHotkey Script Output",
                Location = new Point(20, 190),
                Size = new Size(560, 80)
            };

            var ahkPathTextBox = new TextBox
            {
                Name = "ahkPathTextBox",
                Location = new Point(15, 30),
                Size = new Size(420, 25),
                ReadOnly = true
            };
            ahkGroupBox.Controls.Add(ahkPathTextBox);

            var ahkBrowseButton = new Button
            {
                Text = "Browse...",
                Location = new Point(445, 28),
                Size = new Size(90, 28)
            };
            ahkBrowseButton.Click += BrowseAhkFile;
            ahkGroupBox.Controls.Add(ahkBrowseButton);

            this.Controls.Add(ahkGroupBox);

            // Status Group
            var statusGroupBox = new GroupBox
            {
                Text = "Status",
                Location = new Point(20, 280),
                Size = new Size(560, 120)
            };

            var statusTextBox = new TextBox
            {
                Name = "statusTextBox",
                Location = new Point(15, 25),
                Size = new Size(530, 80),
                Multiline = true,
                ScrollBars = ScrollBars.Vertical,
                ReadOnly = true,
                BackColor = Color.White
            };
            statusGroupBox.Controls.Add(statusTextBox);

            this.Controls.Add(statusGroupBox);

            // Control Buttons
            var startButton = new Button
            {
                Name = "startButton",
                Text = "Start Watching",
                Location = new Point(20, 420),
                Size = new Size(150, 35),
                Font = new Font("Segoe UI", 10, FontStyle.Bold)
            };
            startButton.Click += StartWatching;
            this.Controls.Add(startButton);

            var stopButton = new Button
            {
                Name = "stopButton",
                Text = "Stop Watching",
                Location = new Point(180, 420),
                Size = new Size(150, 35),
                Font = new Font("Segoe UI", 10),
                Enabled = false
            };
            stopButton.Click += StopWatching;
            this.Controls.Add(stopButton);

            var minimizeButton = new Button
            {
                Text = "Minimize to Tray",
                Location = new Point(430, 420),
                Size = new Size(150, 35),
                Font = new Font("Segoe UI", 10)
            };
            minimizeButton.Click += (s, e) => MinimizeToTray();
            this.Controls.Add(minimizeButton);
        }

        private void InitializePaths()
        {
            string userProfile = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
            jsonPath = Path.Combine(userProfile, "iCloudDrive", "text-replacements.json");
            ahkScriptPath = Path.Combine(userProfile, "Documents", "TextReplacements.ahk");
        }

        private void LoadSettings()
        {
            var jsonTextBox = this.Controls.Find("jsonPathTextBox", true).FirstOrDefault() as TextBox;
            var ahkTextBox = this.Controls.Find("ahkPathTextBox", true).FirstOrDefault() as TextBox;

            if (jsonTextBox != null) jsonTextBox.Text = jsonPath;
            if (ahkTextBox != null) ahkTextBox.Text = ahkScriptPath;

            LogStatus("Ready. Configure paths and click 'Start Watching'.");
        }

        private void SetupTrayIcon()
        {
            trayIcon = new NotifyIcon
            {
                Icon = SystemIcons.Application,
                Visible = false,
                Text = "Text Replacement Sync"
            };

            var contextMenu = new ContextMenuStrip();
            contextMenu.Items.Add("Show", null, (s, e) => ShowForm());
            contextMenu.Items.Add("Exit", null, (s, e) => Application.Exit());
            trayIcon.ContextMenuStrip = contextMenu;
            trayIcon.DoubleClick += (s, e) => ShowForm();
        }

        private void BrowseJsonFile(object? sender, EventArgs e)
        {
            using var dialog = new OpenFileDialog
            {
                Title = "Select iCloud JSON File",
                Filter = "JSON Files (*.json)|*.json|All Files (*.*)|*.*",
                InitialDirectory = Path.GetDirectoryName(jsonPath)
            };

            if (dialog.ShowDialog() == DialogResult.OK)
            {
                jsonPath = dialog.FileName;
                var textBox = this.Controls.Find("jsonPathTextBox", true).FirstOrDefault() as TextBox;
                if (textBox != null) textBox.Text = jsonPath;
            }
        }

        private void BrowseAhkFile(object? sender, EventArgs e)
        {
            using var dialog = new SaveFileDialog
            {
                Title = "Select AutoHotkey Script Location",
                Filter = "AutoHotkey Scripts (*.ahk)|*.ahk|All Files (*.*)|*.*",
                InitialDirectory = Path.GetDirectoryName(ahkScriptPath),
                FileName = "TextReplacements.ahk"
            };

            if (dialog.ShowDialog() == DialogResult.OK)
            {
                ahkScriptPath = dialog.FileName;
                var textBox = this.Controls.Find("ahkPathTextBox", true).FirstOrDefault() as TextBox;
                if (textBox != null) textBox.Text = ahkScriptPath;
            }
        }

        private void StartWatching(object? sender, EventArgs e)
        {
            if (isRunning) return;

            if (!File.Exists(jsonPath))
            {
                MessageBox.Show("JSON file not found. Please check the path.", "Error", 
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
                return;
            }

            watcherService = new FileWatcherService(jsonPath, ahkScriptPath, LogStatus);
            watcherService.Start();
            isRunning = true;

            var startBtn = this.Controls.Find("startButton", true).FirstOrDefault() as Button;
            var stopBtn = this.Controls.Find("stopButton", true).FirstOrDefault() as Button;
            
            if (startBtn != null) startBtn.Enabled = false;
            if (stopBtn != null) stopBtn.Enabled = true;

            LogStatus("Watching for changes...");
        }

        private void StopWatching(object? sender, EventArgs e)
        {
            if (!isRunning) return;

            watcherService?.Stop();
            isRunning = false;

            var startBtn = this.Controls.Find("startButton", true).FirstOrDefault() as Button;
            var stopBtn = this.Controls.Find("stopButton", true).FirstOrDefault() as Button;
            
            if (startBtn != null) startBtn.Enabled = true;
            if (stopBtn != null) stopBtn.Enabled = false;

            LogStatus("Stopped watching.");
        }

        private void LogStatus(string message)
        {
            if (InvokeRequired)
            {
                Invoke(new Action<string>(LogStatus), message);
                return;
            }

            var statusTextBox = this.Controls.Find("statusTextBox", true).FirstOrDefault() as TextBox;
            if (statusTextBox != null)
            {
                statusTextBox.AppendText($"[{DateTime.Now:HH:mm:ss}] {message}\r\n");
            }
        }

        private void MinimizeToTray()
        {
            this.Hide();
            if (trayIcon != null)
            {
                trayIcon.Visible = true;
                trayIcon.ShowBalloonTip(2000, "Text Replacement Sync", 
                    "Application minimized to tray", ToolTipIcon.Info);
            }
        }

        private void ShowForm()
        {
            this.Show();
            this.WindowState = FormWindowState.Normal;
            this.Activate();
            if (trayIcon != null) trayIcon.Visible = false;
        }

        protected override void OnFormClosing(FormClosingEventArgs e)
        {
            if (e.CloseReason == CloseReason.UserClosing)
            {
                e.Cancel = true;
                MinimizeToTray();
            }
            else
            {
                watcherService?.Stop();
                trayIcon?.Dispose();
                base.OnFormClosing(e);
            }
        }
    }
}
