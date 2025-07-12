import Foundation
import SwiftUI
import AVFoundation

@MainActor
class HistoryManager: ObservableObject {
    static let shared = HistoryManager()
    
    @Published var entries: [HistoryEntry] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let historyFileName = "history.json"
    private let audioDirectoryName = "Audio"
    
    private var historyDirectoryURL: URL {
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupportURL.appendingPathComponent("Dictaum").appendingPathComponent("History")
    }
    
    private var audioDirectoryURL: URL {
        return historyDirectoryURL.appendingPathComponent(audioDirectoryName)
    }
    
    private var historyFileURL: URL {
        return historyDirectoryURL.appendingPathComponent(historyFileName)
    }
    
    private init() {
        setupDirectories()
        loadHistory()
        startAutoCleanup()
    }
    
    private func setupDirectories() {
        do {
            try FileManager.default.createDirectory(at: historyDirectoryURL, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: audioDirectoryURL, withIntermediateDirectories: true)
        } catch {
            print("Failed to create history directories: \(error)")
            errorMessage = "Failed to create history directories: \(error.localizedDescription)"
        }
    }
    
    private func loadHistory() {
        isLoading = true
        
        guard FileManager.default.fileExists(atPath: historyFileURL.path) else {
            entries = []
            isLoading = false
            return
        }
        
        do {
            let data = try Data(contentsOf: historyFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            entries = try decoder.decode([HistoryEntry].self, from: data)
            entries.sort { $0.timestamp > $1.timestamp }
        } catch {
            print("Failed to load history: \(error)")
            errorMessage = "Failed to load history: \(error.localizedDescription)"
            entries = []
        }
        
        isLoading = false
    }
    
    private func saveHistory() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(entries)
            try data.write(to: historyFileURL)
        } catch {
            print("Failed to save history: \(error)")
            errorMessage = "Failed to save history: \(error.localizedDescription)"
        }
    }
    
    func addEntry(_ entry: HistoryEntry) {
        entries.insert(entry, at: 0)
        saveHistory()
    }
    
    func removeEntry(withId id: UUID) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        let entry = entries[index]
        
        let audioURL = URL(fileURLWithPath: entry.audioFilePath)
        try? FileManager.default.removeItem(at: audioURL)
        
        entries.remove(at: index)
        saveHistory()
    }
    
    func removeAllEntries() {
        for entry in entries {
            let audioURL = URL(fileURLWithPath: entry.audioFilePath)
            try? FileManager.default.removeItem(at: audioURL)
        }
        
        entries.removeAll()
        saveHistory()
    }
    
    func saveAudioFile(data: Data, timestamp: Date) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = dateFormatter.string(from: timestamp)
        
        let fileName = "audio_\(dateString).wav"
        let audioURL = audioDirectoryURL.appendingPathComponent(fileName)
        
        do {
            try data.write(to: audioURL)
            return audioURL.path
        } catch {
            print("Failed to save audio file: \(error)")
            errorMessage = "Failed to save audio file: \(error.localizedDescription)"
            return nil
        }
    }
    
    func getAudioFileURL(for entry: HistoryEntry) -> URL? {
        guard FileManager.default.fileExists(atPath: entry.audioFilePath) else {
            return nil
        }
        return URL(fileURLWithPath: entry.audioFilePath)
    }
    
    private func startAutoCleanup() {
        Task {
            while true {
                try await Task.sleep(for: .seconds(3600))
                performAutoCleanup()
            }
        }
    }
    
    private func performAutoCleanup() {
        let retentionDays = SettingsStore.shared.historyRetentionDays
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) ?? Date()
        
        let entriesToRemove = entries.filter { $0.timestamp < cutoffDate }
        
        for entry in entriesToRemove {
            removeEntry(withId: entry.id)
        }
        
        if !entriesToRemove.isEmpty {
            print("Auto-cleanup removed \(entriesToRemove.count) entries older than \(retentionDays) days")
        }
    }
    
    func manualCleanup() {
        let retentionDays = SettingsStore.shared.historyRetentionDays
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) ?? Date()
        
        let entriesToRemove = entries.filter { $0.timestamp < cutoffDate }
        
        if entriesToRemove.isEmpty {
            print("Manual cleanup: No entries older than \(retentionDays) days found")
            return
        }
        
        for entry in entriesToRemove {
            removeEntry(withId: entry.id)
        }
        
        print("Manual cleanup: Removed \(entriesToRemove.count) entries older than \(retentionDays) days")
    }
    
    func exportHistory() -> URL? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = dateFormatter.string(from: Date())
        
        let fileName = "dictaum_history_\(dateString).json"
        let exportURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(entries)
            try data.write(to: exportURL)
            return exportURL
        } catch {
            print("Failed to export history: \(error)")
            errorMessage = "Failed to export history: \(error.localizedDescription)"
            return nil
        }
    }
    
    var storageSize: String {
        let historySize = (try? historyFileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
        
        var audioSize: Int64 = 0
        if let audioFiles = try? FileManager.default.contentsOfDirectory(at: audioDirectoryURL, includingPropertiesForKeys: [.fileSizeKey]) {
            for audioFile in audioFiles {
                do {
                    let resourceValues = try audioFile.resourceValues(forKeys: [.fileSizeKey])
                    if let fileSize = resourceValues.fileSize {
                        audioSize += Int64(fileSize)
                    }
                } catch {
                    // Ignore errors for individual files
                }
            }
        }
        
        let totalSize = Int64(historySize) + audioSize
        return ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    var entryCount: Int {
        return entries.count
    }
    
    var hasOldEntries: Bool {
        let retentionDays = SettingsStore.shared.historyRetentionDays
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) ?? Date()
        return entries.contains { $0.timestamp < cutoffDate }
    }
}