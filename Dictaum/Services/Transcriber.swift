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
    
    init(modelName: String? = nil) async throws {
        self.modelName = modelName ?? SettingsStore.shared.selectedModel
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
        
        let options = DecodingOptions(
            task: .transcribe,
            language: "english",
            temperature: 0.0,
            temperatureIncrementOnFallback: 0.2,
            temperatureFallbackCount: 3,
            topK: 5,
            usePrefillPrompt: false,
            usePrefillCache: false,
            skipSpecialTokens: true,
            withoutTimestamps: true,
            clipTimestamps: []
        )
        
        let results = try await whisperKit.transcribe(
            audioArray: audioSamples,
            decodeOptions: options
        )
        
        return results.flatMap { $0.segments.map { $0.text } }.joined(separator: " ").trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
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