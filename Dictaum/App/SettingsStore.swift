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
    @Published var showDownloadModal: Bool = false
    @Published var downloadingModelId: String?
    @Published var selectedTab: PreferencesTab = .general
    
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

