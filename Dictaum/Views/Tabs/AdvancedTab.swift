//
//  AdvancedTab.swift
//  Dictaum
//
//  Created by Siddhartha Reddy on 02/07/25.
//

import SwiftUI

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