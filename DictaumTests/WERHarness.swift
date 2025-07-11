//
//  WERHarness.swift
//  DictaumTests
//
//  Created by Claude on 09/07/25.
//

import XCTest
import AVFoundation
@testable import Dictaum

class WERHarness: XCTestCase {
    
    struct TestCase {
        let name: String
        let audioFile: String
        let expectedText: String
        let metadata: [String: Any]
    }
    
    // Test cases with ground truth
    private let testCases: [TestCase] = [
        TestCase(
            name: "short_greeting",
            audioFile: "short_greeting.wav",
            expectedText: "Hello, how are you today?",
            metadata: ["duration": 2.5, "speaker": "female", "accent": "american"]
        ),
        TestCase(
            name: "technical_terms",
            audioFile: "technical_terms.wav",
            expectedText: "The API endpoint returns JSON data with authentication tokens.",
            metadata: ["duration": 4.0, "speaker": "male", "accent": "british", "domain": "technical"]
        ),
        TestCase(
            name: "numbers_and_dates",
            audioFile: "numbers_and_dates.wav",
            expectedText: "Meeting scheduled for January 15th at 3:30 PM.",
            metadata: ["duration": 3.2, "speaker": "female", "accent": "american"]
        ),
        TestCase(
            name: "fast_speech",
            audioFile: "fast_speech.wav",
            expectedText: "This is a test of rapid speech recognition capabilities.",
            metadata: ["duration": 2.0, "speaker": "male", "accent": "american", "speed": "fast"]
        ),
        TestCase(
            name: "quiet_speech",
            audioFile: "quiet_speech.wav",
            expectedText: "Testing transcription with low volume audio input.",
            metadata: ["duration": 3.5, "speaker": "female", "accent": "american", "volume": "low"]
        )
    ]
    
    private var transcriber: Transcriber!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Use a test model - preferably a smaller one for faster testing
        Task {
            transcriber = try await Transcriber(modelName: "openai_whisper-base.en")
        }
    }
    
    override func tearDownWithError() throws {
        transcriber = nil
        try super.tearDownWithError()
    }
    
    // MARK: - WER Calculation
    
    func testWordErrorRate() async throws {
        var totalWER: Double = 0
        var totalTests = 0
        
        for testCase in testCases {
            let audioSamples = try loadAudioFile(testCase.audioFile)
            let transcription = try await transcriber.transcribe(audioSamples)
            
            guard let transcription = transcription else {
                XCTFail("Transcription returned nil for \(testCase.name)")
                continue
            }
            
            let wer = calculateWER(reference: testCase.expectedText, hypothesis: transcription)
            totalWER += wer
            totalTests += 1
            
            print("Test: \(testCase.name)")
            print("Expected: \(testCase.expectedText)")
            print("Actual:   \(transcription)")
            print("WER:      \(String(format: "%.3f", wer))")
            print("---")
        }
        
        let averageWER = totalWER / Double(totalTests)
        print("Average WER: \(String(format: "%.3f", averageWER))")
        
        // Assert that WER is below acceptable threshold
        XCTAssertLessThan(averageWER, 0.3, "Average WER should be below 30%")
    }
    
    // MARK: - Parameter Experimentation Tests
    
    func testTemperatureExperiment() async throws {
        let testCase = testCases[0] // Use first test case
        let audioSamples = try loadAudioFile(testCase.audioFile)
        let temperatures: [Float] = [0.0, 0.1, 0.2, 0.3, 0.4]
        
        var results: [(temperature: Float, wer: Double, transcription: String)] = []
        
        for temp in temperatures {
            transcriber.setTemperature(temp)
            
            let transcription = try await transcriber.transcribe(audioSamples)
            guard let transcription = transcription else { continue }
            
            let wer = calculateWER(reference: testCase.expectedText, hypothesis: transcription)
            results.append((temp, wer, transcription))
            
            print("Temperature: \(temp), WER: \(String(format: "%.3f", wer)), Text: \(transcription)")
        }
        
        // Find best temperature
        let bestResult = results.min { $0.wer < $1.wer }
        print("Best temperature: \(bestResult?.temperature ?? 0.0) with WER: \(String(format: "%.3f", bestResult?.wer ?? 1.0))")
    }
    
    func testBeamSizeExperiment() async throws {
        let testCase = testCases[1] // Use second test case
        let audioSamples = try loadAudioFile(testCase.audioFile)
        let beamSizes: [Int] = [1, 3, 5]
        
        var results: [(beamSize: Int, wer: Double, transcription: String)] = []
        
        for beamSize in beamSizes {
            transcriber.setBeamSize(beamSize)
            
            let transcription = try await transcriber.transcribe(audioSamples)
            guard let transcription = transcription else { continue }
            
            let wer = calculateWER(reference: testCase.expectedText, hypothesis: transcription)
            results.append((beamSize, wer, transcription))
            
            print("Beam size: \(beamSize), WER: \(String(format: "%.3f", wer)), Text: \(transcription)")
        }
        
        // Find best beam size
        let bestResult = results.min { $0.wer < $1.wer }
        print("Best beam size: \(bestResult?.beamSize ?? 1) with WER: \(String(format: "%.3f", bestResult?.wer ?? 1.0))")
    }
    
    func testPresetConfigurations() async throws {
        let testCase = testCases[2] // Use third test case
        let audioSamples = try loadAudioFile(testCase.audioFile)
        
        var results: [(preset: String, wer: Double, transcription: String)] = []
        
        // Test conservative settings
        transcriber.applyConservativeSettings()
        let conservativeTranscription = try await transcriber.transcribe(audioSamples)
        if let transcription = conservativeTranscription {
            let wer = calculateWER(reference: testCase.expectedText, hypothesis: transcription)
            results.append(("conservative", wer, transcription))
        }
        
        // Test balanced settings
        transcriber.applyBalancedSettings()
        let balancedTranscription = try await transcriber.transcribe(audioSamples)
        if let transcription = balancedTranscription {
            let wer = calculateWER(reference: testCase.expectedText, hypothesis: transcription)
            results.append(("balanced", wer, transcription))
        }
        
        // Test creative settings
        transcriber.applyCreativeSettings()
        let creativeTranscription = try await transcriber.transcribe(audioSamples)
        if let transcription = creativeTranscription {
            let wer = calculateWER(reference: testCase.expectedText, hypothesis: transcription)
            results.append(("creative", wer, transcription))
        }
        
        for result in results {
            print("Preset: \(result.preset), WER: \(String(format: "%.3f", result.wer)), Text: \(result.transcription)")
        }
        
        // Find best preset
        let bestResult = results.min { $0.wer < $1.wer }
        print("Best preset: \(bestResult?.preset ?? "none") with WER: \(String(format: "%.3f", bestResult?.wer ?? 1.0))")
    }
    
    // MARK: - Helper Methods
    
    private func loadAudioFile(_ filename: String) throws -> [Float] {
        // Try to load real audio file from test bundle
        if let realAudioSamples = try? loadRealAudioFile(filename) {
            return realAudioSamples
        }
        
        // Fallback to synthetic audio data for testing
        print("Warning: Using synthetic audio for \(filename) - real audio file not found")
        return generateSyntheticAudio(for: filename)
    }
    
    private func loadRealAudioFile(_ filename: String) throws -> [Float] {
        // Look for audio files in test bundle
        guard let testBundle = Bundle(for: type(of: self)) else {
            throw NSError(domain: "TestBundle", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not access test bundle"])
        }
        
        guard let audioFileURL = testBundle.url(forResource: filename, withExtension: nil) else {
            throw NSError(domain: "AudioFile", code: 1, userInfo: [NSLocalizedDescriptionKey: "Audio file \(filename) not found in test bundle"])
        }
        
        let audioFile = try AVAudioFile(forReading: audioFileURL)
        let format = audioFile.processingFormat
        
        let frameCount = UInt32(audioFile.length)
        guard let audioBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw NSError(domain: "AudioBuffer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not create audio buffer"])
        }
        
        try audioFile.read(into: audioBuffer)
        
        // Convert to 16kHz mono float array
        return try convertToMono16kHz(audioBuffer)
    }
    
    private func convertToMono16kHz(_ buffer: AVAudioPCMBuffer) throws -> [Float] {
        let targetSampleRate: Double = 16000
        let sourceFormat = buffer.format
        
        // Create target format (16kHz mono)
        guard let targetFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                             sampleRate: targetSampleRate,
                                             channels: 1,
                                             interleaved: false) else {
            throw NSError(domain: "AudioFormat", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not create target audio format"])
        }
        
        // Create converter
        guard let converter = AVAudioConverter(from: sourceFormat, to: targetFormat) else {
            throw NSError(domain: "AudioConverter", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not create audio converter"])
        }
        
        // Calculate output buffer size
        let outputFrameCount = UInt32(Double(buffer.frameLength) * (targetSampleRate / sourceFormat.sampleRate))
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputFrameCount) else {
            throw NSError(domain: "OutputBuffer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not create output buffer"])
        }
        
        // Convert audio
        var error: NSError?
        converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        
        if let error = error {
            throw error
        }
        
        // Extract float samples
        let channelData = outputBuffer.floatChannelData![0]
        let frameLength = Int(outputBuffer.frameLength)
        return Array(UnsafeBufferPointer(start: channelData, count: frameLength))
    }
    
    private func generateSyntheticAudio(for filename: String) -> [Float] {
        let sampleRate = 16000
        let duration = 3.0
        let sampleCount = Int(Double(sampleRate) * duration)
        
        // Generate different synthetic audio based on filename
        var samples: [Float] = []
        for i in 0..<sampleCount {
            let t = Float(i) / Float(sampleRate)
            
            var sample: Float = 0.0
            
            switch filename {
            case "short_greeting.wav":
                // Simple greeting-like pattern
                let frequency: Float = 200.0 + 100.0 * sin(t * 4.0)
                sample = 0.3 * sin(2.0 * Float.pi * frequency * t) * exp(-t * 0.5)
                
            case "technical_terms.wav":
                // More complex pattern for technical speech
                let frequency: Float = 150.0 + 80.0 * sin(t * 2.0) + 40.0 * sin(t * 6.0)
                sample = 0.25 * sin(2.0 * Float.pi * frequency * t) * (1.0 + sin(t * 3.0)) * 0.5
                
            case "numbers_and_dates.wav":
                // Rhythmic pattern for numbers/dates
                let frequency: Float = 180.0 + 60.0 * sin(t * 8.0)
                sample = 0.2 * sin(2.0 * Float.pi * frequency * t) * (sin(t * 10.0) > 0 ? 1.0 : 0.3)
                
            case "fast_speech.wav":
                // Higher frequency modulation for fast speech
                let frequency: Float = 220.0 + 120.0 * sin(t * 12.0)
                sample = 0.35 * sin(2.0 * Float.pi * frequency * t) * (1.0 + sin(t * 8.0)) * 0.5
                
            case "quiet_speech.wav":
                // Lower amplitude for quiet speech
                let frequency: Float = 160.0 + 70.0 * sin(t * 3.0)
                sample = 0.15 * sin(2.0 * Float.pi * frequency * t) * (1.0 + sin(t * 2.0)) * 0.5
                
            default:
                // Default pattern
                let frequency: Float = 440.0 + 100.0 * sin(t * 2.0)
                sample = 0.2 * sin(2.0 * Float.pi * frequency * t) * (1.0 + sin(t * 0.5)) * 0.5
            }
            
            samples.append(sample)
        }
        
        return samples
    }
    
    private func calculateWER(reference: String, hypothesis: String) -> Double {
        let refWords = reference.lowercased().components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let hypWords = hypothesis.lowercased().components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        // Use edit distance (Levenshtein distance) to calculate WER
        let editDistance = levenshteinDistance(refWords, hypWords)
        
        guard refWords.count > 0 else { return 0.0 }
        return Double(editDistance) / Double(refWords.count)
    }
    
    private func levenshteinDistance(_ a: [String], _ b: [String]) -> Int {
        let aCount = a.count
        let bCount = b.count
        
        if aCount == 0 { return bCount }
        if bCount == 0 { return aCount }
        
        var matrix = Array(repeating: Array(repeating: 0, count: bCount + 1), count: aCount + 1)
        
        // Initialize first row and column
        for i in 0...aCount {
            matrix[i][0] = i
        }
        for j in 0...bCount {
            matrix[0][j] = j
        }
        
        // Fill the matrix
        for i in 1...aCount {
            for j in 1...bCount {
                let cost = (a[i-1] == b[j-1]) ? 0 : 1
                matrix[i][j] = min(
                    matrix[i-1][j] + 1,     // deletion
                    matrix[i][j-1] + 1,     // insertion
                    matrix[i-1][j-1] + cost // substitution
                )
            }
        }
        
        return matrix[aCount][bCount]
    }
}