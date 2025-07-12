//
//  HistoryWindowView.swift
//  Dictaum
//
//  Created by Siddhartha Reddy on 02/07/25.
//

import SwiftUI
import AVFoundation

struct HistoryWindowView: View {
    @StateObject private var historyManager = HistoryManager.shared
    @State private var searchText = ""
    @State private var selectedEntry: HistoryEntry?
    @State private var isPlayingAudio = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var showingDeleteConfirmation = false
    @State private var showingClearAllConfirmation = false
    @State private var entryToDelete: HistoryEntry?
    @State private var showDetailForEntry: HistoryEntry?
    
    var filteredEntries: [HistoryEntry] {
        if searchText.isEmpty {
            return historyManager.entries
        } else {
            return historyManager.entries.filter { entry in
                entry.transcript.localizedCaseInsensitiveContains(searchText) ||
                entry.modelUsed.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with controls
            VStack(spacing: 12) {
                HStack {
                    Text("Transcription History")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Menu {
                        Button("Export History") {
                            exportHistory()
                        }
                        .disabled(historyManager.entries.isEmpty)
                        
                        Divider()
                        
                        Button("Delete All", role: .destructive) {
                            showingClearAllConfirmation = true
                        }
                        .disabled(historyManager.entries.isEmpty)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 16))
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                    .disabled(historyManager.entries.isEmpty)
                }
                
                TextField("Search transcriptions...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                
                // Stats row
                HStack {
                    Text("\(historyManager.entryCount) entries")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Storage: \(historyManager.storageSize)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            
            Divider()
            
            // History list
            if filteredEntries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text(searchText.isEmpty ? "No transcription history yet" : "No matching entries found")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    if searchText.isEmpty {
                        Text("Start dictating to see your history here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List(filteredEntries) { entry in
                    HistoryEntryRow(
                        entry: entry,
                        isSelected: selectedEntry?.id == entry.id,
                        isPlayingAudio: isPlayingAudio && selectedEntry?.id == entry.id,
                        onSelect: { showDetailForEntry = entry },
                        onPlay: { playAudio(for: entry) },
                        onDelete: { deleteEntry(entry) }
                    )
                }
                .listStyle(.plain)
            }
        }
        .alert("Delete Entry", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let entry = entryToDelete {
                    historyManager.removeEntry(withId: entry.id)
                    if selectedEntry?.id == entry.id {
                        selectedEntry = nil
                    }
                    entryToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) { entryToDelete = nil }
        } message: {
            Text("Are you sure you want to delete this transcription entry? This action cannot be undone.")
        }
        .alert("Delete All History", isPresented: $showingClearAllConfirmation) {
            Button("Delete All", role: .destructive) {
                historyManager.removeAllEntries()
                selectedEntry = nil
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete all transcription history? This action cannot be undone.")
        }
        .onChange(of: historyManager.entries) { _, _ in
            // Refresh the view when entries change
        }
        .sheet(item: $showDetailForEntry) { entry in
            HistoryDetailSheet(
                entry: entry,
                isPlayingAudio: isPlayingAudio && selectedEntry?.id == entry.id,
                onPlay: { playAudio(for: entry) },
                onDelete: {
                    showDetailForEntry = nil
                    deleteEntry(entry)
                }
            )
        }
        .navigationTitle("Transcription History")
    }
    
    private func deleteEntry(_ entry: HistoryEntry) {
        entryToDelete = entry
        showingDeleteConfirmation = true
    }
    
    
    private func playAudio(for entry: HistoryEntry) {
        // If we're currently playing this entry, stop it
        if isPlayingAudio && selectedEntry?.id == entry.id {
            audioPlayer?.stop()
            audioPlayer = nil
            isPlayingAudio = false
            selectedEntry = nil
            return
        }
        
        // Otherwise, start playing
        guard let audioURL = historyManager.getAudioFileURL(for: entry) else {
            print("Audio file not found for entry: \(entry.id)")
            return
        }
        
        do {
            audioPlayer?.stop()
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.play()
            isPlayingAudio = true
            selectedEntry = entry
            
            // Stop playing state after audio finishes
            DispatchQueue.main.asyncAfter(deadline: .now() + (audioPlayer?.duration ?? 0)) {
                if self.selectedEntry?.id == entry.id {
                    self.isPlayingAudio = false
                    self.selectedEntry = nil
                }
            }
        } catch {
            print("Failed to play audio: \(error)")
        }
    }
    
    private func exportHistory() {
        guard let exportURL = historyManager.exportHistory() else {
            print("Failed to export history")
            return
        }
        
        NSWorkspace.shared.open(exportURL)
    }
}

#Preview {
    HistoryWindowView()
        .frame(width: 800, height: 600)
}