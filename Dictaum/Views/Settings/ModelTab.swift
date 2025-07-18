//
//  ModelTab.swift
//  Dictaum
//
//  Created by Siddhartha Reddy on 02/07/25.
//

import SwiftUI

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
                    
                    // Attribute badges below name
                    AttributeBadges(attributes: model.attributes)
                    
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

struct AttributeBadges: View {
    let attributes: [ModelInfo.ModelAttribute]
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(attributes, id: \.self) { attribute in
                AttributeBadge(attribute: attribute)
            }
        }
    }
}

struct AttributeBadge: View {
    let attribute: ModelInfo.ModelAttribute
    
    var body: some View {
        Text(attribute.rawValue)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(attribute.color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(attribute.color.opacity(0.15))
            .cornerRadius(4)
    }
}

struct ModelDownloadModal: View {
    @ObservedObject var modelManager: ModelManager
    @ObservedObject var settingsStore: SettingsStore
    @Environment(\.dismiss) private var dismiss
    
    let modelInfo: ModelInfo
    
    @State private var isVisible = false
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                    .symbolEffect(.pulse, isActive: isDownloading)
                
                Text("Downloading Model")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondaryAccent)
                
                Text(modelInfo.displayName)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Download Progress")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        if case .downloading(let progress) = downloadState {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(Int(progress * 100))%")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.accentColor)
                                
                                // Show helpful text for slow downloads
                                if progress > 0.3 && progress < 0.7 {
                                    Text("Large files downloading...")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else if case .warming = downloadState {
                            Text("Warming up...")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    ProgressView(value: progressValue, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle())
                        .scaleEffect(y: 2)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Model Information")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Label("Size: \(modelInfo.diskSize)", systemImage: "internaldrive")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Label("Memory: \(modelInfo.memoryUsage)", systemImage: "memorychip")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if case .warming = downloadState {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Warming up model with sample audio", systemImage: "waveform")
                            .font(.caption)
                            .foregroundColor(.orange)
                        
                        Text("This prepares the model for faster transcription")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)
                } else if case .downloading(let progress) = downloadState {
                    VStack(alignment: .leading, spacing: 4) {
                        if progress > 0.3 && progress < 0.8 {
                            Label("Large model files are downloading", systemImage: "info.circle")
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            Text("Download may slow down during this phase")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            HStack {
                if case .downloaded = downloadState {
                    Spacer()
                    
                    Button("Done") {
                        settingsStore.showDownloadModal = false
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Cancel") {
                        modelManager.cancelCurrentDownload()
                        settingsStore.showDownloadModal = false
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                    
                    Spacer()
                }
            }
        }
        .padding(24)
        .frame(width: 400)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 20)
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .opacity(isVisible ? 1.0 : 0.0)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isVisible = true
            }
        }
        .onDisappear {
            if case .downloading = downloadState {
                modelManager.cancelCurrentDownload()
            }
        }
    }
    
    private var downloadState: ModelDownloadState {
        modelManager.downloadStates[modelInfo.id] ?? .notDownloaded
    }
    
    private var progressValue: Double {
        switch downloadState {
        case .downloading(let progress):
            return progress
        case .warming:
            return 1.0
        case .downloaded:
            return 1.0
        default:
            return 0.0
        }
    }
    
    private var isDownloading: Bool {
        if case .downloading = downloadState {
            return true
        }
        return false
    }
}