//
//  ShortcutCenter.swift
//  Dictaum
//
//  Created by Siddhartha Reddy on 02/07/25.
//

import Foundation
import KeyboardShortcuts

class ShortcutCenter {
    var onToggleAction: (() -> Void)?
    var onPushToTalkStart: (() -> Void)?
    var onPushToTalkEnd: (() -> Void)?
    
    private var isPushToTalkActive = false
    
    func installHandlers() {
        KeyboardShortcuts.onKeyDown(for: .toggleDictation) { [weak self] in
            guard let self = self, !self.isPushToTalkActive else { return }
            self.onToggleAction?()
        }
        
        KeyboardShortcuts.onKeyDown(for: .pushToTalk) { [weak self] in
            guard let self = self else { return }
            if !self.isPushToTalkActive {
                self.isPushToTalkActive = true
                self.onPushToTalkStart?()
            }
        }
        
        KeyboardShortcuts.onKeyUp(for: .pushToTalk) { [weak self] in
            guard let self = self else { return }
            if self.isPushToTalkActive {
                self.isPushToTalkActive = false
                self.onPushToTalkEnd?()
            }
        }
    }
}