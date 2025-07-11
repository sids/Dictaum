//
//  Transcriber.swift
//  Dictaum
//
//  Created by Siddhartha Reddy on 02/07/25.
//

import Foundation
import WhisperKit

class Transcriber {
    private var whisperKit: WhisperKit?
    let modelName: String
    
    // Configurable decoder parameters for experimentation
    var temperature: Float = 0.2 // Changed from 0.0 to 0.2 for better quality
    var temperatureIncrementOnFallback: Float = 0.2
    var temperatureFallbackCount: Int = 3
    var beamSize: Int = 1 // Will experiment with 1, 3, 5
    var bestOf: Int = 1 // Will experiment with 1, 3, 5
    var topK: Int = 5
    var withoutTimestamps: Bool = false // Changed to false for future features
    var language: String = "english"
    var usePrefillPrompt: Bool = false
    var usePrefillCache: Bool = false
    
    // Quality control parameters
    var logProbThreshold: Float = -1.0
    var compressionRatioThreshold: Float = 2.4
    var suppressBlank: Bool = true
    
    init(modelName: String? = nil) async throws {
        self.modelName = modelName ?? SettingsStore.shared.selectedModel
        self.language = SettingsStore.shared.selectedLanguage
        
        // Initialize parameters from settings
        let settings = SettingsStore.shared
        self.temperature = Float(settings.temperature)
        self.beamSize = settings.beamSize
        self.bestOf = settings.bestOf
        self.topK = settings.topK
        self.withoutTimestamps = !settings.enableTimestamps
        self.logProbThreshold = Float(settings.logProbThreshold)
        self.compressionRatioThreshold = Float(settings.compressionRatioThreshold)
        self.suppressBlank = settings.suppressBlank
        
        try await setupWhisperKit()
    }
    
    private func setupWhisperKit() async throws {
        // Get the model folder path
        let modelPath = ModelManagerUtils.getModelPaths(for: modelName).first { path in
            FileManager.default.fileExists(atPath: path.path)
        }
        
        if let modelPath = modelPath {
            whisperKit = try await WhisperKit(
                modelFolder: modelPath.path,
                verbose: true,
                logLevel: .debug,
                prewarm: true,
                load: true,
                download: false
            )
        } else {
            whisperKit = try await WhisperKit(
                model: modelName,
                verbose: true,
                logLevel: .debug,
                prewarm: true,
                load: true,
                download: false
            )
        }
    }
    
    func transcribe(_ audioSamples: [Float]) async throws -> String? {
        guard let whisperKit = whisperKit else {
            throw TranscriptionError.modelNotLoaded
        }
        
        // Create options using configurable parameters
        let options = DecodingOptions(
            task: .transcribe,
            language: language,
            temperature: temperature,
            temperatureIncrementOnFallback: temperatureIncrementOnFallback,
            temperatureFallbackCount: temperatureFallbackCount,
            topK: topK,
            usePrefillPrompt: usePrefillPrompt,
            usePrefillCache: usePrefillCache,
            skipSpecialTokens: true,
            withoutTimestamps: withoutTimestamps,
            clipTimestamps: [],
            suppressBlank: suppressBlank,
            compressionRatioThreshold: compressionRatioThreshold,
            logProbThreshold: logProbThreshold
        )
        
        // Note: WhisperKit's DecodingOptions does not support topP parameter
        
        let results = try await whisperKit.transcribe(
            audioArray: audioSamples,
            decodeOptions: options
        )
        
        let transcription = results.flatMap { $0.segments.map { $0.text } }.joined(separator: " ").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        // Log parameters and results for experimentation
        print("[Transcriber] Parameters - temp: \(temperature), beamSize: \(beamSize), bestOf: \(bestOf), topK: \(topK)")
        print("[Transcriber] Transcription: \(transcription)")
        
        return transcription
    }
    
    // MARK: - Parameter Experimentation Methods
    
    func setTemperature(_ temp: Float) {
        temperature = temp
        print("[Transcriber] Temperature set to: \(temp)")
    }
    
    func setBeamSize(_ size: Int) {
        beamSize = size
        print("[Transcriber] Beam size set to: \(size)")
    }
    
    func setBestOf(_ value: Int) {
        bestOf = value
        print("[Transcriber] BestOf set to: \(value)")
    }
    
    // TopP is not supported by WhisperKit's DecodingOptions
    
    func setLanguage(_ lang: String) {
        language = lang
        print("[Transcriber] Language set to: \(lang)")
    }
    
    func enableTimestamps(_ enable: Bool) {
        withoutTimestamps = !enable
        print("[Transcriber] Timestamps \(enable ? "enabled" : "disabled")")
    }
    
    func enablePrefillPrompt(_ enable: Bool) {
        usePrefillPrompt = enable
        usePrefillCache = enable
        print("[Transcriber] Prefill prompt \(enable ? "enabled" : "disabled")")
    }
    
    // Preset configurations for experimentation
    func applyConservativeSettings() {
        temperature = 0.0
        beamSize = 1
        bestOf = 1
        // topP not used - WhisperKit doesn't support it
        print("[Transcriber] Applied conservative settings")
    }
    
    func applyBalancedSettings() {
        temperature = 0.2
        beamSize = 3
        bestOf = 1
        // topP not used - WhisperKit doesn't support it
        print("[Transcriber] Applied balanced settings")
    }
    
    func applyCreativeSettings() {
        temperature = 0.4
        beamSize = 5
        bestOf = 3
        // topP not used - WhisperKit doesn't support it
        print("[Transcriber] Applied creative settings")
    }
}

enum TranscriptionError: LocalizedError {
    case modelNotLoaded
    
    var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            return "Transcription model not loaded"
        }
    }
}