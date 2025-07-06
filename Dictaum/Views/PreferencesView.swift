//
//  PreferencesView.swift
//  Dictaum
//
//  Created by Siddhartha Reddy on 02/07/25.
//

import SwiftUI
import KeyboardShortcuts

enum PreferencesTab: Int, CaseIterable {
    case general = 0
    case model = 1
    case permissions = 2
}

struct PreferencesView: View {
    static let windowTitle = "Dictaum Settings"
    
    @StateObject private var store = SettingsStore.shared
    @StateObject private var launchHelper = LaunchAtLoginHelper()
    @StateObject private var permissionManager = PermissionManager.shared
    
    var body: some View {
        TabView(selection: $store.selectedTab) {
            GeneralTab(store: store, launchHelper: launchHelper)
                .navigationTitle(PreferencesView.windowTitle)
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(PreferencesTab.general)
            
            ModelTab(store: store)
                .navigationTitle(PreferencesView.windowTitle)
                .tabItem {
                    Label("Model", systemImage: "brain")
                }
                .tag(PreferencesTab.model)
            
            PermissionsTab(permissionManager: permissionManager)
                .navigationTitle(PreferencesView.windowTitle)
                .tabItem {
                    Label("Permissions", systemImage: "lock.shield")
                }
                .tag(PreferencesTab.permissions)
        }
        .padding()
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            permissionManager.refreshPermissionStatus()
        }
    }
}

struct GeneralTab: View {
    @ObservedObject var store: SettingsStore
    @ObservedObject var launchHelper: LaunchAtLoginHelper
    
    var body: some View {
        Form {
            Section {
                Toggle("Launch Dictaum at login", isOn: $launchHelper.isEnabled)
                    .onChange(of: launchHelper.isEnabled) { _, newValue in
                        LaunchAtLoginHelper.setEnabled(newValue)
                    }
            } header: {
                Text("Appearance")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondaryColor)
            }
            
            Section {
                VStack(alignment: .leading) {
                    Spacer(minLength: 8)
                    
                    KeyboardShortcuts.Recorder("Start/Stop (Toggle)", name: .toggleDictation)

                    Text("Press once to start recording, press again to stop.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }

                VStack (alignment: .leading){
                    Spacer(minLength: 8)
                    
                    KeyboardShortcuts.Recorder("Push-to-Talk (Hold)", name: .pushToTalk)
                    
                    Text("Hold down the shortcut to record, release to stop.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            } header: {
                Text("Recording Shortcuts")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondaryColor)
            }
        }
        .formStyle(.grouped)
    }
}

struct ModelTab: View {
    @ObservedObject var store: SettingsStore
    @StateObject private var modelManager = ModelManager.shared
    @EnvironmentObject var dictationController: DictationController
    @State private var selectedModelForDownload: ModelInfo?
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 20) {
                // No Model Selected Message
                if currentlySelectedModel == nil {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 16))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("No Speech Recognition Model Selected")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                Text("Please download and select a model to enable voice transcription.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(16)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
                
                // Currently Selected Model Section
                if let currentModel = currentlySelectedModel {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Currently Selected Model")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondaryColor)
                        
                        ModelCard(
                            model: currentModel,
                            isSelected: true,
                            downloadState: modelManager.downloadStates[currentModel.id] ?? .notDownloaded,
                            onDownload: { startDownload(currentModel) },
                            onDelete: { modelManager.deleteModel(currentModel.id) },
                            onSelect: { }
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }
                
                if currentlySelectedModel != nil {
                    Divider()
                        .padding(.horizontal, 20)
                }
                
                // Available Models Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Available Models")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondaryColor)
                        .padding(.horizontal, 20)
                    
                    // Model Information
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Larger models are more accurate but slower")
                        Text("• English models are optimized for English only")
                    }
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.8))
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                    
                    LazyVStack(spacing: 10) {
                        ForEach(availableModels) { model in
                            ModelCard(
                                model: model,
                                isSelected: isModelActuallySelected(model),
                                downloadState: modelManager.downloadStates[model.id] ?? .notDownloaded,
                                onDownload: { startDownload(model) },
                                onDelete: { modelManager.deleteModel(model.id) },
                                onSelect: { modelManager.selectModel(model.id) }
                            )
                            .padding(.horizontal, 20)
                        }
                    }
                
                }
            }
        }
        .scrollIndicators(.visible, axes: .vertical)
        .sheet(isPresented: $store.showDownloadModal) {
            if let model = selectedModelForDownload {
                ModelDownloadModal(
                    modelManager: modelManager,
                    settingsStore: store,
                    modelInfo: model
                )
            }
        }
    }
    
    private var currentlySelectedModel: ModelInfo? {
        // Only show a model as selected if it's actually selected AND the transcriber is ready
        guard let controller = DictationController.shared,
              controller.isTranscriberReady,
              !store.selectedModel.isEmpty else {
            return nil
        }
        return modelManager.availableModels.first { $0.id == store.selectedModel }
    }
    
    private var availableModels: [ModelInfo] {
        modelManager.availableModels.filter { $0.id != store.selectedModel }
    }
    
    private func startDownload(_ model: ModelInfo) {
        selectedModelForDownload = model
        store.showDownloadModal = true
        modelManager.downloadModel(model.id)
    }
    
    private func isModelActuallySelected(_ model: ModelInfo) -> Bool {
        guard let controller = DictationController.shared,
              controller.isTranscriberReady else {
            return false
        }
        return model.id == store.selectedModel
    }
}

struct ModelCard: View {
    let model: ModelInfo
    let isSelected: Bool
    let downloadState: ModelDownloadState
    let onDownload: () -> Void
    let onDelete: () -> Void
    let onSelect: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                // Model info
                VStack(alignment: .leading, spacing: 8) {
                    // Model name and select button
                    HStack {
                        HStack(spacing: 8) {
                            Text(model.displayName)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                            
                            if model.isEnglishOnly {
                                Text("EN")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.gray.opacity(0.6))
                                    .cornerRadius(4)
                            }
                        }
                        
                        Spacer()
                        
                        // Select button or checkmark aligned with name
                        if case .downloaded = downloadState {
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                                    .font(.system(size: 20))
                            } else {
                                Button(action: onSelect) {
                                    Text("Select")
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.regular)
                            }
                        }
                    }
                    
                    // Speed badge below name
                    SpeedBadge(speed: model.speed)
                    
                    // Size and download info line
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "internaldrive")
                                .font(.system(size: 11))
                            Text("Size: \(model.diskSize)")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "memorychip")
                                .font(.system(size: 11))
                            Text("Memory: \(model.memoryUsage)")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Download status/actions aligned with disk/RAM info
                        if !isSelected {
                            HStack(spacing: 8) {
                                switch downloadState {
                                case .notDownloaded:
                                    Button(action: onDownload) {
                                        Label("Download", systemImage: "arrow.down.circle")
                                            .padding(.vertical, 4)
                                            .padding(.horizontal, 8)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.regular)
                                    
                                case .downloading:
                                    ProgressView()
                                        .scaleEffect(0.7)
                                        .frame(height: 20)
                                    Text("Downloading...")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                    Button(action: { ModelManager.shared.cancelCurrentDownload() }) {
                                        Text("Cancel")
                                            .padding(.vertical, 4)
                                            .padding(.horizontal, 8)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.regular)
                                    
                                case .warming:
                                    Image(systemName: "flame.fill")
                                        .foregroundColor(.orange)
                                        .font(.system(size: 12))
                                    Text("Warming up...")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                    
                                case .downloaded:
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 11))
                                        Text("Downloaded")
                                            .font(.system(size: 12))
                                    }
                                    .foregroundColor(.secondary)
                                    Button(action: onDelete) {
                                        Image(systemName: "trash")
                                            .padding(.vertical, 4)
                                            .padding(.horizontal, 8)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.regular)
                                    
                                case .error:
                                    Button(action: onDownload) {
                                        Label("Retry", systemImage: "arrow.clockwise")
                                            .padding(.vertical, 4)
                                            .padding(.horizontal, 8)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.regular)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .overlay(
            // Download progress overlay
            Group {
                if case .downloading(let progress) = downloadState {
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.accentColor.opacity(0.1))
                            .frame(width: geometry.size.width * CGFloat(progress))
                            .animation(.linear(duration: 0.2), value: progress)
                    }
                    .allowsHitTesting(false)
                    .cornerRadius(10)
                }
            }
        )
    }
}

struct SpeedBadge: View {
    let speed: ModelInfo.ModelSpeed
    
    var body: some View {
        Text(speed.rawValue)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(speed.color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(speed.color.opacity(0.15))
            .cornerRadius(4)
    }
}

struct PermissionsTab: View {
    @ObservedObject var permissionManager: PermissionManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 12) {
                Text("Required Permissions")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondaryColor)
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

#Preview {
    PreferencesView()
}
