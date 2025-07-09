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
    
    var onLevelUpdate: (([CGFloat]) -> Void)?
    
    private let targetSampleRate: Double = 16000
    private let bufferSize: AVAudioFrameCount = 1024
    
    private var levelTimer: Timer?
    private var currentLevels: [Float] = Array(repeating: 0, count: 32)
    private var levelsCGFloat: [CGFloat] = Array(repeating: 0, count: 32)
    
    init() {
        setupAudioSession()
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
        
        isRecording = true
        recordingBuffer.removeAll()
        
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
        
        // Remove existing tap if any
        if hasTap {
            inputNode!.removeTap(onBus: 0)
            hasTap = false
        }
        
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
                
                self.recordingBuffer.append(contentsOf: samples)
                self.updateLevels(from: samples)
            } else {
                print("Audio conversion error: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
        
        hasTap = true
        
        try audioEngine.start()
        
        startLevelTimer()
    }
    
    func stopRecording() async throws -> [Float] {
        guard isRecording else { 
            print("[MicRecorder] Not recording, ignoring stop request")
            return [] 
        }
        
        isRecording = false
        stopLevelTimer()
        
        if hasTap {
            inputNode?.removeTap(onBus: 0)
            hasTap = false
        }
        
        audioEngine.stop()
        
        return recordingBuffer
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
}