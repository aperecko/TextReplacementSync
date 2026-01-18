import SwiftUI
import Combine
import UniformTypeIdentifiers
import AppKit

struct TextReplacement: Codable, Identifiable {
    var id = UUID()
    let shortcut: String
    let phrase: String
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case shortcut, phrase, timestamp
    }
}

struct ReplacementExport: Codable {
    let exportDate: Date
    let replacements: [TextReplacement]
    let version: String
}

class TextReplacementManager: ObservableObject {
    @Published var replacements: [TextReplacement] = []
    @Published var status: String = "Ready"
    @Published var lastExportTime: Date?
    @Published var autoExportEnabled: Bool = false
    @Published var exportPath: String = ""
    
    private var timer: Timer?
    
    init() {
        loadExportPath()
        loadReplacements()
    }
    
    func loadExportPath() {
        let defaults = UserDefaults.standard
        if let saved = defaults.string(forKey: "exportPath") {
            exportPath = saved
        } else {
            // Default to iCloud Drive
            let homeDir = FileManager.default.homeDirectoryForCurrentUser
            exportPath = homeDir
                .appendingPathComponent("Library/Mobile Documents/com~apple~CloudDocs")
                .appendingPathComponent("text-replacements.json")
                .path
            defaults.set(exportPath, forKey: "exportPath")
        }
        
        autoExportEnabled = defaults.bool(forKey: "autoExportEnabled")
        if autoExportEnabled {
            startAutoExport()
        }
    }
    
    func saveExportPath() {
        let defaults = UserDefaults.standard
        defaults.set(exportPath, forKey: "exportPath")
        defaults.set(autoExportEnabled, forKey: "autoExportEnabled")
    }

    func openExportLocationInFinder() {
        let fileURL = URL(fileURLWithPath: exportPath)
        let folderURL = fileURL.deletingLastPathComponent()

        // If the file exists, reveal it in Finder. Otherwise, open the folder.
        if FileManager.default.fileExists(atPath: fileURL.path) {
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        } else {
            NSWorkspace.shared.open(folderURL)
        }
    }
    
    func loadReplacements() {
        replacements.removeAll()
        
        if let items = UserDefaults.standard.array(forKey: "NSUserDictionaryReplacementItems") as? [[String: Any]] {
            for item in items {
                if let shortcut = item["replace"] as? String,
                   let phrase = item["with"] as? String {
                    let replacement = TextReplacement(
                        shortcut: shortcut,
                        phrase: phrase,
                        timestamp: Date()
                    )
                    replacements.append(replacement)
                }
            }
        }
        
        status = "Found \(replacements.count) replacements"
    }
    
    func exportToJSON() {
        let export = ReplacementExport(
            exportDate: Date(),
            replacements: replacements,
            version: "1.0"
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let jsonData = try encoder.encode(export)
            let url = URL(fileURLWithPath: exportPath)
            
            // Create directory if it doesn't exist
            let directory = url.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            
            try jsonData.write(to: url)
            status = "✅ Exported \(replacements.count) replacements"
            lastExportTime = Date()
        } catch {
            status = "❌ Error: \(error.localizedDescription)"
        }
    }
    
    func startAutoExport() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.loadReplacements()
            self?.exportToJSON()
        }
    }
    
    func stopAutoExport() {
        timer?.invalidate()
        timer = nil
    }
    
    func toggleAutoExport() {
        autoExportEnabled.toggle()
        saveExportPath()
        
        if autoExportEnabled {
            startAutoExport()
            status = "Auto-export enabled (every 5 minutes)"
        } else {
            stopAutoExport()
            status = "Auto-export disabled"
        }
    }
}

struct ContentView: View {
    @StateObject private var manager = TextReplacementManager()
    @State private var showingFilePicker = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "text.badge.checkmark")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("Text Replacement Sync")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(manager.status)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top)
            
            Divider()
            
            // Replacements List
            VStack(alignment: .leading, spacing: 10) {
                Text("Text Replacements (\(manager.replacements.count))")
                    .font(.headline)
                
                if manager.replacements.isEmpty {
                    Text("No text replacements found")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(manager.replacements.prefix(10)) { replacement in
                                HStack {
                                    Text(replacement.shortcut)
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(.blue)
                                        .frame(width: 100, alignment: .leading)
                                    
                                    Image(systemName: "arrow.right")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                    
                                    Text(replacement.phrase)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(4)
                            }
                            
                            if manager.replacements.count > 10 {
                                Text("... and \(manager.replacements.count - 10) more")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                            }
                        }
                    }
                    .frame(height: 200)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
            
            // Export Path
            VStack(alignment: .leading, spacing: 8) {
                Text("Export Location")
                    .font(.headline)
                
                HStack {
                    Text(manager.exportPath)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    HStack(spacing: 8) {
                        Button("Change...") {
                            selectExportPath()
                        }
                        .buttonStyle(.borderless)

                        Button("Open") {
                            manager.openExportLocationInFinder()
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
            
            if let lastExport = manager.lastExportTime {
                Text("Last export: \(lastExport.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Action Buttons
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button(action: {
                        manager.loadReplacements()
                    }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    
                    Button(action: {
                        manager.loadReplacements()
                        manager.exportToJSON()
                    }) {
                        Label("Export Now", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                Toggle(isOn: Binding(
                    get: { manager.autoExportEnabled },
                    set: { _ in manager.toggleAutoExport() }
                )) {
                    Label("Auto-export every 5 minutes", systemImage: "clock.arrow.circlepath")
                }
                .toggleStyle(.switch)
            }
            .padding(.bottom)
        }
        .padding()
        .frame(width: 500, height: 600)
    }
    
    func selectExportPath() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.json]
        panel.nameFieldStringValue = "text-replacements.json"
        panel.message = "Choose export location"
        panel.canCreateDirectories = true
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                manager.exportPath = url.path
                manager.saveExportPath()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
