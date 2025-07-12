//
//  ShortcutCenter.swift
//  Dictaum
//
//  Created by Siddhartha Reddy on 02/07/25.
//

import Foundation
import KeyboardShortcuts

class ShortcutCenter {
    var onDictationTap: (() -> Void)?
    var onDictationHoldStart: (() -> Void)?
    var onDictationHoldEnd: (() -> Void)?
    
    private var isHoldActive = false
    private var holdTimer: Timer?
    private let holdThreshold: TimeInterval = 0.3 // 300ms
    
    func installHandlers() {
        KeyboardShortcuts.onKeyDown(for: .dictation) { [weak self] in
            guard let self = self else { return }
            
            // Start timer to detect hold
            self.holdTimer = Timer.scheduledTimer(withTimeInterval: self.holdThreshold, repeats: false) { _ in
                // Threshold reached - this is a hold
                if !self.isHoldActive {
                    self.isHoldActive = true
                    self.onDictationHoldStart?()
                }
            }
        }
        
        KeyboardShortcuts.onKeyUp(for: .dictation) { [weak self] in
            guard let self = self else { return }
            
            // Cancel timer
            self.holdTimer?.invalidate()
            self.holdTimer = nil
            
            if self.isHoldActive {
                // This was a hold - end it
                self.isHoldActive = false
                self.onDictationHoldEnd?()
            } else {
                // This was a quick tap
                self.onDictationTap?()
            }
        }
    }
}