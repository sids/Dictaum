//
//  PermissionManager.swift
//  Dictaum
//
//  Created by Siddhartha Reddy on 04/07/25.
//

import Foundation
import AVFoundation
import ApplicationServices
import AppKit

class PermissionManager: ObservableObject {
    @Published var microphonePermissionStatus: PermissionStatus = .notDetermined
    @Published var accessibilityPermissionStatus: PermissionStatus = .notDetermined
    
    enum PermissionStatus {
        case notDetermined
        case denied
        case authorized
        case restricted
    }
    
    static let shared = PermissionManager()
    
    private init() {
        refreshPermissionStatus()
    }
    
    func refreshPermissionStatus() {
        checkMicrophonePermission()
        checkAccessibilityPermission()
    }
    
    private func checkMicrophonePermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        
        switch status {
        case .notDetermined:
            microphonePermissionStatus = .notDetermined
        case .denied:
            microphonePermissionStatus = .denied
        case .authorized:
            microphonePermissionStatus = .authorized
        case .restricted:
            microphonePermissionStatus = .restricted
        @unknown default:
            microphonePermissionStatus = .notDetermined
        }
    }
    
    private func checkAccessibilityPermission() {
        let trusted = AXIsProcessTrusted()
        accessibilityPermissionStatus = trusted ? .authorized : .denied
    }
    
    func requestMicrophonePermission() async {
        guard microphonePermissionStatus == .notDetermined else {
            openMicrophoneSettings()
            return
        }
        
        _ = await AVCaptureDevice.requestAccess(for: .audio)
        await MainActor.run {
            checkMicrophonePermission()
        }
    }
    
    func openMicrophoneSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!
        NSWorkspace.shared.open(url)
    }
    
    func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
    
}