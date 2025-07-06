//
//  ModelDownloadModal.swift
//  Dictaum
//
//  Created by Siddhartha Reddy on 02/07/25.
//

import SwiftUI

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
                    .foregroundColor(.secondaryColor)
                
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
                            Text("\(Int(progress * 100))%")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.accentColor)
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

#Preview {
    ModelDownloadModal(
        modelManager: ModelManager.shared,
        settingsStore: SettingsStore.shared,
        modelInfo: ModelInfo(
            id: "openai_whisper-base.en",
            name: "openai_whisper-base.en",
            displayName: "Whisper Base (English)",
            diskSize: "142 MB",
            memoryUsage: "~500 MB",
            speed: .fast,
            isEnglishOnly: true
        )
    )
}