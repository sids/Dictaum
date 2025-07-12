//
//  DictaumApp.swift
//  Dictaum
//
//  Created by Siddhartha Reddy on 02/07/25.
//

import SwiftUI
import KeyboardShortcuts

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Apply dock icon setting after SwiftUI has finished setup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            DockIconHelper.applyInitialSetting()
            
            // Show Settings window if launch at login is disabled
            if !LaunchAtLoginHelper.isLaunchAtLoginEnabled() {
                self.showSettingsWindow()
            }
        }
        
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Check if settings window is open
        if isSettingsWindowOpen() {
            // Show confirmation dialog
            let alert = NSAlert()
            alert.messageText = "Quit Dictaum?"
            alert.informativeText = "Dictation will stop working if you quit the app."
            alert.alertStyle = .warning
            
            _ = alert.addButton(withTitle: "Quit")
            _ = alert.addButton(withTitle: "Close Settings Window")
            
            let response = alert.runModal()
            
            if response == .alertFirstButtonReturn {
                // User chose "Quit"
                return .terminateNow
            } else {
                // User chose "Close Settings Window"
                closeSettingsWindow()
                return .terminateCancel
            }
        }
        
        // No settings window open, allow normal termination
        return .terminateNow
    }
    
    private func showSettingsWindow(selectedTab: PreferencesTab? = nil) {
        AppDelegate.showSettingsWindow(selectedTab: selectedTab)
    }
    
    private func isSettingsWindowOpen() -> Bool {
        return NSApp.windows.contains { window in
            window.isVisible && isSettingsWindow(window)
        }
    }
    
    private func isSettingsWindow(_ window: NSWindow) -> Bool {
        return window.title.contains("Settings") ||
               window.title.contains("Preferences") ||
               window.title.contains("General") ||
               window.title.contains("Model") ||
               (window.title.isEmpty && window.contentViewController != nil)
    }
    
    private func closeSettingsWindow() {
        for window in NSApp.windows {
            if window.isVisible && isSettingsWindow(window) {
                window.close()
            }
        }
    }
    
    static func showSettingsWindow(selectedTab: PreferencesTab? = nil) {
        // Set the selected tab if specified
        if let tab = selectedTab {
            SettingsStore.shared.selectedTab = tab
        }
        
        // Show dock icon first
        DockIconHelper.setHidden(false)
        
        // Open settings via menu
        if let mainMenu = NSApp.mainMenu,
           let appMenu = mainMenu.items.first?.submenu,
           let preferencesItem = appMenu.items.first(where: { $0.title.contains("Preferences") || $0.title.contains("Settings") }),
           let action = preferencesItem.action {
            NSApp.sendAction(action, to: preferencesItem.target, from: nil)
        }
        
        // Ensure window focus
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            
            // Find and focus the settings window
            for window in NSApp.windows {
                if window.isVisible && (window.title == SettingsView.windowTitle) {
                    window.orderFrontRegardless()
                }
            }
        }
    }
}

@main
struct DictaumApp: App {
    @StateObject private var dictationController = DictationController()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openSettings) private var openSettings
    
    var body: some Scene {
        MenuBarExtra("Dictaum", systemImage: "waveform.badge.microphone") {
            MenuBarContentView()
            
            Divider()
            
            Button("Quit Dictaum") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .menuBarExtraStyle(.menu)
        
        // Application menu commands
        Settings {
            SettingsView()
                .frame(width: 600, height: 500)
                .environmentObject(dictationController)
        }
        .windowResizability(.contentSize)
    }
}

struct MenuBarContentView: View {
    var body: some View {
        Button("Settings...") {
            AppDelegate.showSettingsWindow()
        }
    }
}
