//
//  OverlayWindow.swift
//  Dictaum
//
//  Created by Siddhartha Reddy on 02/07/25.
//

import SwiftUI
import AppKit

class OverlayWindow: NSWindow {
    private var hostingView: NSHostingView<WaveformView>?
    private let waveformViewModel = WaveformViewModel()
    
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 70, height: 70),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        setupWindow()
        setupContent()
    }
    
    private func setupWindow() {
        isOpaque = false
        backgroundColor = .clear
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        isMovableByWindowBackground = false
        hasShadow = true
        ignoresMouseEvents = true
    }
    
    private func setupContent() {
        let waveformView = WaveformView(viewModel: waveformViewModel)
        hostingView = NSHostingView(rootView: waveformView)
        contentView = hostingView
        contentView?.wantsLayer = true
    }
    
    func show(with levels: [CGFloat]) {
        positionWindow()
        
        waveformViewModel.isProcessing = false
        waveformViewModel.audioLevels = levels
        
        alphaValue = 0
        makeKeyAndOrderFront(nil)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            animator().alphaValue = 1.0
        }
    }
    
    func hide() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            animator().alphaValue = 0.0
        } completionHandler: {
            self.orderOut(nil)
        }
    }
    
    func startProcessing() {
        waveformViewModel.isProcessing = true
    }
    
    private func positionWindow() {
        guard let screen = NSScreen.main else { return }
        
        let screenFrame = screen.visibleFrame
        let windowWidth = frame.width
        
        let x = screenFrame.midX - windowWidth / 2
        let y = screenFrame.minY + 24
        
        setFrameOrigin(NSPoint(x: x, y: y))
    }
}