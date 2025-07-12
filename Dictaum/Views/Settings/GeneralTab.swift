//
//  GeneralTab.swift
//  Dictaum
//
//  Created by Siddhartha Reddy on 02/07/25.
//

import SwiftUI
import KeyboardShortcuts

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
                            HStack(spacing: 4) {
                                Text("Toggle mode:")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary.opacity(0.8))
                                Text("Tap once and begin dictation; tap again to transcribe and paste")
                                    .font(.caption)
                                    .foregroundColor(.primary.opacity(0.8))
                            }
                            HStack(spacing: 4) {
                                Text("Push-to-talk:")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary.opacity(0.8))
                                Text("Press and hold; dictate to transcribe only while the button is held")
                                    .font(.caption)
                                    .foregroundColor(.primary.opacity(0.8))
                            }
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
                Text("Transcription Shortcuts")
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