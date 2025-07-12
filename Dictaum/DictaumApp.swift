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
        
        // Initialize window monitors
        _ = SettingsWindowMonitor.shared
        _ = HistoryWindowMonitor.shared
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Check if any windows are open
        let hasOpenWindows = isSettingsWindowOpen() || isHistoryWindowOpen()
        
        if hasOpenWindows {
            // Show confirmation dialog
            let alert = NSAlert()
            alert.messageText = "Quit Dictaum?"
            alert.informativeText = "Dictation will stop working if you quit the app."
            alert.alertStyle = .warning
            
            _ = alert.addButton(withTitle: "Quit")
            _ = alert.addButton(withTitle: "Close Windows")
            
            let response = alert.runModal()
            
            if response == .alertFirstButtonReturn {
                // User chose "Quit"
                return .terminateNow
            } else {
                // User chose "Close Windows"
                closeAllWindows()
                return .terminateCancel
            }
        }
        
        // No windows open, allow normal termination
        return .terminateNow
    }
    
    private func showSettingsWindow(selectedTab: PreferencesTab? = nil) {
        AppDelegate.showSettingsWindow(selectedTab: selectedTab)
    }
    
    private func isSettingsWindowOpen() -> Bool {
        return NSApp.windows.contains { window in
            window.isVisible && (isSettingsWindow(window) || isHistoryWindow(window))
        }
    }
    
    private func isSettingsWindow(_ window: NSWindow) -> Bool {
        return window.title.contains("Settings") ||
               window.title.contains("Preferences") ||
               window.title.contains("General") ||
               window.title.contains("Model") ||
               (window.title.isEmpty && window.contentViewController != nil)
    }
    
    private func isHistoryWindowOpen() -> Bool {
        return NSApp.windows.contains { window in
            window.isVisible && isHistoryWindow(window)
        }
    }
    
    private func isHistoryWindow(_ window: NSWindow) -> Bool {
        return window.title.contains("History") ||
               window.title.contains("Transcription History")
    }
    
    private func closeSettingsWindow() {
        for window in NSApp.windows {
            if window.isVisible && isSettingsWindow(window) {
                window.close()
            }
        }
    }
    
    private func closeAllWindows() {
        for window in NSApp.windows {
            if window.isVisible && (isSettingsWindow(window) || isHistoryWindow(window)) {
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
        
        // History window - single instance only
        Window("Transcription History", id: "history-window") {
            HistoryWindowView()
                .frame(minWidth: 800, idealWidth: 1000, minHeight: 600, idealHeight: 700)
                .environmentObject(dictationController)
        }
        .windowResizability(.contentSize)
    }
}

struct MenuBarContentView: View {
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        Button("Settings...") {
            AppDelegate.showSettingsWindow()
        }
        .keyboardShortcut(",", modifiers: .command)
        
        Button("History...") {
            DockIconHelper.setHidden(false)
            openWindow(id: "history-window")
        }
        .keyboardShortcut("h", modifiers: .command)
    }
}
