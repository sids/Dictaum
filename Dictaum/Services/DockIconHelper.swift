//
//  DockIconHelper.swift
//  Dictaum
//
//  Created by Siddhartha Reddy on 02/07/25.
//

import Foundation
import AppKit

struct DockIconHelper {
    static func setHidden(_ hidden: Bool) {
        DispatchQueue.main.async {
            // Remember the current key window and its frame before changing activation policy
            let currentKeyWindow = NSApp.keyWindow
            let currentFrame = currentKeyWindow?.frame
            let wasVisible = currentKeyWindow?.isVisible ?? false
            
            if hidden {
                NSApp.setActivationPolicy(.accessory)
            } else {
                NSApp.setActivationPolicy(.regular)
            }
            
            // Only restore focus if we had a visible window before the change
            if wasVisible, let window = currentKeyWindow {
                // Minimal delay to reduce flicker
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
                    // Restore the window frame if it changed
                    if let frame = currentFrame, window.frame != frame {
                        window.setFrame(frame, display: false)
                    }
                    
                    // Smoothly restore focus
                    window.makeKeyAndOrderFront(nil)
                    if hidden {
                        // For accessory apps, we need to force activation
                        NSApp.activate(ignoringOtherApps: true)
                    }
                }
            }
        }
    }
    
    static func applyInitialSetting() {
        // Always start as accessory (dock icon hidden) by default
        setHidden(true)
    }
}