//
//  PasteService.swift
//  Dictaum
//
//  Created by Siddhartha Reddy on 02/07/25.
//

import Foundation
import AppKit
import CoreGraphics
import ApplicationServices

class PasteService {
    func paste(_ text: String) {
        guard !text.isEmpty else { return }
        
        // Try accessibility API first
        if insertTextViaAccessibility(text) {
            return // Success, no clipboard needed
        }
        
        // Fallback to clipboard with restoration
        pasteViaClipboardWithRestore(text)
    }
    
    private func insertTextViaAccessibility(_ text: String) -> Bool {
        // Get the frontmost application
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            return false
        }
        
        // Get the application's AXUIElement
        let appElement = AXUIElementCreateApplication(frontApp.processIdentifier)
        
        // Get the focused element
        var focusedElementRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedElementRef)
        
        guard result == .success, let element = focusedElementRef else {
            return false
        }
        
        let focusedElement = unsafeBitCast(element, to: AXUIElement.self)
        
        // Check if the focused element supports text insertion
        var roleValue: AnyObject?
        let roleResult = AXUIElementCopyAttributeValue(focusedElement, kAXRoleAttribute as CFString, &roleValue)
        
        guard roleResult == .success,
              let role = roleValue as? String,
              (role == kAXTextFieldRole || role == kAXTextAreaRole || role == kAXComboBoxRole) else {
            return false
        }
        
        // Try to insert the text directly
        let textValue = text as CFString
        let insertResult = AXUIElementSetAttributeValue(focusedElement, kAXSelectedTextAttribute as CFString, textValue)
        
        if insertResult == .success {
            return true
        }
        
        // If direct insertion failed, try setting the entire value (less ideal but works for some fields)
        var currentValue: AnyObject?
        let getCurrentResult = AXUIElementCopyAttributeValue(focusedElement, kAXValueAttribute as CFString, &currentValue)
        
        if getCurrentResult == .success {
            let currentText = (currentValue as? String) ?? ""
            let newText = currentText + text
            let newValue = newText as CFString
            let setResult = AXUIElementSetAttributeValue(focusedElement, kAXValueAttribute as CFString, newValue)
            return setResult == .success
        }
        
        return false
    }
    
    private func pasteViaClipboardWithRestore(_ text: String) {
        // Save original clipboard contents
        let originalText = NSPasteboard.general.string(forType: .string)
        let originalData = NSPasteboard.general.data(forType: .string)
        
        // Set transcribed text to clipboard
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        
        // Simulate paste command
        simulatePasteCommand()
        
        // Restore original clipboard after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSPasteboard.general.clearContents()
            
            if let originalText = originalText {
                NSPasteboard.general.setString(originalText, forType: .string)
            } else if let originalData = originalData {
                NSPasteboard.general.setData(originalData, forType: .string)
            }
            // If no original content, leave clipboard empty
        }
    }
    
    private func simulatePasteCommand() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let vKeyCode: CGKeyCode = 0x09 // 'v' key
        
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true)
        keyDown?.flags = .maskCommand
        
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false)
        keyUp?.flags = .maskCommand
        
        let location = CGEventTapLocation.cgAnnotatedSessionEventTap
        keyDown?.post(tap: location)
        keyUp?.post(tap: location)
    }
}