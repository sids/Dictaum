//
//  ModelManager.swift
//  Dictaum
//
//  Created by Siddhartha Reddy on 02/07/25.
//

import Foundation
import SwiftUI
import WhisperKit
import AVFoundation

struct ModelInfo: Identifiable, Equatable {
    let id: String
    let name: String
    let displayName: String
    let diskSize: String
    let memoryUsage: String
    let speed: ModelSpeed
    let isEnglishOnly: Bool
    
    var isDownloaded: Bool {
        return ModelManagerUtils.isModelDownloaded(id)
    }
    
    enum ModelSpeed: String, CaseIterable {
        case fastest = "Fastest"
        case fast = "Fast"
        case balanced = "Balanced"
        case accurate = "Accurate"
        case mostAccurate = "Most Accurate"
        
        var color: Color {
            switch self {
            case .fastest: return .green
            case .fast: return .mint
            case .balanced: return .blue
            case .accurate: return .orange
            case .mostAccurate: return .red
            }
        }
    }
}

enum ModelDownloadState: Equatable {
    case notDownloaded
    case downloading(progress: Double)
    case warming
    case downloaded
    case error(String)
}

struct ModelManagerUtils {
    static func isModelDownloaded(_ modelId: String) -> Bool {
        let possiblePaths = getModelPaths(for: modelId)
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path.path) {
                // Check if it's actually a directory with model files
                var isDirectory: ObjCBool = false
                if FileManager.default.fileExists(atPath: path.path, isDirectory: &isDirectory) && isDirectory.boolValue {
                    // Check for actual model files inside
                    do {
                        let contents = try FileManager.default.contentsOfDirectory(atPath: path.path)
                        let hasModelFiles = contents.contains { $0.hasSuffix(".mlmodelc") || $0.hasSuffix(".mlpackage") }
                        if hasModelFiles {
                            return true
                        }
                    } catch {
                        // Silently ignore errors
                    }
                }
            }
        }
        
        return false
    }
    
    static func getModelPaths(for modelId: String) -> [URL] {
        var paths: [URL] = []
        
        // Get base directories
        let directories = [
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
            FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
        ].compactMap { $0 }
        
        // Define path patterns
        let pathPatterns = [
            // WhisperKit specific paths
            ["huggingface", "models", "argmaxinc", "whisperkit-coreml", modelId],
            ["whisperkit", modelId],
            ["Models", modelId],
            // OpenAI direct paths
            ["huggingface", "models", "openai", transformOpenAIModelName(modelId)],
            // Standard huggingface path (fallback)
            ["huggingface", "models", modelId]
        ]
        
        // Build all combinations
        for directory in directories {
            for pattern in pathPatterns {
                paths.append(buildPath(from: directory, components: pattern))
            }
        }
        
        return paths
    }
    
    private static func buildPath(from baseURL: URL, components: [String]) -> URL {
        return components.reduce(baseURL) { url, component in
            url.appendingPathComponent(component)
        }
    }
    
    private static func transformOpenAIModelName(_ modelId: String) -> String {
        return modelId.replacingOccurrences(of: "openai_", with: "").replacingOccurrences(of: "_", with: "-")
    }
}

@MainActor
class ModelManager: ObservableObject {
    static let shared = ModelManager()
    
    @Published var downloadStates: [String: ModelDownloadState] = [:]
    @Published var downloadProgress: [String: Double] = [:]
    @Published var isDownloading: Bool = false
    @Published var currentDownloadingModel: String?
    
    private var downloadTask: Task<Void, Never>?
    
    private init() {
        setupInitialStates()
    }
    
    let availableModels: [ModelInfo] = [
        // Balanced models first
        ModelInfo(
            id: "openai_whisper-small.en",
            name: "openai_whisper-small.en",
            displayName: "Whisper Small (English)",
            diskSize: "244 MB",
            memoryUsage: "~1 GB",
            speed: .balanced,
            isEnglishOnly: true
        ),
        ModelInfo(
            id: "openai_whisper-small",
            name: "openai_whisper-small",
            displayName: "Whisper Small",
            diskSize: "244 MB",
            memoryUsage: "~1 GB",
            speed: .balanced,
            isEnglishOnly: false
        ),
        // Fast models
        ModelInfo(
            id: "openai_whisper-base.en",
            name: "openai_whisper-base.en",
            displayName: "Whisper Base (English)",
            diskSize: "142 MB",
            memoryUsage: "~500 MB",
            speed: .fast,
            isEnglishOnly: true
        ),
        ModelInfo(
            id: "openai_whisper-base",
            name: "openai_whisper-base",
            displayName: "Whisper Base",
            diskSize: "142 MB",
            memoryUsage: "~500 MB",
            speed: .fast,
            isEnglishOnly: false
        ),
        // Turbo model
        ModelInfo(
            id: "openai_whisper-large-v3-turbo",
            name: "openai_whisper-large-v3-turbo",
            displayName: "Whisper Large v3 Turbo",
            diskSize: "1.6 GB",
            memoryUsage: "~3 GB",
            speed: .accurate,
            isEnglishOnly: false
        ),
        // Large model
        ModelInfo(
            id: "openai_whisper-large-v3",
            name: "openai_whisper-large-v3",
            displayName: "Whisper Large v3",
            diskSize: "3.1 GB",
            memoryUsage: "~6 GB",
            speed: .mostAccurate,
            isEnglishOnly: false
        ),
        // Tiny models at the end
        ModelInfo(
            id: "openai_whisper-tiny.en",
            name: "openai_whisper-tiny.en",
            displayName: "Whisper Tiny (English)",
            diskSize: "39 MB",
            memoryUsage: "~200 MB",
            speed: .fastest,
            isEnglishOnly: true
        ),
        ModelInfo(
            id: "openai_whisper-tiny",
            name: "openai_whisper-tiny",
            displayName: "Whisper Tiny",
            diskSize: "39 MB",
            memoryUsage: "~200 MB",
            speed: .fastest,
            isEnglishOnly: false
        )
    ]
    
    private func setupInitialStates() {
        for model in availableModels {
            downloadStates[model.id] = isModelDownloaded(model.id) ? .downloaded : .notDownloaded
        }
    }
    
    func isModelDownloaded(_ modelId: String) -> Bool {
        return ModelManagerUtils.isModelDownloaded(modelId)
    }
    
    private func getModelPaths(for modelId: String) -> [URL] {
        return ModelManagerUtils.getModelPaths(for: modelId)
    }
    
    func downloadModel(_ modelId: String) {
        guard !isDownloading else { return }
        
        isDownloading = true
        currentDownloadingModel = modelId
        downloadStates[modelId] = .downloading(progress: 0.0)
        
        downloadTask = Task {
            await downloadModelAsync(modelId)
        }
    }
    
    private func downloadModelAsync(_ modelId: String) async {
        do {
            downloadStates[modelId] = .downloading(progress: 0.0)
            
            // Extract variant from model ID
            // "openai_whisper-base" -> "base"
            // "openai_whisper-base.en" -> "base.en"
            // "openai_whisper-large-v3" -> "large-v3"
            let variant = modelId.replacingOccurrences(of: "openai_whisper-", with: "")
            
            // Download the model with real progress tracking
            let modelFolder = try await WhisperKit.download(
                variant: variant,
                downloadBase: nil, // Use default Hugging Face CDN
                useBackgroundSession: false, // Can't use background session in sandboxed app
                from: "argmaxinc/whisperkit-coreml",
                progressCallback: { [weak self] progress in
                    Task { @MainActor in
                        guard let self = self else { return }
                        let fractionCompleted = progress.fractionCompleted
                        self.downloadStates[modelId] = .downloading(progress: fractionCompleted)
                        self.downloadProgress[modelId] = fractionCompleted
                    }
                }
            )
            
            // Download complete, now initialize WhisperKit with the downloaded model
            downloadStates[modelId] = .warming
            
            let whisperKit = try await WhisperKit(
                modelFolder: modelFolder.path,
                verbose: true,
                logLevel: .debug,
                prewarm: true,
                load: true,
                download: false
            )
            
            // Warm up the model
            let warmupAudio = generateWarmupAudio()
            _ = try await whisperKit.transcribe(audioArray: warmupAudio)
            
            downloadStates[modelId] = .downloaded
            isDownloading = false
            currentDownloadingModel = nil
            
        } catch {
            await handleDownloadError(modelId, error)
        }
    }
    
    private func handleDownloadError(_ modelId: String, _ error: Error) async {
        downloadStates[modelId] = .error(error.localizedDescription)
        isDownloading = false
        currentDownloadingModel = nil
    }
    
    func cancelCurrentDownload() {
        downloadTask?.cancel()
        
        if let modelId = currentDownloadingModel {
            downloadStates[modelId] = .notDownloaded
            downloadProgress[modelId] = 0.0
        }
        
        isDownloading = false
        currentDownloadingModel = nil
    }
    
    func deleteModel(_ modelId: String) {
        let possiblePaths = getModelPaths(for: modelId)
        
        for modelPath in possiblePaths {
            if FileManager.default.fileExists(atPath: modelPath.path) {
                do {
                    try FileManager.default.removeItem(at: modelPath)
                } catch {
                    print("Failed to delete model at \(modelPath.path): \(error)")
                }
            }
        }
        
        downloadStates[modelId] = .notDownloaded
    }
    
    func selectModel(_ modelId: String) {
        SettingsStore.shared.selectedModel = modelId
    }
    
    private func generateWarmupAudio() -> [Float] {
        let sampleRate: Float = 16000
        let duration: Float = 2.0
        let frequency: Float = 440.0
        
        let sampleCount = Int(sampleRate * duration)
        var samples: [Float] = []
        
        for i in 0..<sampleCount {
            let sample = sin(2.0 * Float.pi * frequency * Float(i) / sampleRate) * 0.3
            samples.append(sample)
        }
        
        return samples
    }
}