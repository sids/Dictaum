//
//  WaveformView.swift
//  Dictaum
//
//  Created by Siddhartha Reddy on 02/07/25.
//

import SwiftUI

class WaveformViewModel: ObservableObject {
    @Published var audioLevels: [CGFloat] = Array(repeating: 0, count: 32)
    @Published var isProcessing: Bool = false
}

struct WaveformView: View {
    @ObservedObject var viewModel: WaveformViewModel
    
    var body: some View {
        ZStack {
            Image(systemName: "waveform.badge.microphone")
                .font(.system(size: 24))
                .symbolEffect(.variableColor.iterative.dimInactiveLayers.reversing, options: .repeat(.continuous))
                .foregroundStyle(.white)
                .opacity(viewModel.isProcessing ? 0 : 1)
                .scaleEffect(viewModel.isProcessing ? 0.8 : 1)
            
            Image(systemName: "waveform")
                .font(.system(size: 24))
                .foregroundStyle(.white)
                .symbolEffect(.variableColor.iterative.dimInactiveLayers.nonReversing, options: .repeat(.continuous))
                .opacity(viewModel.isProcessing ? 1 : 0)
                .scaleEffect(viewModel.isProcessing ? 1 : 1.2)
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.isProcessing)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.black.opacity(0.6))
        )
        .frame(width: 70, height: 70)
    }
}

#Preview {
    WaveformView(viewModel: WaveformViewModel())
        .padding()
}
