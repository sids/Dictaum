//
//  MicRecorder.swift
//  Dictaum
//
//  Created by Siddhartha Reddy on 02/07/25.
//

import Foundation
import AVFoundation
import Accelerate

class MicRecorder {
    private var audioEngine = AVAudioEngine()
    private var inputNode: AVAudioInputNode?
    private var recordingBuffer = [Float]()
    private var isRecording = false
    private var hasTap = false
    private let audioQueue = DispatchQueue(label: "com.dictaum.audio", qos: .userInitiated)
    
    var onLevelUpdate: (([CGFloat]) -> Void)?
    
    private let targetSampleRate: Double = 16000
    private let bufferSize: AVAudioFrameCount = 1024
    
    private var levelTimer: Timer?
    private var currentLevels: [Float] = Array(repeating: 0, count: 32)
    private var levelsCGFloat: [CGFloat] = Array(repeating: 0, count: 32)
    
    // Pre-roll buffer for capturing audio before user starts recording
    private var prerollBuffer = [Float]()
    private let prerollDuration: Double = 0.25 // 250ms pre-roll buffer
    private var prerollSampleCount: Int { Int(targetSampleRate * prerollDuration) }
    private var isPrerollActive = false
    
    // Fade-in processing to prevent abrupt start artifacts
    private let fadeInDuration: Double = 0.02 // 20ms fade-in
    private var fadeInSampleCount: Int { Int(targetSampleRate * fadeInDuration) }
    
    // High-pass filter for noise reduction
    private var highPassFilter: AVAudioUnitEQ?
    private let highPassCutoff: Float = 80.0 // 80Hz cutoff
    
    // Audio level monitoring
    private let targetPeakLevel: Float = -12.0 // -12 dBFS target
    private let targetLevelTolerance: Float = 3.0 // ±3 dB tolerance
    
    init() {
        // Suppress verbose audio system warnings in console
        UserDefaults.standard.set(true, forKey: "com.apple.coreaudio.silenceOutput")
        
        setupAudioSession()
        setupHighPassFilter()
        startPrerollBuffer()
    }
    
    deinit {
        // Stop recording if active
        isRecording = false
        isPrerollActive = false
        
        // Stop and invalidate timer
        levelTimer?.invalidate()
        levelTimer = nil
        
        // Proper cleanup order: stop engine first, then remove taps
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        
        // Remove audio tap if installed
        removeTapIfNeeded()
        
        // Clear buffers
        recordingBuffer.removeAll()
        prerollBuffer.removeAll()
        
        // Clear callback to prevent retain cycles
        onLevelUpdate = nil
    }
    
    private func setupAudioSession() {
        #if os(macOS)
        #else
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.record, mode: .measurement)
        try? audioSession.setActive(true)
        #endif
    }
    
    func startRecording() async throws {
        guard !isRecording else { 
            print("[MicRecorder] Already recording, ignoring start request")
            return 
        }
        
        await requestMicrophonePermission()
        
        // Stop pre-roll buffer mode
        isPrerollActive = false
        isRecording = true
        recordingBuffer.removeAll()
        
        // Add pre-roll buffer to start of recording
        recordingBuffer.append(contentsOf: prerollBuffer)
        
        // Reset pre-roll buffer for next recording
        prerollBuffer.removeAll()
        
        inputNode = audioEngine.inputNode
        let recordingFormat = inputNode!.outputFormat(forBus: 0)
        
        // Create a compatible tap format based on the hardware format
        // but ensuring it matches what we can actually use
        let tapFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: recordingFormat.sampleRate,
            channels: recordingFormat.channelCount,
            interleaved: false
        )!
        
        let converter = AVAudioConverter(
            from: tapFormat,
            to: AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: targetSampleRate,
                channels: 1,
                interleaved: false
            )!
        )!
        
        // Safely remove existing tap and install new one
        audioQueue.sync {
            removeTapIfNeeded()
            
            inputNode!.installTap(onBus: 0, bufferSize: bufferSize, format: tapFormat) { [weak self] buffer, _ in
                guard let self = self else { return }
                
                let pcmBuffer = AVAudioPCMBuffer(
                    pcmFormat: converter.outputFormat,
                    frameCapacity: AVAudioFrameCount(
                        Double(buffer.frameLength) * (self.targetSampleRate / tapFormat.sampleRate)
                    )
                )!
                
                var error: NSError?
                converter.convert(to: pcmBuffer, error: &error) { _, outStatus in
                    outStatus.pointee = .haveData
                    return buffer
                }
                
                if error == nil {
                    let channelData = pcmBuffer.floatChannelData![0]
                    let frameLength = Int(pcmBuffer.frameLength)
                    let samples = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
                    
                    if self.isRecording {
                        self.recordingBuffer.append(contentsOf: samples)
                    } else {
                        // Still in pre-roll mode, add to pre-roll buffer
                        self.addToPrerollBuffer(samples)
                    }
                    
                    self.updateLevels(from: samples)
                } else {
                    print("Audio conversion error: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
            
            hasTap = true
        }
        
        if !audioEngine.isRunning {
            try audioEngine.start()
        }
        
        startLevelTimer()
    }
    
    func stopRecording() async throws -> [Float] {
        guard isRecording else { 
            print("[MicRecorder] Not recording, ignoring stop request")
            return [] 
        }
        
        isRecording = false
        stopLevelTimer()
        
        // Don't remove tap or stop engine - keep pre-roll buffer active
        logAudioLevels(samples: recordingBuffer, label: "Pre-processing")
        
        let filteredSamples = applyHighPassFilter(to: recordingBuffer)
        logAudioLevels(samples: filteredSamples, label: "After high-pass")
        
        let result = applyFadeIn(to: filteredSamples)
        logAudioLevels(samples: result, label: "Final processed")
        
        // Restart pre-roll buffer - but only if we're not already in the middle of cleanup
        if !isPrerollActive {
            startPrerollBuffer()
        }
        
        return result
    }
    
    private func requestMicrophonePermission() async {
        #if os(macOS)
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .notDetermined:
            _ = await AVCaptureDevice.requestAccess(for: .audio)
        case .denied, .restricted:
            print("Microphone access denied")
        case .authorized:
            break
        @unknown default:
            break
        }
        #endif
    }
    
    private func updateLevels(from samples: [Float]) {
        let chunkSize = samples.count / currentLevels.count
        guard chunkSize > 0 else { return }
        
        samples.withUnsafeBufferPointer { buffer in
            for i in 0..<currentLevels.count {
                let start = i * chunkSize
                let end = min(start + chunkSize, samples.count)
                let chunkLength = end - start
                
                var rms: Float = 0
                vDSP_rmsqv(buffer.baseAddress! + start, 1, &rms, vDSP_Length(chunkLength))
                
                let normalizedLevel = min(1.0, rms * 20)
                currentLevels[i] = currentLevels[i] * 0.7 + normalizedLevel * 0.3
            }
        }
    }
    
    private func startLevelTimer() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            // Convert to CGFloat array in-place to avoid allocations
            for i in 0..<self.currentLevels.count {
                self.levelsCGFloat[i] = CGFloat(self.currentLevels[i])
            }
            Task { @MainActor in
                self.onLevelUpdate?(self.levelsCGFloat)
            }
        }
    }
    
    private func stopLevelTimer() {
        levelTimer?.invalidate()
        levelTimer = nil
        // Reset levels in-place to avoid allocations
        for i in 0..<currentLevels.count {
            currentLevels[i] = 0
            levelsCGFloat[i] = 0
        }
        Task { @MainActor in
            self.onLevelUpdate?(levelsCGFloat)
        }
    }
    
    // MARK: - Pre-roll Buffer Methods
    
    private func startPrerollBuffer() {
        guard !isPrerollActive && !isRecording else { return }
        
        Task {
            await requestMicrophonePermission()
            
            isPrerollActive = true
            prerollBuffer.removeAll()
            
            inputNode = audioEngine.inputNode
            let recordingFormat = inputNode!.outputFormat(forBus: 0)
            
            // Use the same format creation logic as startRecording() to avoid format mismatch
            let tapFormat = AVAudioFormat(
                commonFormat: .pcmFormatFloat32,
                sampleRate: recordingFormat.sampleRate,
                channels: recordingFormat.channelCount,
                interleaved: false
            )!
            
            let converter = AVAudioConverter(
                from: tapFormat,
                to: AVAudioFormat(
                    commonFormat: .pcmFormatFloat32,
                    sampleRate: targetSampleRate,
                    channels: 1,
                    interleaved: false
                )!
            )!
            
            // Safely remove existing tap and install new one
            audioQueue.sync {
                removeTapIfNeeded()
                
                inputNode!.installTap(onBus: 0, bufferSize: bufferSize, format: tapFormat) { [weak self] buffer, _ in
                    guard let self = self else { return }
                    
                    let pcmBuffer = AVAudioPCMBuffer(
                        pcmFormat: converter.outputFormat,
                        frameCapacity: AVAudioFrameCount(
                            Double(buffer.frameLength) * (self.targetSampleRate / tapFormat.sampleRate)
                        )
                    )!
                    
                    var error: NSError?
                    converter.convert(to: pcmBuffer, error: &error) { _, outStatus in
                        outStatus.pointee = .haveData
                        return buffer
                    }
                    
                    if error == nil {
                        let channelData = pcmBuffer.floatChannelData![0]
                        let frameLength = Int(pcmBuffer.frameLength)
                        let samples = Array(UnsafeBufferPointer(start: channelData, count: frameLength))
                        
                        if self.isRecording {
                            self.recordingBuffer.append(contentsOf: samples)
                        } else {
                            self.addToPrerollBuffer(samples)
                        }
                        
                        self.updateLevels(from: samples)
                    } else {
                        print("Audio conversion error: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
                
                hasTap = true
            }
            
            if !audioEngine.isRunning {
                do {
                    try audioEngine.start()
                } catch {
                    print("Failed to start audio engine for pre-roll: \(error)")
                    isPrerollActive = false
                    hasTap = false
                }
            }
        }
    }
    
    private func addToPrerollBuffer(_ samples: [Float]) {
        prerollBuffer.append(contentsOf: samples)
        
        // Keep only the last prerollSampleCount samples
        if prerollBuffer.count > prerollSampleCount {
            let excessSamples = prerollBuffer.count - prerollSampleCount
            prerollBuffer.removeFirst(excessSamples)
        }
    }
    
    // MARK: - Tap Management
    
    private func removeTapIfNeeded() {
        guard hasTap && inputNode != nil else { return }
        
        // Always try to remove the tap, regardless of engine state
        // AVAudioEngine will handle the case where engine is stopped
        inputNode?.removeTap(onBus: 0)
        hasTap = false
    }
    
    // MARK: - Audio Processing Methods
    
    private func setupHighPassFilter() {
        highPassFilter = AVAudioUnitEQ(numberOfBands: 1)
        
        // Configure high-pass filter
        let band = highPassFilter!.bands[0]
        band.filterType = .highPass
        band.frequency = highPassCutoff
        band.bypass = false
    }
    
    private func applyFadeIn(to samples: [Float]) -> [Float] {
        guard samples.count > fadeInSampleCount else { return samples }
        
        var processedSamples = samples
        
        // Apply fade-in to the first fadeInSampleCount samples
        for i in 0..<fadeInSampleCount {
            let fadeFactor = Float(i) / Float(fadeInSampleCount)
            processedSamples[i] = samples[i] * fadeFactor
        }
        
        return processedSamples
    }
    
    private func applyHighPassFilter(to samples: [Float]) -> [Float] {
        // Create a simple high-pass filter implementation since AVAudioUnitEQ
        // requires being in the audio chain, not for direct processing
        return applyDigitalHighPassFilter(to: samples, cutoff: highPassCutoff)
    }
    
    private func applyDigitalHighPassFilter(to samples: [Float], cutoff: Float) -> [Float] {
        // Simple digital high-pass filter implementation
        // RC = 1 / (2 * π * cutoff)
        let rc = 1.0 / (2.0 * Float.pi * cutoff)
        let dt = 1.0 / Float(targetSampleRate)
        let alpha = rc / (rc + dt)
        
        var filteredSamples = samples
        var previousInput: Float = 0
        var previousOutput: Float = 0
        
        for i in 0..<filteredSamples.count {
            let currentInput = samples[i]
            let currentOutput = alpha * (previousOutput + currentInput - previousInput)
            filteredSamples[i] = currentOutput
            
            previousInput = currentInput
            previousOutput = currentOutput
        }
        
        return filteredSamples
    }
    
    // MARK: - Audio Level Monitoring
    
    private func logAudioLevels(samples: [Float], label: String) {
        let peakLevel = calculatePeakLevel(samples)
        let rmsLevel = calculateRMSLevel(samples)
        
        let peakDB = 20.0 * log10(abs(peakLevel))
        let rmsDB = 20.0 * log10(rmsLevel)
        
        print("[\(label)] Peak: \(String(format: "%.1f", peakDB)) dBFS, RMS: \(String(format: "%.1f", rmsDB)) dBFS")
        
        // Check if levels are within target range
        let targetMin = targetPeakLevel - targetLevelTolerance
        let targetMax = targetPeakLevel + targetLevelTolerance
        
        if peakDB < targetMin {
            print("[\(label)] WARNING: Audio level too low (\(String(format: "%.1f", peakDB)) dBFS < \(targetMin) dBFS)")
        } else if peakDB > targetMax {
            print("[\(label)] WARNING: Audio level too high (\(String(format: "%.1f", peakDB)) dBFS > \(targetMax) dBFS)")
        }
    }
    
    private func calculatePeakLevel(_ samples: [Float]) -> Float {
        return samples.max(by: { abs($0) < abs($1) }) ?? 0.0
    }
    
    private func calculateRMSLevel(_ samples: [Float]) -> Float {
        let sumOfSquares = samples.reduce(0) { $0 + ($1 * $1) }
        return sqrt(sumOfSquares / Float(samples.count))
    }
}