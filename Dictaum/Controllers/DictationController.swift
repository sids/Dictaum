//
//  DictationController.swift
//  Dictaum
//
//  Created by Siddhartha Reddy on 02/07/25.
//

import Foundation
import SwiftUI
import Combine
import AVFoundation

enum DictationState: Equatable {
    case idle
    case recording
    case processing
    case error(String)
}

@MainActor
class DictationController: ObservableObject {
    static var shared: DictationController?
    
    @Published private(set) var state: DictationState = .idle
    @Published private(set) var isRecording: Bool = false
    @Published var audioLevels: [CGFloat] = Array(repeating: 0, count: 32)
    @Published private(set) var isTranscriberReady: Bool = false
    
    private var micRecorder: MicRecorder?
    private var transcriber: Transcriber?
    private let pasteService = PasteService()
    private let overlayWindow: OverlayWindow
    private let shortcutCenter = ShortcutCenter()
    
    private var recordingTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.overlayWindow = OverlayWindow()
        DictationController.shared = self
        setupShortcuts()
        setupAudioSession()
        observeModelChanges()
        
        // Initialize window monitors
        _ = SettingsWindowMonitor.shared
        _ = HistoryWindowMonitor.shared
        
        Task {
            await setupTranscriberIfNeeded()
        }
    }
    
    deinit {
        // Cancel any ongoing recording task
        recordingTask?.cancel()
        
        // Cancel all Combine subscriptions
        cancellables.removeAll()
        
        // Clean up MicRecorder resources
        micRecorder = nil
        
        // Clean up transcriber
        transcriber = nil
        
        // Note: We can't safely clean up @MainActor isolated properties from deinit
        // The overlay window and shared instance will be cleaned up automatically
        // when the object is deallocated, or can be handled by the app lifecycle
    }
    
    private func setupShortcuts() {
        shortcutCenter.onDictationTap = { [weak self] in
            Task { @MainActor in
                await self?.toggleRecording()
            }
        }
        
        shortcutCenter.onDictationHoldStart = { [weak self] in
            Task { @MainActor in
                await self?.startRecording()
            }
        }
        
        shortcutCenter.onDictationHoldEnd = { [weak self] in
            Task { @MainActor in
                await self?.stopRecording()
            }
        }
        
        shortcutCenter.installHandlers()
    }
    
    private func setupAudioSession() {
        micRecorder = MicRecorder()
        micRecorder?.onLevelUpdate = { [weak self] levels in
            Task { @MainActor in
                self?.audioLevels = levels
            }
        }
    }
    
    private func setupTranscriberIfNeeded() async {
        let selectedModel = SettingsStore.shared.selectedModel
        
        guard !selectedModel.isEmpty else {
            print("No model selected, transcriber will be initialized when model is selected")
            return
        }
        
        guard ModelManager.shared.isModelDownloaded(selectedModel) else {
            print("Model \(selectedModel) not downloaded, transcriber will be initialized when model is available")
            return
        }
        
        await setupTranscriber()
    }
    
    private func setupTranscriber() async {
        let selectedModel = SettingsStore.shared.selectedModel
        
        guard !selectedModel.isEmpty else {
            print("No model selected, skipping transcriber setup")
            state = .error("No model selected. Please select and download a model first.")
            return
        }
        
        guard ModelManager.shared.isModelDownloaded(selectedModel) else {
            print("Model \(selectedModel) not downloaded, skipping transcriber setup")
            state = .error("Selected model not downloaded. Please download the model first.")
            return
        }
        
        do {
            transcriber = try await Transcriber(modelName: selectedModel)
            await updateTranscriberParameters()
            isTranscriberReady = true
            state = .idle
        } catch {
            print("Failed to setup transcriber: \(error)")
            state = .error("Failed to initialize transcription model: \(error.localizedDescription)")
            transcriber = nil
            isTranscriberReady = false
            // Clear the selected model if initialization fails
            SettingsStore.shared.selectedModel = ""
        }
    }
    
    private func observeModelChanges() {
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    guard let self = self else { return }
                    let currentModel = self.transcriber?.modelName ?? ""
                    let newModel = SettingsStore.shared.selectedModel
                    if currentModel != newModel {
                        await self.setupTranscriberIfNeeded()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    
    func toggleRecording() async {
        if isRecording {
            await stopRecording()
        } else {
            await startRecording()
        }
    }
    
    func startRecording() async {
        guard state == .idle else { 
            print("[DictationController] Not in idle state (\(state)), ignoring start request")
            return 
        }
        
        // Cancel any existing recording task
        recordingTask?.cancel()
        recordingTask = nil
        
        // Check if a model is selected before attempting to start recording
        let selectedModel = SettingsStore.shared.selectedModel
        if selectedModel.isEmpty {
            print("[DictationController] No model selected, opening settings")
            SettingsStore.shared.openSettingsWithModelTab()
            return
        }
        
        // Ensure transcriber is available before starting recording
        if transcriber == nil {
            await setupTranscriberIfNeeded()
        }
        
        guard transcriber != nil else {
            print("[DictationController] No transcriber available, opening settings")
            SettingsStore.shared.openSettingsWithModelTab()
            return
        }
        
        state = .recording
        isRecording = true
        
        overlayWindow.show(with: audioLevels)
        
        recordingTask = Task {
            do {
                try await micRecorder?.startRecording()
            } catch {
                await handleError(error)
            }
        }
    }
    
    func stopRecording() async {
        guard state == .recording else { 
            print("[DictationController] Not in recording state (\(state)), ignoring stop request")
            return 
        }
        
        // Cancel recording task if any
        recordingTask?.cancel()
        recordingTask = nil
        
        state = .processing
        isRecording = false
        
        overlayWindow.startProcessing()
        
        do {
            let audioBuffer = try await micRecorder?.stopRecording()
            
            if let buffer = audioBuffer, !buffer.isEmpty {
                print("Transcribing complete buffer of \(buffer.count) samples")
                let transcription = try await transcriber?.transcribe(buffer)
                if let text = transcription, !text.isEmpty {
                    // Capture for history if enabled
                    if SettingsStore.shared.historyEnabled {
                        await captureHistoryEntry(audioBuffer: buffer, transcript: text)
                    }
                    
                    print("Pasting transcribed text: '\(text)'")
                    pasteService.paste(text)
                } else {
                    print("No transcription result")
                }
            } else {
                print("No audio buffer to transcribe")
            }
            
            state = .idle
            overlayWindow.hide()
        } catch {
            await handleError(error)
        }
    }
    
    private func handleError(_ error: Error) async {
        state = .error(error.localizedDescription)
        isRecording = false
        overlayWindow.hide()
        
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        state = .idle
    }
    
    func updateTranscriberLanguage(_ language: String) async {
        guard let transcriber = transcriber else { return }
        
        transcriber.setLanguage(language)
        print("Updated transcriber language to: \(language)")
    }
    
    func updateTranscriberParameters() async {
        guard let transcriber = transcriber else { return }
        
        let settings = SettingsStore.shared
        
        transcriber.setTemperature(Float(settings.temperature))
        transcriber.setBeamSize(settings.beamSize)
        transcriber.setBestOf(settings.bestOf)
        transcriber.topK = settings.topK
        // topP not supported by WhisperKit
        transcriber.enableTimestamps(settings.enableTimestamps)
        transcriber.logProbThreshold = Float(settings.logProbThreshold)
        transcriber.compressionRatioThreshold = Float(settings.compressionRatioThreshold)
        transcriber.suppressBlank = settings.suppressBlank
        
        print("Updated transcriber parameters from settings")
    }
    
    private func captureHistoryEntry(audioBuffer: [Float], transcript: String) async {
        guard transcriber != nil else { return }
        
        let timestamp = Date()
        let duration = Double(audioBuffer.count) / 16000.0 // 16kHz sample rate
        let settings = SettingsStore.shared
        
        // Convert audio buffer to WAV data
        let audioData = convertAudioBufferToWAV(audioBuffer: audioBuffer)
        
        // Save audio file
        guard let audioFilePath = HistoryManager.shared.saveAudioFile(data: audioData, timestamp: timestamp) else {
            print("Failed to save audio file for history")
            return
        }
        
        // Create quality metrics
        let quality = TranscriptionQuality(
            temperature: settings.temperature,
            beamSize: settings.beamSize,
            bestOf: settings.bestOf,
            topK: settings.topK,
            enableTimestamps: settings.enableTimestamps
        )
        
        // Create history entry
        let historyEntry = HistoryEntry(
            timestamp: timestamp,
            audioFilePath: audioFilePath,
            transcript: transcript,
            duration: duration,
            modelUsed: settings.selectedModel,
            language: settings.selectedLanguage,
            quality: quality
        )
        
        // Save to history
        HistoryManager.shared.addEntry(historyEntry)
        
        print("Captured history entry: \(transcript.prefix(50))...")
    }
    
    private func convertAudioBufferToWAV(audioBuffer: [Float]) -> Data {
        // Convert Float array to Data in WAV format
        let sampleRate: Int32 = 16000
        let channels: Int16 = 1
        let bitsPerSample: Int16 = 16
        
        // Convert Float samples to Int16
        let int16Samples = audioBuffer.map { sample in
            Int16(max(-32768, min(32767, sample * 32767)))
        }
        
        // Create WAV header
        let dataSize = int16Samples.count * 2 // 2 bytes per sample
        let fileSize = 44 + dataSize - 8 // Total file size - 8 bytes
        
        var wavData = Data()
        
        // RIFF header
        wavData.append("RIFF".data(using: .ascii)!)
        wavData.append(withUnsafeBytes(of: Int32(fileSize).littleEndian) { Data($0) })
        wavData.append("WAVE".data(using: .ascii)!)
        
        // fmt chunk
        wavData.append("fmt ".data(using: .ascii)!)
        wavData.append(withUnsafeBytes(of: Int32(16).littleEndian) { Data($0) }) // chunk size
        wavData.append(withUnsafeBytes(of: Int16(1).littleEndian) { Data($0) }) // audio format (PCM)
        wavData.append(withUnsafeBytes(of: channels.littleEndian) { Data($0) })
        wavData.append(withUnsafeBytes(of: sampleRate.littleEndian) { Data($0) })
        wavData.append(withUnsafeBytes(of: (sampleRate * Int32(channels) * Int32(bitsPerSample) / 8).littleEndian) { Data($0) }) // byte rate
        wavData.append(withUnsafeBytes(of: (channels * bitsPerSample / 8).littleEndian) { Data($0) }) // block align
        wavData.append(withUnsafeBytes(of: bitsPerSample.littleEndian) { Data($0) })
        
        // data chunk
        wavData.append("data".data(using: .ascii)!)
        wavData.append(withUnsafeBytes(of: Int32(dataSize).littleEndian) { Data($0) })
        
        // Audio data
        for sample in int16Samples {
            wavData.append(withUnsafeBytes(of: sample.littleEndian) { Data($0) })
        }
        
        return wavData
    }
}
