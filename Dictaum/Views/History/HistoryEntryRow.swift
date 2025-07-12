//
//  HistoryEntryRow.swift
//  Dictaum
//
//  Created by Siddhartha Reddy on 02/07/25.
//

import SwiftUI

struct HistoryEntryRow: View {
    let entry: HistoryEntry
    let isSelected: Bool
    let isPlayingAudio: Bool
    let onSelect: () -> Void
    let onPlay: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onPlay) {
                Image(systemName: isPlayingAudio ? "stop.fill" : "play.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.accentColor)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .help("Play audio")
            
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.shortTranscript)
                    .font(.body)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Text(entry.formattedTimestamp)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(entry.formattedDuration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(entry.language.uppercased())
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !entry.modelUsed.isEmpty {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(entry.modelUsed)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(.red)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .help("Delete entry")
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
        .cornerRadius(8)
        .onTapGesture {
            onSelect()
        }
    }
}