//
//  HistoryDetailSheet.swift
//  Dictaum
//
//  Created by Siddhartha Reddy on 02/07/25.
//

import SwiftUI
import AVFoundation

struct HistoryDetailSheet: View {
    let entry: HistoryEntry
    let isPlayingAudio: Bool
    let onPlay: () -> Void
    let onDelete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteConfirmation = false
    @State private var isRerunning = false
    @State private var rerunError: String?
    
    // Transcription parameters for rerun
    @State private var temperature: Double = 0.2
    @State private var beamSize: Int = 1
    @State private var bestOf: Int = 1
    @State private var topK: Int = 5
    @State private var enableTimestamps: Bool = true
    @State private var selectedLanguage: String = "english"
    @State private var selectedModel: String = ""
    @State private var selectedPreset: String = "balanced"
    @State private var logProbThreshold: Double = -1.0
    @State private var compressionRatioThreshold: Double = 2.4
    @State private var suppressBlank: Bool = true
    
    // Original parameters for comparison
    @State private var originalTemperature: Double = 0.2
    @State private var originalBeamSize: Int = 1
    @State private var originalBestOf: Int = 1
    @State private var originalTopK: Int = 5
    @State private var originalModel: String = ""
    @State private var originalPreset: String = "balanced"
    @State private var originalLogProbThreshold: Double = -1.0
    @State private var originalCompressionRatioThreshold: Double = 2.4
    @State private var originalSuppressBlank: Bool = true
    
    // Modifiable transcript
    @State private var currentTranscript: String = ""
    
    // Original transcript for comparison
    @State private var originalTranscript: String = ""
    
    private let availableLanguages = ["english", "spanish", "french", "german", "italian", "portuguese", "dutch", "russian", "chinese", "japanese", "korean"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with title and buttons
            HStack {
                Text("Transcription Details")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: onPlay) {
                        HStack(spacing: 6) {
                            Image(systemName: isPlayingAudio ? "stop.fill" : "play.fill")
                                .font(.system(size: 14))
                            Text(isPlayingAudio ? "Stop" : "Play")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .help(isPlayingAudio ? "Stop audio" : "Play audio")
                    
                    Button(action: { showingDeleteConfirmation = true }) {
                        HStack(spacing: 6) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                            Text("Delete")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .help("Delete entry")
                    
                    Button(action: { dismiss() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12))
                            Text("Close")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.primary.opacity(0.08))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .help("Close")
                    .onHover { isHovering in
                        // Visual feedback on hover
                    }
                }
            }
            .padding()
            
            Divider()
            
            // Form content
            Form {
                // Metadata Section
                Section {
                    HStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Date & Time")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(entry.formattedTimestamp)
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Duration")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(entry.formattedDuration)
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                
                // Transcription Section
                Section {
                    ScrollView {
                        Text(currentTranscript.isEmpty ? "No transcription available" : currentTranscript)
                            .font(.body)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    .frame(minHeight: 120, maxHeight: 200)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                    )
                } header: {
                    Text("Transcription")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondaryAccent)
                }
                
                // Model & Parameters Section
                Section {
                    // Model Selection
                    HStack {
                        Text("Model")
                            .font(.headline)
                            .fontWeight(.medium)
                                                        
                        Text("Original: \(entry.modelUsed.isEmpty ? "Unknown" : modelDisplayName(entry.modelUsed))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Picker("", selection: $selectedModel) {
                            ForEach(availableModels, id: \.id) { model in
                                Text(model.displayName).tag(model.id)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }

                    // Presets Selection
                    HStack {
                        Text("Presets")
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Picker("", selection: $selectedPreset) {
                            Text("Conservative").tag("conservative")
                            Text("Balanced").tag("balanced")
                            Text("Creative").tag("creative")
                            Text("Custom").tag("custom")
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        .onChange(of: selectedPreset) { _, newValue in
                            applyPreset(newValue)
                        }
                    }

                    // Temperature
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Temperature")
                                .font(.system(size: 13))
                            Spacer()
                            Text(String(format: "%.1f", temperature))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        if selectedPreset == "custom" {
                            Slider(value: $temperature, in: 0.0...1.0, step: 0.1)
                        } else {
                            ProgressView(value: temperature, total: 1.0)
                                .tint(.gray)
                                .opacity(0.5)
                        }
                        
                        Text("Controls randomness. Lower = more consistent, Higher = more creative")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                    
                    // Beam Size
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Beam Size")
                                .font(.system(size: 13))
                            Spacer()
                            Text("\(beamSize)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        if selectedPreset == "custom" {
                            Slider(
                                value: Binding(
                                    get: { Double(beamSize) },
                                    set: { beamSize = Int($0) }
                                ),
                                in: 1.0...5.0,
                                step: 1.0
                            )
                        } else {
                            ProgressView(value: Double(beamSize), total: 5.0)
                                .tint(.gray)
                                .opacity(0.5)
                        }
                        
                        Text("Search width. Higher = more accurate but slower")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                    
                    // Best Of
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Best Of")
                                .font(.system(size: 13))
                                .foregroundColor(selectedPreset == "custom" && temperature == 0.0 ? .secondary : .primary)
                            Spacer()
                            Text("\(bestOf)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        if selectedPreset == "custom" {
                            Slider(
                                value: Binding(
                                    get: { Double(bestOf) },
                                    set: { bestOf = Int($0) }
                                ),
                                in: 1.0...5.0,
                                step: 1.0
                            )
                            .disabled(temperature == 0.0)
                        } else {
                            ProgressView(value: Double(bestOf), total: 5.0)
                                .tint(.gray)
                                .opacity(0.5)
                        }
                        
                        Text("Number of candidates to consider. Only used when temperature > 0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                    
                    // Top K
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Top K")
                                .font(.system(size: 13))
                            Spacer()
                            Text("\(topK)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        if selectedPreset == "custom" {
                            Slider(
                                value: Binding(
                                    get: { Double(topK) },
                                    set: { topK = Int($0) }
                                ),
                                in: 1.0...50.0,
                                step: 1.0
                            )
                        } else {
                            ProgressView(value: Double(topK), total: 50.0)
                                .tint(.gray)
                                .opacity(0.5)
                        }
                        
                        Text("Limits vocabulary choices. Lower = more focused")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                } header: {
                    HStack {
                        Text("Model & Parameters")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondaryAccent)
                        
                        Spacer()
                        
                        HStack {
                            Spacer()
                            
                            if isRerunning {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                    Text("Processing...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                HStack(spacing: 8) {
                                    Button("Reset") {
                                        resetToOriginal()
                                    }
                                    .buttonStyle(.bordered)
                                    .disabled(!hasChanges)
                                    
                                    Button("Rerun") {
                                        performRerun()
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(isRerunning)
                                }
                            }
                        }
                    }
                }
                
                // Quality Control Section - Only show in custom mode
                if selectedPreset == "custom" {
                    Section {
                        // Log Probability Threshold
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Log Probability Threshold")
                                    .font(.system(size: 13))
                                Spacer()
                                Text(String(format: "%.1f", logProbThreshold))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            Slider(value: $logProbThreshold, in: -5.0...0.0, step: 0.1)
                            
                            Text("Reject transcriptions below this confidence. -1.0 = moderate, 0.0 = strict")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                        
                        // Compression Ratio Threshold
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Compression Ratio Threshold")
                                    .font(.system(size: 13))
                                Spacer()
                                Text(String(format: "%.1f", compressionRatioThreshold))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            Slider(value: $compressionRatioThreshold, in: 1.5...3.0, step: 0.1)
                            
                            Text("Detect repetitive output. Lower = more sensitive to repetition")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                        
                        // Suppress Blank
                        VStack(alignment: .leading, spacing: 4) {
                            Toggle("Suppress Blank Tokens", isOn: $suppressBlank)
                            
                            Text("Remove empty tokens from the beginning of transcription")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                    } header: {
                        Text("Quality Control")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondaryAccent)
                    }
                }
                
                // Error Display Section
                if let rerunError = rerunError {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.red)
                            Text(rerunError)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    } header: {
                        Text("Error")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(minWidth: 600, minHeight: 500)
        .onAppear {
            initializeParameters()
        }
        .alert("Delete Entry", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this transcription entry? This action cannot be undone.")
        }
    }
    
    // MARK: - Computed Properties
    
    private var hasChanges: Bool {
        let parameterChanges = selectedModel != originalModel ||
                              temperature != originalTemperature ||
                              beamSize != originalBeamSize ||
                              bestOf != originalBestOf ||
                              topK != originalTopK ||
                              selectedPreset != originalPreset
        
        let qualityChanges = logProbThreshold != originalLogProbThreshold ||
                            compressionRatioThreshold != originalCompressionRatioThreshold ||
                            suppressBlank != originalSuppressBlank
        
        let transcriptChanges = currentTranscript != originalTranscript
        
        return parameterChanges || qualityChanges || transcriptChanges
    }
    
    private var availableModels: [ModelInfo] {
        return ModelManager.shared.availableModels.filter { model in
            ModelManager.shared.isModelDownloaded(model.id)
        }
    }
    
    private func modelDisplayName(_ modelId: String) -> String {
        return availableModels.first { $0.id == modelId }?.displayName ?? modelId
    }
    
    // MARK: - Helper Functions
    
    private func resetToOriginal() {
        selectedModel = originalModel
        temperature = originalTemperature
        beamSize = originalBeamSize
        bestOf = originalBestOf
        topK = originalTopK
        selectedPreset = originalPreset
        logProbThreshold = originalLogProbThreshold
        compressionRatioThreshold = originalCompressionRatioThreshold
        suppressBlank = originalSuppressBlank
        currentTranscript = originalTranscript
        rerunError = nil
    }
    
    private func applyPreset(_ preset: String) {
        switch preset {
        case "conservative":
            temperature = 0.0
            beamSize = 1
            bestOf = 1
        case "balanced":
            temperature = 0.2
            beamSize = 3
            bestOf = 1
        case "creative":
            temperature = 0.4
            beamSize = 5
            bestOf = 3
        default:
            break // Custom - don't change values
        }
    }
    
    private func initializeParameters() {
        // Initialize current transcript
        currentTranscript = entry.transcript
        originalTranscript = entry.transcript
        
        // Initialize parameters from the entry's quality data or defaults
        if let quality = entry.quality {
            temperature = quality.temperature
            beamSize = quality.beamSize
            bestOf = quality.bestOf
            topK = quality.topK
            enableTimestamps = quality.enableTimestamps
            logProbThreshold = quality.avgLogProb ?? -1.0
            compressionRatioThreshold = quality.compressionRatio ?? 2.4
            
            // Determine preset based on parameters
            if temperature == 0.0 && beamSize == 1 && bestOf == 1 {
                selectedPreset = "conservative"
            } else if temperature == 0.2 && beamSize == 3 && bestOf == 1 {
                selectedPreset = "balanced" 
            } else if temperature == 0.4 && beamSize == 5 && bestOf == 3 {
                selectedPreset = "creative"
            } else {
                selectedPreset = "custom"
            }
        } else {
            // Use default values from SettingsStore
            let settings = SettingsStore.shared
            temperature = settings.temperature
            beamSize = settings.beamSize
            bestOf = settings.bestOf
            topK = settings.topK
            enableTimestamps = settings.enableTimestamps
            selectedPreset = settings.selectedPreset
            logProbThreshold = settings.logProbThreshold
            compressionRatioThreshold = settings.compressionRatioThreshold
            suppressBlank = settings.suppressBlank
        }
        
        selectedLanguage = entry.language
        selectedModel = entry.modelUsed.isEmpty ? SettingsStore.shared.selectedModel : entry.modelUsed
        
        // Store original values for comparison (excluding language and timestamps - use entry values for those)
        originalTemperature = temperature
        originalBeamSize = beamSize
        originalBestOf = bestOf
        originalTopK = topK
        originalModel = selectedModel
        originalPreset = selectedPreset
        originalLogProbThreshold = logProbThreshold
        originalCompressionRatioThreshold = compressionRatioThreshold
        originalSuppressBlank = suppressBlank
    }
    
    private func performRerun() {
        guard !isRerunning else { return }
        
        isRerunning = true
        rerunError = nil
        
        Task {
            do {
                // Load audio file
                guard let audioURL = HistoryManager.shared.getAudioFileURL(for: entry),
                      let audioData = try? Data(contentsOf: audioURL) else {
                    await MainActor.run {
                        rerunError = "Failed to load audio file"
                        isRerunning = false
                    }
                    return
                }
                
                // Convert audio data to samples
                let audioSamples = try await convertAudioDataToSamples(audioData)
                
                // Create transcriber with new parameters
                let transcriber = try await Transcriber(modelName: selectedModel)
                
                // Apply the custom parameters
                transcriber.setTemperature(Float(temperature))
                transcriber.setBeamSize(beamSize)
                transcriber.setBestOf(bestOf)
                transcriber.topK = topK
                transcriber.setLanguage(entry.language) // Use original entry language
                transcriber.enableTimestamps(entry.quality?.enableTimestamps ?? enableTimestamps) // Use original entry timestamps setting
                
                // Set quality control parameters if in custom mode
                if selectedPreset == "custom" {
                    transcriber.logProbThreshold = Float(logProbThreshold)
                    transcriber.compressionRatioThreshold = Float(compressionRatioThreshold)
                    transcriber.suppressBlank = suppressBlank
                }
                
                // Perform transcription
                let result = try await transcriber.transcribe(audioSamples)
                
                await MainActor.run {
                    // Replace the current transcript with the new result
                    currentTranscript = result ?? "No transcription result"
                    isRerunning = false
                }
                
            } catch {
                await MainActor.run {
                    rerunError = "Transcription failed: \(error.localizedDescription)"
                    isRerunning = false
                }
            }
        }
    }
    
    private func convertAudioDataToSamples(_ audioData: Data) async throws -> [Float] {
        // This is a simplified implementation. In reality, you'd need to:
        // 1. Parse the WAV file header
        // 2. Extract the audio samples
        // 3. Convert to the correct format (16kHz mono Float32)
        
        return try await withCheckedThrowingContinuation { continuation in
            do {
                // Create temporary file URL
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".wav")
                try audioData.write(to: tempURL)
                defer { try? FileManager.default.removeItem(at: tempURL) }
                
                // Use AVAudioFile to read the audio data
                let audioFile = try AVAudioFile(forReading: tempURL)
                let format = audioFile.processingFormat
                
                let frameCount = AVAudioFrameCount(audioFile.length)
                guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
                    throw NSError(domain: "AudioConversion", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create audio buffer"])
                }
                
                try audioFile.read(into: buffer)
                
                // Convert to Float array (assuming mono channel)
                let samples: [Float]
                if let floatChannelData = buffer.floatChannelData {
                    let channelCount = Int(format.channelCount)
                    let frameLength = Int(buffer.frameLength)
                    
                    if channelCount == 1 {
                        // Mono
                        samples = Array(UnsafeBufferPointer(start: floatChannelData[0], count: frameLength))
                    } else {
                        // Convert stereo to mono by averaging channels
                        samples = (0..<frameLength).map { frame in
                            var sum: Float = 0
                            for channel in 0..<channelCount {
                                sum += floatChannelData[channel][frame]
                            }
                            return sum / Float(channelCount)
                        }
                    }
                } else {
                    throw NSError(domain: "AudioConversion", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to access audio data"])
                }
                
                continuation.resume(returning: samples)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}