import SwiftUI

struct HistoryTab: View {
    @ObservedObject var store: SettingsStore
    @StateObject private var historyManager = HistoryManager.shared
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable audio & transcription history", isOn: $store.historyEnabled)
                
                HStack {
                    Text("Keep history for:")
                    Spacer()
                    Picker("", selection: $store.historyRetentionDays) {
                        Text("7 days").tag(7)
                        Text("30 days").tag(30)
                        Text("90 days").tag(90)
                        Text("1 year").tag(365)
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)
                }
                
                HStack {
                    Text("Maximum entries:")
                    Spacer()
                    Picker("", selection: $store.historyMaxEntries) {
                        Text("100").tag(100)
                        Text("500").tag(500)
                        Text("1000").tag(1000)
                        Text("5000").tag(5000)
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)
                }
                
                HStack {
                    Spacer()
                    Button("Clean Up Old Entries") {
                        historyManager.manualCleanup()
                    }
                    .buttonStyle(.bordered)
                    .disabled(!historyManager.hasOldEntries)
                }
            } header: {
                Text("History Settings")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondaryAccent)
            }
            
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(historyManager.entryCount) entries")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("Storage: \(historyManager.storageSize)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Open History") {
                        DockIconHelper.setHidden(false)
                        openWindow(id: "history-window")
                    }
                    .buttonStyle(.borderedProminent)
                }
            } header: {
                Text("History")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondaryAccent)
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    HistoryTab(store: SettingsStore.shared)
        .frame(width: 600, height: 500)
}
