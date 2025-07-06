//
//  LaunchAtLoginHelper.swift
//  Dictaum
//
//  Created by Siddhartha Reddy on 02/07/25.
//

import Foundation
import ServiceManagement
import SwiftUI

class LaunchAtLoginHelper: ObservableObject {
    @Published var isEnabled: Bool = false
    
    init() {
        updateStatus()
    }
    
    private func updateStatus() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }
    
    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            
            // Sync with UserDefaults
            UserDefaults.standard.set(enabled, forKey: "launchAtLogin")
        } catch {
            print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
        }
    }
    
    // Check if launch at login is enabled (static method for AppDelegate)
    static func isLaunchAtLoginEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "launchAtLogin")
    }
}