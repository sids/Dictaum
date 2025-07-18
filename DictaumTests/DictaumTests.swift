//
//  DictaumTests.swift
//  DictaumTests
//
//  Created by Siddhartha Reddy on 02/07/25.
//

import Testing
@testable import Dictaum
import AVFoundation

struct DictaumTests {

    @Test func testModelManagerUtilsPathGeneration() async throws {
        let modelId = "openai_whisper-base.en"
        let paths = ModelManagerUtils.getModelPaths(for: modelId)
        
        #expect(!paths.isEmpty)
        
        // Should contain WhisperKit specific paths
        let whisperKitPaths = paths.filter { $0.path.contains("whisperkit-coreml") }
        #expect(!whisperKitPaths.isEmpty)
        
        // Should contain OpenAI transformed path
        let openaiPaths = paths.filter { $0.path.contains("whisper-base.en") }
        #expect(!openaiPaths.isEmpty)
    }
    
    @Test func testOpenAIModelNameTransformation() async throws {
        let modelId = "openai_whisper-base.en"
        let paths = ModelManagerUtils.getModelPaths(for: modelId)
        
        // Check that OpenAI model name transformation works correctly
        let transformedName = "whisper-base.en"
        let hasTransformedPath = paths.contains { $0.path.contains(transformedName) }
        #expect(hasTransformedPath)
    }
    
    @Test func testSettingsStoreDefaults() async throws {
        let store = SettingsStore.shared
        
        // Test default values
        #expect(store.launchAtLogin == false)
        #expect(store.selectedModel == "")
        #expect(store.showDownloadModal == false)
        #expect(store.downloadingModelId == nil)
    }
    
    @Test func testPermissionManagerInitialization() async throws {
        let manager = PermissionManager.shared
        
        // Should have valid permission status values
        #expect(manager.microphonePermissionStatus != nil)
        #expect(manager.accessibilityPermissionStatus != nil)
    }
    
    @Test func testModelInfoProperties() async throws {
        let model = ModelInfo(
            id: "test-model",
            name: "test-model",
            displayName: "Test Model",
            diskSize: "100 MB",
            memoryUsage: "~500 MB",
            attributes: [.balanced, .lowMemory],
            isEnglishOnly: true,
            recommendation: "Good for testing"
        )
        
        #expect(model.id == "test-model")
        #expect(model.attributes.contains(.balanced))
        #expect(model.attributes.contains(.lowMemory))
        #expect(model.isEnglishOnly == true)
        #expect(model.recommendation == "Good for testing")
    }
    
    @Test func testModelAttributeColors() async throws {
        // Test that all attribute levels have distinct colors
        let attributes: [ModelInfo.ModelAttribute] = [.veryFast, .fast, .balanced, .accurate, .mostAccurate, .lowMemory, .recommended]
        let colors = attributes.map { $0.color }
        
        // Check that we have colors for all attributes
        #expect(colors.count == attributes.count)
        
        // Test specific color mappings
        #expect(ModelInfo.ModelAttribute.veryFast.color == .green)
        #expect(ModelInfo.ModelAttribute.mostAccurate.color == .red)
        #expect(ModelInfo.ModelAttribute.balanced.color == .blue)
        #expect(ModelInfo.ModelAttribute.lowMemory.color == .purple)
        #expect(ModelInfo.ModelAttribute.recommended.color == .accentColor)
    }
    
    @Test func testDictationStateEquality() async throws {
        let idle1 = DictationState.idle
        let idle2 = DictationState.idle
        let recording = DictationState.recording
        let error1 = DictationState.error("Test error")
        let error2 = DictationState.error("Test error")
        let errorDifferent = DictationState.error("Different error")
        
        #expect(idle1 == idle2)
        #expect(idle1 != recording)
        #expect(error1 == error2)
        #expect(error1 != errorDifferent)
    }
    
    @Test func testShortcutCenterInitialization() async throws {
        let shortcutCenter = ShortcutCenter()
        
        // Should initialize without crash
        #expect(shortcutCenter.onToggleAction == nil)
        #expect(shortcutCenter.onPushToTalkStart == nil)
        #expect(shortcutCenter.onPushToTalkEnd == nil)
    }
    
    @Test func testTranscriptionErrorLocalization() async throws {
        let error = TranscriptionError.modelNotLoaded
        
        #expect(error.errorDescription == "Transcription model not loaded")
        #expect(error.localizedDescription.contains("model"))
    }
    
    @Test func testModelDownloadStateEquality() async throws {
        let notDownloaded1 = ModelDownloadState.notDownloaded
        let notDownloaded2 = ModelDownloadState.notDownloaded
        let downloading1 = ModelDownloadState.downloading(progress: 0.5)
        let downloading2 = ModelDownloadState.downloading(progress: 0.5)
        let downloadingDifferent = ModelDownloadState.downloading(progress: 0.3)
        
        #expect(notDownloaded1 == notDownloaded2)
        #expect(downloading1 == downloading2)
        #expect(downloading1 != downloadingDifferent)
    }

}
