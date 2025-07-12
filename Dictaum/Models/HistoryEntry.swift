import Foundation

struct HistoryEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: Date
    let audioFilePath: String
    let transcript: String
    let duration: Double
    let modelUsed: String
    let language: String
    let quality: TranscriptionQuality?
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        audioFilePath: String,
        transcript: String,
        duration: Double,
        modelUsed: String,
        language: String,
        quality: TranscriptionQuality? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.audioFilePath = audioFilePath
        self.transcript = transcript
        self.duration = duration
        self.modelUsed = modelUsed
        self.language = language
        self.quality = quality
    }
}

struct TranscriptionQuality: Codable, Equatable {
    let avgLogProb: Double?
    let compressionRatio: Double?
    let temperature: Double
    let beamSize: Int
    let bestOf: Int
    let topK: Int
    let enableTimestamps: Bool
    
    init(
        avgLogProb: Double? = nil,
        compressionRatio: Double? = nil,
        temperature: Double,
        beamSize: Int,
        bestOf: Int,
        topK: Int,
        enableTimestamps: Bool
    ) {
        self.avgLogProb = avgLogProb
        self.compressionRatio = compressionRatio
        self.temperature = temperature
        self.beamSize = beamSize
        self.bestOf = bestOf
        self.topK = topK
        self.enableTimestamps = enableTimestamps
    }
}

extension HistoryEntry {
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    var formattedDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0s"
    }
    
    var shortTranscript: String {
        if transcript.count > 100 {
            return String(transcript.prefix(100)) + "..."
        }
        return transcript
    }
}