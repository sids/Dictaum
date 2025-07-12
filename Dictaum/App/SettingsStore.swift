//
//  SettingsStore.swift
//  Dictaum
//
//  Created by Siddhartha Reddy on 02/07/25.
//

import Foundation
import SwiftUI
import KeyboardShortcuts
import AppKit

class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false
    @AppStorage("selectedModel") var selectedModel: String = ""
    @AppStorage("selectedLanguage") var selectedLanguage: String = "en"
    @Published var showDownloadModal: Bool = false
    @Published var downloadingModelId: String?
    @Published var selectedTab: PreferencesTab = .general
    
    // Transcription parameters
    @AppStorage("temperature") var temperature: Double = 0.2
    @AppStorage("beamSize") var beamSize: Int = 1
    @AppStorage("bestOf") var bestOf: Int = 1
    @AppStorage("topK") var topK: Int = 5
    @AppStorage("enableTimestamps") var enableTimestamps: Bool = false
    @AppStorage("selectedPreset") var selectedPreset: String = "balanced"
    
    // Advanced quality control parameters
    @AppStorage("logProbThreshold") var logProbThreshold: Double = -1.0
    @AppStorage("compressionRatioThreshold") var compressionRatioThreshold: Double = 2.4
    @AppStorage("suppressBlank") var suppressBlank: Bool = true
    
    // History settings
    @AppStorage("historyEnabled") var historyEnabled: Bool = true
    @AppStorage("historyRetentionDays") var historyRetentionDays: Int = 30
    @AppStorage("historyMaxEntries") var historyMaxEntries: Int = 1000
    
    private init() {
        setupDefaultShortcuts()
    }
    
    private func setupDefaultShortcuts() {
        if !UserDefaults.standard.bool(forKey: "hasSetupDefaultShortcuts") {
            KeyboardShortcuts.setShortcut(.init(.escape, modifiers: [.control]), for: .dictation)
            UserDefaults.standard.set(true, forKey: "hasSetupDefaultShortcuts")
        }
    }
    
    func resetDictationShortcutToDefault() {
        KeyboardShortcuts.setShortcut(.init(.escape, modifiers: [.control]), for: .dictation)
    }
    
    var defaultDictationShortcut: KeyboardShortcuts.Shortcut {
        return .init(.escape, modifiers: [.control])
    }
    
    func openSettingsWithModelTab() {
        AppDelegate.showSettingsWindow(selectedTab: .model)
    }
}

extension KeyboardShortcuts.Name {
    static let dictation = Self("dictation")
}

