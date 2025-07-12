//
//  HistoryWindowMonitor.swift
//  Dictaum
//
//  Created by Siddhartha Reddy on 02/07/25.
//

import Foundation
import AppKit

class HistoryWindowMonitor: ObservableObject {
    static let shared = HistoryWindowMonitor()
    
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
               self?.isHistoryWindow(window) == true {
                self?.startWindowCheckTimer()
            }
        }
    }
    
    private func isHistoryWindow(_ window: NSWindow) -> Bool {
        return window.title.contains("History") ||
               window.title.contains("Transcription History") ||
               (window.title.isEmpty && window.contentViewController != nil && 
                String(describing: type(of: window.contentViewController!)).contains("History"))
    }
    
    private func startWindowCheckTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkHistoryWindowStatus()
        }
    }
    
    private func checkHistoryWindowStatus() {
        // Check if history window is still visible
        let hasVisibleHistoryWindow = NSApp.windows.contains { window in
            window.isVisible && isHistoryWindow(window)
        }
        
        // Also check if settings window is still visible
        let hasVisibleSettingsWindow = NSApp.windows.contains { window in
            window.isVisible && isSettingsWindow(window)
        }
        
        if !hasVisibleHistoryWindow {
            // History window was closed
            timer?.invalidate()
            timer = nil
            
            // Only hide dock icon if no other windows are open
            if !hasVisibleSettingsWindow {
                DockIconHelper.setHidden(true)
            }
        }
    }
    
    private func isSettingsWindow(_ window: NSWindow) -> Bool {
        return window.title.contains("Settings") ||
               window.title.contains("Preferences") ||
               window.title.contains("General") ||
               window.title.contains("Model") ||
               (window.title.isEmpty && window.contentViewController != nil &&
                String(describing: type(of: window.contentViewController!)).contains("Settings"))
    }
    
    deinit {
        if let observer = windowObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        timer?.invalidate()
    }
}