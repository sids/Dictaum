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
    let attributes: [ModelAttribute]
    let isEnglishOnly: Bool
    let recommendation: String?
    
    var isDownloaded: Bool {
        return ModelManagerUtils.isModelDownloaded(id)
    }
    
    enum ModelAttribute: String, CaseIterable {
        case veryFast = "Very Fast"
        case fast = "Fast"
        case balanced = "Balanced"
        case accurate = "Accurate"
        case mostAccurate = "Most Accurate"
        case lowMemory = "Low Memory"
        case recommended = "Recommended"
        
        var color: Color {
            switch self {
            case .veryFast: return .green
            case .fast: return .mint
            case .balanced: return .blue
            case .accurate: return .orange
            case .mostAccurate: return .red
            case .lowMemory: return .purple
            case .recommended: return .accentColor
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
            // WhisperKit specific paths (handles both regular Whisper and Distil-Whisper models)
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
    private var progressHistory: [String: [Double]] = [:]
    
    private init() {
        setupInitialStates()
    }
    
    let availableModels: [ModelInfo] = [
        // Distil-Whisper model - Best of both worlds for English
        ModelInfo(
            id: "distil-whisper_distil-large-v3_turbo",
            name: "distil-whisper_distil-large-v3_turbo",
            displayName: "Distil-Whisper Large v3 Turbo",
            diskSize: "600 MB",
            memoryUsage: "~1.5 GB",
            attributes: [.veryFast, .accurate, .recommended],
            isEnglishOnly: true,
            recommendation: "Best choice for English: 6x faster than regular Whisper with near-identical accuracy"
        ),
        // Balanced models - Good all-around performance
        ModelInfo(
            id: "openai_whisper-small.en",
            name: "openai_whisper-small.en",
            displayName: "Whisper Small (English)",
            diskSize: "244 MB",
            memoryUsage: "~1 GB",
            attributes: [.balanced],
            isEnglishOnly: true,
            recommendation: "Good balance of speed, accuracy, and memory usage"
        ),
        ModelInfo(
            id: "openai_whisper-small",
            name: "openai_whisper-small",
            displayName: "Whisper Small (Multilingual)",
            diskSize: "244 MB",
            memoryUsage: "~1 GB",
            attributes: [.balanced],
            isEnglishOnly: false,
            recommendation: "Good balance for multiple languages with moderate memory usage"
        ),
        // Large models - Maximum accuracy with trade-offs
        ModelInfo(
            id: "openai_whisper-large-v3-turbo",
            name: "openai_whisper-large-v3-turbo",
            displayName: "Whisper Large v3 Turbo (Multilingual)",
            diskSize: "1.6 GB",
            memoryUsage: "~3 GB",
            attributes: [.fast, .accurate],
            isEnglishOnly: false,
            recommendation: "Fast and accurate for all languages, but slower than Distil-Whisper for English"
        ),
        ModelInfo(
            id: "openai_whisper-large-v3",
            name: "openai_whisper-large-v3",
            displayName: "Whisper Large v3 (Multilingual)",
            diskSize: "3.1 GB",
            memoryUsage: "~6 GB",
            attributes: [.mostAccurate],
            isEnglishOnly: false,
            recommendation: "Highest accuracy for rare languages and challenging audio, but significantly slower"
        ),
        // Ultra-lightweight models - Speed over accuracy
        ModelInfo(
            id: "openai_whisper-tiny.en",
            name: "openai_whisper-tiny.en",
            displayName: "Whisper Tiny (English)",
            diskSize: "39 MB",
            memoryUsage: "~200 MB",
            attributes: [.veryFast, .lowMemory],
            isEnglishOnly: true,
            recommendation: "Fastest option with minimal memory usage, but significantly lower accuracy"
        ),
        ModelInfo(
            id: "openai_whisper-tiny",
            name: "openai_whisper-tiny",
            displayName: "Whisper Tiny (Multilingual)",
            diskSize: "39 MB",
            memoryUsage: "~200 MB",
            attributes: [.veryFast, .lowMemory],
            isEnglishOnly: false,
            recommendation: "Fastest multilingual option with minimal memory usage, but significantly lower accuracy"
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
            try Task.checkCancellation()

            downloadStates[modelId] = .downloading(progress: 0.0)
            
            let (variant, repoId) = extractModelVariantAndRepo(modelId)
            
            // Download the model with real progress tracking
            // Try multiple CDN endpoints for better performance
            let downloadBases: [URL?] = [
                nil, // Default Hugging Face CDN
                URL(string: "https://cdn-lfs.huggingface.co"), // LFS CDN
                URL(string: "https://hf-mirror.com") // Alternative mirror
            ]
            
            var lastError: Error?
            var modelFolder: URL?
            
            for downloadBase in downloadBases {
                try Task.checkCancellation()
                do {
                    print("[ModelManager] Attempting download from: \(downloadBase?.absoluteString ?? "default CDN")")
                    modelFolder = try await WhisperKit.download(
                        variant: variant,
                        downloadBase: downloadBase,
                        useBackgroundSession: false, // Can't use background session in sandboxed app
                        from: repoId,
                        progressCallback: { [weak self] progress in
                            Task { @MainActor in
                                guard let self, self.isDownloading, self.currentDownloadingModel == modelId else { return }

                                try? Task.checkCancellation()

                                let fractionCompleted = progress.fractionCompleted

                                // Add some smoothing to progress updates to handle uneven download speeds
                                let smoothedProgress = self.smoothProgress(fractionCompleted, for: modelId)
                                self.downloadStates[modelId] = .downloading(progress: smoothedProgress)
                                self.downloadProgress[modelId] = smoothedProgress

                                // Log progress for debugging slow downloads
                                if Int(smoothedProgress * 100) % 10 == 0 {
                                    print("[ModelManager] Download progress: \(Int(smoothedProgress * 100))%")
                                }
                            }
                        }
                    )
                    print("[ModelManager] Successfully downloaded from: \(downloadBase?.absoluteString ?? "default CDN")")
                    break
                } catch is CancellationError {
                    // Propagate cancellation to outer catch block
                    throw CancellationError()
                } catch {
                    print("[ModelManager] Download failed from \(downloadBase?.absoluteString ?? "default CDN"): \(error)")
                    lastError = error
                    if downloadBase != downloadBases.last {
                        print("[ModelManager] Trying next CDN...")
                        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                    }
                }
            }
            
            try Task.checkCancellation()

            guard let modelFolder = modelFolder else {
                throw lastError ?? NSError(domain: "ModelDownload", code: -1, userInfo: [NSLocalizedDescriptionKey: "All download attempts failed"])
            }
            
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
        // Ignore cancellation errors as they are expected
        if error is CancellationError {
            return
        }
        downloadStates[modelId] = .error(error.localizedDescription)
        isDownloading = false
        currentDownloadingModel = nil
        downloadTask = nil
    }
    
    func cancelCurrentDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        
        if let modelId = currentDownloadingModel {
            downloadStates[modelId] = .notDownloaded
            downloadProgress[modelId] = 0.0
            progressHistory[modelId] = nil // Clear progress history
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
    
    private func smoothProgress(_ progress: Double, for modelId: String) -> Double {
        // Maintain a history of progress values to smooth out erratic updates
        if progressHistory[modelId] == nil {
            progressHistory[modelId] = []
        }
        
        progressHistory[modelId]!.append(progress)
        
        // Keep only the last 5 progress values
        if progressHistory[modelId]!.count > 5 {
            progressHistory[modelId]!.removeFirst()
        }
        
        // Return the maximum progress seen so far (progress should only increase)
        return progressHistory[modelId]!.max() ?? progress
    }
    
    private func extractModelVariantAndRepo(_ modelId: String) -> (variant: String, repoId: String) {
        if modelId.hasPrefix("distil-whisper_") {
            // "distil-whisper_distil-large-v3_turbo" -> ("distil-whisper_distil-large-v3_turbo", "argmaxinc/whisperkit-coreml")
            return (modelId, "argmaxinc/whisperkit-coreml")
        } else if modelId.hasPrefix("openai_whisper-") {
            // "openai_whisper-base" -> "base"
            // "openai_whisper-base.en" -> "base.en"
            // "openai_whisper-large-v3" -> "large-v3"
            let variant = modelId.replacingOccurrences(of: "openai_whisper-", with: "")
            return (variant, "argmaxinc/whisperkit-coreml")
        } else {
            // Fallback for other models
            return (modelId, "argmaxinc/whisperkit-coreml")
        }
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