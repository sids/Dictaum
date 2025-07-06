//
//  SettingsWindowMonitor.swift
//  Dictaum
//
//  Created by Siddhartha Reddy on 02/07/25.
//

import Foundation
import AppKit

class SettingsWindowMonitor: ObservableObject {
    static let shared = SettingsWindowMonitor()
    
    private var windowObserver: Any?
    private var timer: Timer?
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        // Monitor for new windows
        windowObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let window = notification.object as? NSWindow,
               self?.isSettingsWindow(window) == true {
                self?.startWindowCheckTimer()
            }
        }
    }
    
    private func isSettingsWindow(_ window: NSWindow) -> Bool {
        return window.title.contains("Settings") ||
               window.title.contains("Preferences") ||
               window.title.contains("General") ||
               window.title.contains("Model") ||
               (window.title.isEmpty && window.contentViewController != nil)
    }
    
    private func startWindowCheckTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkSettingsWindowStatus()
        }
    }
    
    private func checkSettingsWindowStatus() {
        // Check if settings window is still visible
        let hasVisibleSettingsWindow = NSApp.windows.contains { window in
            window.isVisible && isSettingsWindow(window)
        }
        
        if !hasVisibleSettingsWindow {
            // Settings window was closed
            timer?.invalidate()
            timer = nil
            
            // Always hide dock icon when settings window closes
            DockIconHelper.setHidden(true)
        }
    }
    
    deinit {
        if let observer = windowObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        timer?.invalidate()
    }
}