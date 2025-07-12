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
    case advanced = 2
    case permissions = 3
}

enum LanguageOption: String, CaseIterable {
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case italian = "it"
    case portuguese = "pt"
    case russian = "ru"
    case korean = "ko"
    case chinese = "zh"
    case japanese = "ja"
    case arabic = "ar"
    case turkish = "tr"
    case polish = "pl"
    case dutch = "nl"
    case catalan = "ca"
    case ukrainian = "uk"
    case swedish = "sv"
    case hindi = "hi"
    case czech = "cs"
    case hebrew = "he"
    case persian = "fa"
    case finnish = "fi"
    case malay = "ms"
    case slovak = "sk"
    case danish = "da"
    case tamil = "ta"
    case norwegian = "no"
    case thai = "th"
    case urdu = "ur"
    case croatian = "hr"
    case bulgarian = "bg"
    case lithuanian = "lt"
    case latin = "la"
    case maori = "mi"
    case malayalam = "ml"
    case welsh = "cy"
    case telugu = "te"
    case latvian = "lv"
    case bengali = "bn"
    case serbian = "sr"
    case azerbaijani = "az"
    case slovenian = "sl"
    case kannada = "kn"
    case estonian = "et"
    case macedonian = "mk"
    case breton = "br"
    case basque = "eu"
    case icelandic = "is"
    case armenian = "hy"
    case nepali = "ne"
    case mongolian = "mn"
    case bosnian = "bs"
    case kazakh = "kk"
    case albanian = "sq"
    case swahili = "sw"
    case galician = "gl"
    case maltese = "mt"
    case somali = "so"
    case tagalog = "tl"
    case uzbek = "uz"
    case amharic = "am"
    case georgian = "ka"
    case byelorussian = "be"
    case tajik = "tg"
    case sindhi = "sd"
    case gujarati = "gu"
    case yiddish = "yi"
    case lao = "lo"
    case burmese = "my"
    case khmer = "km"
    case xhosa = "xh"
    case zulu = "zu"
    case afrikaans = "af"
    case sanskrit = "sa"
    case javanese = "jv"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .spanish: return "Spanish"
        case .french: return "French"
        case .german: return "German"
        case .italian: return "Italian"
        case .portuguese: return "Portuguese"
        case .russian: return "Russian"
        case .korean: return "Korean"
        case .chinese: return "Chinese"
        case .japanese: return "Japanese"
        case .arabic: return "Arabic"
        case .turkish: return "Turkish"
        case .polish: return "Polish"
        case .dutch: return "Dutch"
        case .catalan: return "Catalan"
        case .ukrainian: return "Ukrainian"
        case .swedish: return "Swedish"
        case .hindi: return "Hindi"
        case .czech: return "Czech"
        case .hebrew: return "Hebrew"
        case .persian: return "Persian"
        case .finnish: return "Finnish"
        case .malay: return "Malay"
        case .slovak: return "Slovak"
        case .danish: return "Danish"
        case .tamil: return "Tamil"
        case .norwegian: return "Norwegian"
        case .thai: return "Thai"
        case .urdu: return "Urdu"
        case .croatian: return "Croatian"
        case .bulgarian: return "Bulgarian"
        case .lithuanian: return "Lithuanian"
        case .latin: return "Latin"
        case .maori: return "Maori"
        case .malayalam: return "Malayalam"
        case .welsh: return "Welsh"
        case .telugu: return "Telugu"
        case .latvian: return "Latvian"
        case .bengali: return "Bengali"
        case .serbian: return "Serbian"
        case .azerbaijani: return "Azerbaijani"
        case .slovenian: return "Slovenian"
        case .kannada: return "Kannada"
        case .estonian: return "Estonian"
        case .macedonian: return "Macedonian"
        case .breton: return "Breton"
        case .basque: return "Basque"
        case .icelandic: return "Icelandic"
        case .armenian: return "Armenian"
        case .nepali: return "Nepali"
        case .mongolian: return "Mongolian"
        case .bosnian: return "Bosnian"
        case .kazakh: return "Kazakh"
        case .albanian: return "Albanian"
        case .swahili: return "Swahili"
        case .galician: return "Galician"
        case .maltese: return "Maltese"
        case .somali: return "Somali"
        case .tagalog: return "Tagalog"
        case .uzbek: return "Uzbek"
        case .amharic: return "Amharic"
        case .georgian: return "Georgian"
        case .byelorussian: return "Byelorussian"
        case .tajik: return "Tajik"
        case .sindhi: return "Sindhi"
        case .gujarati: return "Gujarati"
        case .yiddish: return "Yiddish"
        case .lao: return "Lao"
        case .burmese: return "Burmese"
        case .khmer: return "Khmer"
        case .xhosa: return "Xhosa"
        case .zulu: return "Zulu"
        case .afrikaans: return "Afrikaans"
        case .sanskrit: return "Sanskrit"
        case .javanese: return "Javanese"
        }
    }
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
            
            AdvancedTab(store: store)
                .navigationTitle(PreferencesView.windowTitle)
                .tabItem {
                    Label("Advanced", systemImage: "slider.horizontal.3")
                }
                .tag(PreferencesTab.advanced)
            
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
                    .foregroundColor(.secondaryAccent)
            }
            
            Section {
                VStack(alignment: .leading) {
                    Spacer(minLength: 8)
                    
                    KeyboardShortcuts.Recorder("Dictation", name: .dictation)

                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Quick tap: Toggle recording on/off.")
                                .font(.caption)
                                .foregroundColor(.primary.opacity(0.8))
                            Text("Hold down: Push-to-talk mode.")
                                .font(.caption)
                                .foregroundColor(.primary.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        Button("Default: control + esc") {
                            SettingsStore.shared.resetDictationShortcutToDefault()
                        }
                        .buttonStyle(.plain)
                        .font(.caption2)
                        .foregroundColor(.accentColor)
                    }
                    .padding(.top, 4)
                }
            } header: {
                Text("Keyboard Shortcut")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondaryAccent)
            }
            
            Section {
                Picker("Language", selection: $store.selectedLanguage) {
                    ForEach(LanguageOption.allCases, id: \.self) { language in
                        Text(language.displayName).tag(language.rawValue)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: store.selectedLanguage) { _, newValue in
                    // Update transcriber language if available
                    if let controller = DictationController.shared {
                        Task {
                            await controller.updateTranscriberLanguage(newValue)
                        }
                    }
                }
                
                Text("Select the primary language for transcription. This setting works best with multilingual models.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            } header: {
                Text("Transcription")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondaryAccent)
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
                            .foregroundColor(.secondaryAccent)
                        
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
                        .foregroundColor(.secondaryAccent)
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

struct AdvancedTab: View {
    @ObservedObject var store: SettingsStore
    
    private var presetHeaderText: String {
        switch store.selectedPreset {
        case "conservative":
            return "Preset Parameters - Conservative"
        case "balanced":
            return "Preset Parameters - Balanced"
        case "creative":
            return "Preset Parameters - Creative"
        case "custom":
            return "Custom Parameters"
        default:
            return "Preset Parameters"
        }
    }
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    // Conservative preset
                    PresetOption(
                        title: "Conservative",
                        description: "Fast processing with basic accuracy",
                        systemImage: "hare.fill",
                        parameters: "Temp: 0.0 • Beam: 1 • Best: 1",
                        isSelected: store.selectedPreset == "conservative",
                        isRecommended: false
                    ) {
                        store.selectedPreset = "conservative"
                        applyPreset("conservative")
                    }
                    
                    // Balanced preset
                    PresetOption(
                        title: "Balanced",
                        description: "Optimal balance of speed and accuracy",
                        systemImage: "checkmark.circle.fill",
                        parameters: "Temp: 0.2 • Beam: 3 • Best: 1",
                        isSelected: store.selectedPreset == "balanced",
                        isRecommended: true
                    ) {
                        store.selectedPreset = "balanced"
                        applyPreset("balanced")
                    }
                    
                    // Creative preset
                    PresetOption(
                        title: "Creative",
                        description: "Highest accuracy with slower processing",
                        systemImage: "tortoise.fill",
                        parameters: "Temp: 0.4 • Beam: 5 • Best: 3",
                        isSelected: store.selectedPreset == "creative",
                        isRecommended: false
                    ) {
                        store.selectedPreset = "creative"
                        applyPreset("creative")
                    }
                    
                    Divider()
                        .padding(.vertical, 4)
                    
                    // Custom preset
                    PresetOption(
                        title: "Custom",
                        description: "Manual control over all parameters",
                        systemImage: "slider.horizontal.3",
                        parameters: nil,
                        isSelected: store.selectedPreset == "custom",
                        isRecommended: false
                    ) {
                        store.selectedPreset = "custom"
                    }
                }
            } header: {
                Text("Transcription Presets")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondaryAccent)
            }
            
            // Parameters Section - Always visible
            Section {
                // Temperature
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Temperature")
                            .font(.system(size: 13))
                        Spacer()
                        Text(String(format: "%.1f", store.temperature))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    if store.selectedPreset == "custom" {
                        Slider(value: $store.temperature, in: 0.0...1.0, step: 0.1)
                            .onChange(of: store.temperature) { _, _ in
                                updateTranscriberParameters()
                            }
                    } else {
                        ProgressView(value: store.temperature, total: 1.0)
                            .tint(.gray)
                            .opacity(0.5)
                    }
                    
                    Text("Controls randomness. Lower = more consistent, Higher = more creative")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 2)
                
                // Beam Size
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Beam Size")
                            .font(.system(size: 13))
                        Spacer()
                        Text("\(store.beamSize)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    if store.selectedPreset == "custom" {
                        Slider(
                            value: Binding(
                                get: { Double(store.beamSize) },
                                set: { store.beamSize = Int($0) }
                            ),
                            in: 1.0...5.0,
                            step: 1.0
                        )
                        .onChange(of: store.beamSize) { _, _ in
                            updateTranscriberParameters()
                        }
                    } else {
                        ProgressView(value: Double(store.beamSize), total: 5.0)
                            .tint(.gray)
                            .opacity(0.5)
                    }
                    
                    Text("Search width. Higher = more accurate but slower")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 2)
                
                // Best Of
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Best Of")
                            .font(.system(size: 13))
                            .foregroundColor(store.selectedPreset == "custom" && store.temperature == 0.0 ? .secondary : .primary)
                        Spacer()
                        Text("\(store.bestOf)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    if store.selectedPreset == "custom" {
                        Slider(
                            value: Binding(
                                get: { Double(store.bestOf) },
                                set: { store.bestOf = Int($0) }
                            ),
                            in: 1.0...5.0,
                            step: 1.0
                        )
                        .disabled(store.temperature == 0.0)
                        .onChange(of: store.bestOf) { _, _ in
                            updateTranscriberParameters()
                        }
                    } else {
                        ProgressView(value: Double(store.bestOf), total: 5.0)
                            .tint(.gray)
                            .opacity(0.5)
                    }
                    
                    Text("Number of candidates to consider. Only used when temperature > 0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 2)
                
                // Top K
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Top K")
                            .font(.system(size: 13))
                        Spacer()
                        Text("\(store.topK)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    if store.selectedPreset == "custom" {
                        Slider(
                            value: Binding(
                                get: { Double(store.topK) },
                                set: { store.topK = Int($0) }
                            ),
                            in: 1.0...50.0,
                            step: 1.0
                        )
                        .onChange(of: store.topK) { _, _ in
                            updateTranscriberParameters()
                        }
                    } else {
                        ProgressView(value: Double(store.topK), total: 50.0)
                            .tint(.gray)
                            .opacity(0.5)
                    }
                    
                    Text("Limits vocabulary choices. Lower = more focused")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 2)
                
            } header: {
                HStack {
                    Text(presetHeaderText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondaryAccent)
                    
                    Spacer()
                    
                    Button(action: {
                        if let url = URL(string: "https://github.com/jhj0517/Whisper-WebUI/wiki/Whisper-Advanced-Parameters") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 14))
                            .foregroundColor(.secondaryAccent)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Learn more about transcription parameters")
                }
            }
            
            // Quality Control Section - Only visible in custom mode
            if store.selectedPreset == "custom" {
                Section {
                    // Log Probability Threshold
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Log Probability Threshold")
                                .font(.system(size: 13))
                            Spacer()
                            Text(String(format: "%.1f", store.logProbThreshold))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $store.logProbThreshold, in: -5.0...0.0, step: 0.1)
                            .onChange(of: store.logProbThreshold) { _, _ in
                                updateTranscriberParameters()
                            }
                        
                        Text("Reject transcriptions below this confidence. -1.0 = moderate, 0.0 = strict")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                    
                    // Compression Ratio Threshold
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Compression Ratio Threshold")
                                .font(.system(size: 13))
                            Spacer()
                            Text(String(format: "%.1f", store.compressionRatioThreshold))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $store.compressionRatioThreshold, in: 1.5...3.0, step: 0.1)
                            .onChange(of: store.compressionRatioThreshold) { _, _ in
                                updateTranscriberParameters()
                            }
                        
                        Text("Detect repetitive output. Lower = more sensitive to repetition")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                    
                    // Suppress Blank
                    VStack(alignment: .leading, spacing: 4) {
                        Toggle("Suppress Blank Tokens", isOn: $store.suppressBlank)
                            .onChange(of: store.suppressBlank) { _, _ in
                                updateTranscriberParameters()
                            }
                        
                        Text("Remove empty tokens from the beginning of transcription")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                } header: {
                    Text("Quality Control")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondaryAccent)
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            // Apply the selected preset on appear
            if store.selectedPreset != "custom" {
                applyPreset(store.selectedPreset)
            }
        }
    }
    
    private func applyPreset(_ preset: String) {
        switch preset {
        case "conservative":
            store.temperature = 0.0
            store.beamSize = 1
            store.bestOf = 1
        case "balanced":
            store.temperature = 0.2
            store.beamSize = 3
            store.bestOf = 1
        case "creative":
            store.temperature = 0.4
            store.beamSize = 5
            store.bestOf = 3
        default:
            break // Custom - don't change values
        }
        
        // Apply to transcriber if available
        if let controller = DictationController.shared {
            Task {
                await controller.updateTranscriberParameters()
            }
        }
    }
    
    private func updateTranscriberParameters() {
        if let controller = DictationController.shared {
            Task {
                await controller.updateTranscriberParameters()
            }
        }
    }
}

// Custom preset option view
struct PresetOption: View {
    let title: String
    let description: String
    let systemImage: String
    let parameters: String?
    let isSelected: Bool
    let isRecommended: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                // Radio button
                Image(systemName: isSelected ? "circle.inset.filled" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .font(.system(size: 16))
                    .frame(width: 20, height: 20)
                    .padding(.top, 2)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        // Icon
                        Image(systemName: systemImage)
                            .foregroundColor(isSelected ? .accentColor : .secondary)
                            .font(.system(size: 14))
                        
                        // Title
                        Text(title)
                            .font(.system(size: 14, weight: isSelected ? .medium : .regular))
                            .foregroundColor(isSelected ? .primary : .primary.opacity(0.9))
                        
                        // Recommended badge
                        if isRecommended {
                            Text("RECOMMENDED")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor)
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                    }
                    
                    // Description
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    
                    // Parameters preview
                    if let parameters = parameters {
                        Text(parameters)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(isSelected ? .accentColor.opacity(0.8) : .secondary.opacity(0.8))
                            .padding(.top, 2)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : (isHovered ? Color.gray.opacity(0.1) : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    PreferencesView()
}
