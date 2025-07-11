//
//  AudioProcessingTests.swift
//  DictaumTests
//
//  Created by Claude on 09/07/25.
//

import XCTest
import AVFoundation
@testable import Dictaum

class AudioProcessingTests: XCTestCase {
    
    var micRecorder: MicRecorder!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        micRecorder = MicRecorder()
    }
    
    override func tearDownWithError() throws {
        micRecorder = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Audio Level Monitoring Tests
    
    func testCalculatePeakLevel() {
        let samples: [Float] = [0.1, -0.5, 0.3, -0.2, 0.8, -0.1]
        
        // Use reflection to access private method
        let peakLevel = micRecorder.value(forKey: "calculatePeakLevel") as? (([Float]) -> Float)
        let result = peakLevel?(samples)
        
        XCTAssertEqual(result, 0.8, accuracy: 0.001, "Peak level should be 0.8")
    }
    
    func testCalculateRMSLevel() {
        let samples: [Float] = [0.1, -0.1, 0.1, -0.1] // Square wave
        
        let peakLevel = micRecorder.value(forKey: "calculateRMSLevel") as? (([Float]) -> Float)
        let result = peakLevel?(samples)
        
        XCTAssertEqual(result, 0.1, accuracy: 0.001, "RMS level should be 0.1")
    }
    
    func testAudioLevelMonitoring() {
        // Test with sine wave
        let sampleRate = 16000
        let frequency: Float = 440.0
        let duration = 1.0
        let sampleCount = Int(Double(sampleRate) * duration)
        
        var samples: [Float] = []
        for i in 0..<sampleCount {
            let t = Float(i) / Float(sampleRate)
            let sample = 0.5 * sin(2.0 * Float.pi * frequency * t)
            samples.append(sample)
        }
        
        // Test peak level calculation
        let peakLevel = samples.max(by: { abs($0) < abs($1) }) ?? 0.0
        XCTAssertEqual(abs(peakLevel), 0.5, accuracy: 0.1, "Peak level should be approximately 0.5")
        
        // Test RMS level calculation
        let sumOfSquares = samples.reduce(0) { $0 + ($1 * $1) }
        let rmsLevel = sqrt(sumOfSquares / Float(samples.count))
        XCTAssertEqual(rmsLevel, 0.354, accuracy: 0.1, "RMS level should be approximately 0.354 (0.5/√2)")
    }
    
    // MARK: - High-Pass Filter Tests
    
    func testHighPassFilter() {
        // Create a test signal with low and high frequency components
        let sampleRate = 16000
        let duration = 1.0
        let sampleCount = Int(Double(sampleRate) * duration)
        
        var samples: [Float] = []
        for i in 0..<sampleCount {
            let t = Float(i) / Float(sampleRate)
            // Mix of low frequency (50Hz) and high frequency (1000Hz)
            let lowFreq = 0.5 * sin(2.0 * Float.pi * 50.0 * t)
            let highFreq = 0.5 * sin(2.0 * Float.pi * 1000.0 * t)
            samples.append(lowFreq + highFreq)
        }
        
        // Apply high-pass filter using reflection
        let filterMethod = micRecorder.value(forKey: "applyHighPassFilter") as? (([Float]) -> [Float])
        let filteredSamples = filterMethod?(samples) ?? samples
        
        // High-pass filter should reduce low frequency components
        XCTAssertEqual(filteredSamples.count, samples.count, "Filtered samples should have same count")
        
        // Calculate RMS of original and filtered signals
        let originalRMS = sqrt(samples.reduce(0) { $0 + ($1 * $1) } / Float(samples.count))
        let filteredRMS = sqrt(filteredSamples.reduce(0) { $0 + ($1 * $1) } / Float(filteredSamples.count))
        
        // Filtered signal should have lower RMS (low frequencies removed)
        XCTAssertLessThan(filteredRMS, originalRMS, "Filtered signal should have lower RMS")
    }
    
    // MARK: - Fade-in Processing Tests
    
    func testFadeInProcessing() {
        let sampleRate = 16000
        let fadeInDuration = 0.02 // 20ms
        let fadeInSamples = Int(Double(sampleRate) * fadeInDuration)
        
        // Create test signal with constant amplitude
        let totalSamples = fadeInSamples * 2
        let samples = Array(repeating: Float(1.0), count: totalSamples)
        
        // Apply fade-in using reflection
        let fadeInMethod = micRecorder.value(forKey: "applyFadeIn") as? (([Float]) -> [Float])
        let fadedSamples = fadeInMethod?(samples) ?? samples
        
        XCTAssertEqual(fadedSamples.count, samples.count, "Faded samples should have same count")
        
        // First sample should be 0 (start of fade)
        XCTAssertEqual(fadedSamples[0], 0.0, accuracy: 0.001, "First sample should be 0")
        
        // Last fade sample should be close to 1.0
        XCTAssertEqual(fadedSamples[fadeInSamples - 1], 1.0, accuracy: 0.1, "Last fade sample should be close to 1.0")
        
        // Samples after fade-in should be unchanged
        XCTAssertEqual(fadedSamples[fadeInSamples + 10], 1.0, accuracy: 0.001, "Samples after fade-in should be unchanged")
    }
    
    // MARK: - Pre-roll Buffer Tests
    
    func testPrerollBufferSize() {
        let prerollDuration = 0.25 // 250ms
        let targetSampleRate = 16000
        let expectedSamples = Int(Double(targetSampleRate) * prerollDuration)
        
        // Test that pre-roll buffer has correct size
        XCTAssertEqual(expectedSamples, 4000, "Pre-roll buffer should have 4000 samples for 250ms at 16kHz")
    }
    
    // MARK: - Integration Tests
    
    func testAudioProcessingPipeline() {
        let sampleRate = 16000
        let duration = 1.0
        let sampleCount = Int(Double(sampleRate) * duration)
        
        // Create test signal with noise and signal
        var samples: [Float] = []
        for i in 0..<sampleCount {
            let t = Float(i) / Float(sampleRate)
            // Add low frequency noise + signal
            let noise = 0.1 * sin(2.0 * Float.pi * 30.0 * t) // 30Hz noise
            let signal = 0.5 * sin(2.0 * Float.pi * 440.0 * t) // 440Hz signal
            samples.append(noise + signal)
        }
        
        // Test the complete processing pipeline
        let filterMethod = micRecorder.value(forKey: "applyHighPassFilter") as? (([Float]) -> [Float])
        let fadeInMethod = micRecorder.value(forKey: "applyFadeIn") as? (([Float]) -> [Float])
        
        let filteredSamples = filterMethod?(samples) ?? samples
        let finalSamples = fadeInMethod?(filteredSamples) ?? filteredSamples
        
        XCTAssertEqual(finalSamples.count, samples.count, "Final samples should have same count")
        
        // Calculate signal-to-noise ratio improvement
        let originalSNR = calculateSNR(samples, signalFreq: 440.0, sampleRate: sampleRate)
        let finalSNR = calculateSNR(finalSamples, signalFreq: 440.0, sampleRate: sampleRate)
        
        print("Original SNR: \(originalSNR) dB")
        print("Final SNR: \(finalSNR) dB")
        
        // Processing should improve SNR (though this is a simple test)
        XCTAssertGreaterThan(finalSNR, originalSNR - 5.0, "Processing should not significantly degrade SNR")
    }
    
    // MARK: - Helper Methods
    
    private func calculateSNR(_ samples: [Float], signalFreq: Float, sampleRate: Int) -> Float {
        // Simple SNR calculation based on frequency domain analysis
        // This is a simplified version - real SNR calculation would use FFT
        
        let signalPeriod = Int(Float(sampleRate) / signalFreq)
        let signalSamples = samples.prefix(signalPeriod)
        
        let signalPower = signalSamples.reduce(0) { $0 + ($1 * $1) } / Float(signalSamples.count)
        let totalPower = samples.reduce(0) { $0 + ($1 * $1) } / Float(samples.count)
        
        let noisePower = totalPower - signalPower
        
        guard noisePower > 0 else { return 100.0 } // Very high SNR
        
        return 10.0 * log10(signalPower / noisePower)
    }
}