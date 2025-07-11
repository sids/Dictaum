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
    
    private init() {
        setupDefaultShortcuts()
    }
    
    private func setupDefaultShortcuts() {
        if !UserDefaults.standard.bool(forKey: "hasSetupDefaultShortcuts") {
            KeyboardShortcuts.setShortcut(.init(KeyboardShortcuts.Key(rawValue: 50), modifiers: [.control]), for: .toggleDictation)
            KeyboardShortcuts.setShortcut(.init(.escape, modifiers: [.control]), for: .pushToTalk)
            UserDefaults.standard.set(true, forKey: "hasSetupDefaultShortcuts")
        }
    }
    
    func openSettingsWithModelTab() {
        AppDelegate.showSettingsWindow(selectedTab: .model)
    }
}

extension KeyboardShortcuts.Name {
    static let toggleDictation = Self("toggleDictation")
    static let pushToTalk = Self("pushToTalk")
}

