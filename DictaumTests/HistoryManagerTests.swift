import Testing
import Foundation
@testable import Dictaum

@Test("HistoryEntry creation and formatting")
func testHistoryEntryCreation() async throws {
    let timestamp = Date()
    let entry = HistoryEntry(
        timestamp: timestamp,
        audioFilePath: "/path/to/audio.wav",
        transcript: "This is a test transcription that is longer than 100 characters to test the shortTranscript property functionality",
        duration: 5.5,
        modelUsed: "openai_whisper-small",
        language: "en",
        quality: TranscriptionQuality(
            temperature: 0.2,
            beamSize: 1,
            bestOf: 1,
            topK: 5,
            enableTimestamps: false
        )
    )
    
    #expect(entry.transcript.count > 100)
    #expect(entry.shortTranscript.count <= 103) // 100 + "..."
    #expect(entry.shortTranscript.hasSuffix("..."))
    #expect(entry.formattedDuration == "5s")
    #expect(entry.modelUsed == "openai_whisper-small")
    #expect(entry.language == "en")
}

@Test("HistoryEntry short transcript handling")
func testShortTranscriptHandling() async throws {
    let shortEntry = HistoryEntry(
        timestamp: Date(),
        audioFilePath: "/path/to/audio.wav",
        transcript: "Short transcript",
        duration: 1.0,
        modelUsed: "test",
        language: "en"
    )
    
    #expect(shortEntry.shortTranscript == "Short transcript")
    #expect(!shortEntry.shortTranscript.hasSuffix("..."))
}

@Test("TranscriptionQuality creation")
func testTranscriptionQualityCreation() async throws {
    let quality = TranscriptionQuality(
        avgLogProb: -0.5,
        compressionRatio: 2.1,
        temperature: 0.3,
        beamSize: 2,
        bestOf: 3,
        topK: 10,
        enableTimestamps: true
    )
    
    #expect(quality.avgLogProb == -0.5)
    #expect(quality.compressionRatio == 2.1)
    #expect(quality.temperature == 0.3)
    #expect(quality.beamSize == 2)
    #expect(quality.bestOf == 3)
    #expect(quality.topK == 10)
    #expect(quality.enableTimestamps == true)
}

@Test("HistoryEntry codable conformance")
func testHistoryEntryCodableConformance() async throws {
    let originalEntry = HistoryEntry(
        timestamp: Date(),
        audioFilePath: "/path/to/audio.wav",
        transcript: "Test transcript",
        duration: 3.0,
        modelUsed: "test-model",
        language: "en",
        quality: TranscriptionQuality(
            temperature: 0.2,
            beamSize: 1,
            bestOf: 1,
            topK: 5,
            enableTimestamps: false
        )
    )
    
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    
    let encoded = try encoder.encode(originalEntry)
    let decoded = try decoder.decode(HistoryEntry.self, from: encoded)
    
    #expect(decoded.id == originalEntry.id)
    #expect(decoded.audioFilePath == originalEntry.audioFilePath)
    #expect(decoded.transcript == originalEntry.transcript)
    #expect(decoded.duration == originalEntry.duration)
    #expect(decoded.modelUsed == originalEntry.modelUsed)
    #expect(decoded.language == originalEntry.language)
    #expect(decoded.quality?.temperature == originalEntry.quality?.temperature)
}