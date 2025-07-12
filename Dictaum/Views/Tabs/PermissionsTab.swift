//
//  PermissionsTab.swift
//  Dictaum
//
//  Created by Siddhartha Reddy on 02/07/25.
//

import SwiftUI

struct PermissionsTab: View {
    @ObservedObject var permissionManager: PermissionManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                Text("Required Permissions")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondaryAccent)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                
                Text("Dictaum needs these permissions to work properly. All processing happens locally on your Mac.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)
            }
            
            // Permission Cards
            VStack(spacing: 16) {
                PermissionCard(
                    icon: "mic.fill",
                    title: "Microphone Access",
                    description: "Required to capture your voice for transcription.",
                    status: permissionManager.microphonePermissionStatus,
                    buttonTitle: permissionManager.microphonePermissionStatus == .notDetermined ? "Request Access" : "Open Settings",
                    action: {
                        Task {
                            await permissionManager.requestMicrophonePermission()
                        }
                    }
                )
                
                PermissionCard(
                    icon: "accessibility",
                    title: "Accessibility Access",
                    description: "Required to automatically paste transcribed text into the active application.",
                    status: permissionManager.accessibilityPermissionStatus,
                    buttonTitle: "Open Settings",
                    action: {
                        permissionManager.openAccessibilitySettings()
                    }
                )
            }
            .padding(.horizontal, 24)
            
            // Refresh Button
            HStack {
                Spacer()
                Button("Refresh Status") {
                    permissionManager.refreshPermissionStatus()
                }
                .buttonStyle(.borderless)
                .foregroundColor(.secondary)
                .font(.system(size: 12))
                Spacer()
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .onAppear {
            permissionManager.refreshPermissionStatus()
        }
    }
}

struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    let status: PermissionManager.PermissionStatus
    let buttonTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                    .font(.system(size: 20))
                    .frame(width: 24, height: 24)
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    // Title and Status
                    HStack {
                        Text(title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Status Badge
                        PermissionStatusBadge(status: status)
                    }
                    
                    // Description
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Action Button
                Button(action: action) {
                    Text(buttonTitle)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }
            .padding(20)
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
}

struct PermissionStatusBadge: View {
    let status: PermissionManager.PermissionStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: statusIcon)
                .font(.system(size: 10))
            Text(statusText)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(statusColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(statusColor.opacity(0.15))
        .cornerRadius(6)
    }
    
    private var statusIcon: String {
        switch status {
        case .authorized:
            return "checkmark.circle.fill"
        case .denied:
            return "xmark.circle.fill"
        case .notDetermined:
            return "questionmark.circle.fill"
        case .restricted:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var statusText: String {
        switch status {
        case .authorized:
            return "Authorized"
        case .denied:
            return "Denied"
        case .notDetermined:
            return "Not Set"
        case .restricted:
            return "Restricted"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .authorized:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        case .restricted:
            return .red
        }
    }
}