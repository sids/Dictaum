# Dictaum – Requirements & Technical Approach

*Last updated: 02 July 2025*

---

## 1  Objective

Build a **macOS menu‑bar app** (“Dictaum”) that turns speech into text and pastes it wherever the user’s caret is. The app must:

1. Start/stop recording via **user‑configurable global shortcuts**.
2. Offer **two modes**:
   - **Toggle** – tap once to start, tap again to stop.
   - **Push‑to‑talk** – record while the keys are held down.
3. Show a **bottom‑centre overlay** with a live waveform while listening.
4. Provide a **Settings window** for:
   - Editing shortcuts (via *KeyboardShortcuts* recorders).
   - Enabling “**Launch at login**”.
5. Run entirely on‑device using **WhisperKit** (Core ML) for transcription.
6. Respect App Sandbox, hardened runtime, and macOS privacy prompts.

---

## 2  End‑User Stories

| As a…                   | I want…                               | So that…                                       |
| ----------------------- | ------------------------------------- | ---------------------------------------------- |
| Writer                  | Press my chosen keys and dictate text | I can compose faster without switching windows |
| Power user              | Use push‑to‑talk like a walkie‑talkie | I control exactly when the mic is on           |
| Security‑conscious user | Local transcription only              | My audio never leaves the Mac                  |
| New user                | Clear permission prompts & onboarding | I trust the app and know why it needs access   |
| Frequent user           | App to start with macOS               | I never have to launch it manually             |

---

## 3  High‑Level Architecture

```
NSStatusItem                PreferencesView (SwiftUI Form)
   │                               │
   ▼                               ▼
DictationController  ◄──►  SettingsStore (UserDefaults)
   │        ▲                    ▲
   │        │                    │
MicRecorder   Transcriber   LaunchAtLoginHelper
(AVAudioEngine) (WhisperKit)      │
   │        │                    ▼
   │        └──► PasteService (NSPasteboard + CGEvent)
   ▼
OverlayWindow (waveform)
```

*All boxes are Swift types in a single sandboxed target.*

---

## 4  Key Modules & Responsibilities

| Module                  | Responsibility                                                                                          | Sample API                           |
| ----------------------- | ------------------------------------------------------------------------------------------------------- | ------------------------------------ |
| **SettingsStore**       | Wrap `UserDefaults` keys for shortcuts, launch‑at‑login flag.                                           | `@AppStorage("toggleShortcut")`      |
| **PreferencesView**     | SwiftUI `Form` containing two `KeyboardShortcuts.Recorder`s and a `Toggle` for launch‑at‑login.         | —                                    |
| **ShortcutCenter**      | Subscribes to `.onKeyDown` / `.onKeyUp` for the two `KeyboardShortcuts.Name`s and maps them to intents. | `func installHandlers()`             |
| **DictationController** | Finite‑state‑machine that orchestrates MicRecorder ⇢ Transcriber ⇢ PasteService; shows/hides overlay.   | `start() / stop()`                   |
| **MicRecorder**         | Configure `AVAudioEngine`, install tap, down‑sample to 16 kHz mono, expose async buffer stream.         | `start()`, `stop()`, `bufferHandler` |
| **Transcriber**         | Wrap WhisperKit streaming API; expose `func transcribe(_ buf) async -> String?`                         | —                                    |
| **PasteService**        | Write text to clipboard + send ⌘V via `CGEvent`.                                                        | `paste(_ text: String)`              |
| **OverlayWindow**       | Borderless, non‑activating `NSWindow` pinned to bottom‑centre; hosts SwiftUI waveform animation.        | `show()`, `hide()`                   |
| **LaunchAtLoginHelper** | Use `SMAppService.mainApp.register()/unregister()` to toggle login‑item.                                | `setEnabled(Bool)`                   |

---

## 5  External Dependencies

| Library               | URL                                                 | Notes                                                          |
| --------------------- | --------------------------------------------------- | -------------------------------------------------------------- |
| **KeyboardShortcuts** | `https://github.com/sindresorhus/KeyboardShortcuts` | Shortcut recorder UI + global hot‑keys                         |
| **WhisperKit**        | `https://github.com/argmaxinc/WhisperKit`           | Bundles Whisper Core ML models; pick *small‑distil* as default |

Add both via *File ▸ Add Packages…*; commit `Package.resolved`.

---

## 6  Entitlements & Privacy

| Key                                                     | Purpose                                   |
| ------------------------------------------------------- | ----------------------------------------- |
| `com.apple.security.app-sandbox`                        | Required for Mac App Store & notarisation |
| `com.apple.security.device.microphone`                  | Access to mic                             |
| Hardened Runtime ▸ Audio Input                          | Matches the above for runtime             |
| `com.apple.security.automation.apple-events` (optional) | Future Apple‑events scripting             |

**Info.plist** keys

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Needed to capture speech for transcription.</string>
<key>NSAppleEventsUsageDescription</key>
<string>Needed to paste transcribed text into the frontmost app.</string>
```

---

## 7  User‑Configurable Shortcuts

```swift
extension KeyboardShortcuts.Name {
    static let toggleDictation = Self("toggleDictation", default: .init(.d, modifiers: [.command, .option]))
    static let pushToTalk = Self("pushToTalk") // no default
}
```

*PreferencesView* snippet:

```swift
Form {
    KeyboardShortcuts.Recorder("Start/Stop on tap", name: .toggleDictation)
    KeyboardShortcuts.Recorder("Push‑to‑talk (hold)", name: .pushToTalk)
    Toggle("Launch Dictaum at login", isOn: $store.launchAtLogin)
}
.padding()
.frame(width: 360)
```

---

## 8  Launch at Login Implementation

```swift
import ServiceManagement

struct LaunchAtLoginHelper {
    static func setEnabled(_ enabled: Bool) {
        if enabled {
            try? SMAppService.mainApp.register()
        } else {
            SMAppService.mainApp.unregister()
        }
    }
}
```

This call triggers macOS’s standard “Allow ‘Dictaum’ to run at login?” prompt. No extra entitlement is required in macOS 13 +.

---

## 9  Overlay Waveform Window

*Requirements*

1. Always on top but **non‑activating** (doesn’t steal focus).
2. Fixed size (\~300 × 80 pt) pinned to bottom‑centre, 24 pt above the safe area.
3. SwiftUI view with an `@State` array of amplitudes feeding a `TimelineView` animated `Shape`.

*Window shell*

```swift
class OverlayWindow: NSWindow {
    init() {
        super.init(contentRect: .zero,
                   styleMask: [.borderless],
                   backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .ignoresCycle]
        ignoresMouseEvents = true
    }
}
```

*Waveform SwiftUI* (simplified):

```swift
struct WaveformView: View {
    @State private var levels: [CGFloat] = Array(repeating: 0, count: 32)
    var body: some View {
        GeometryReader { geo in
            Path { path in
                let w = geo.size.width / CGFloat(levels.count)
                for (i, level) in levels.enumerated() {
                    let x = CGFloat(i) * w
                    let h = level * geo.size.height
                    path.addRoundedRect(in: CGRect(x: x, y: (geo.size.height-h)/2,
                                                    width: w*0.8, height: h), cornerSize: CGSize(width: 2, height: 2))
                }
            }
            .fill(.accent)
            .animation(.linear(duration: 0.05), value: levels)
        }
        .frame(height: 60)
        .padding(.horizontal)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}
```

`MicRecorder` should push RMS levels on the main actor every 50 ms to drive the animation.

---

## 10  Recording State Machine

| State         | Entry action         | Exit condition                      | Exit action                 |
| ------------- | -------------------- | ----------------------------------- | --------------------------- |
| **idle**      | —                    | Shortcut pressed                    | show overlay, `mic.start()` |
| **recording** | buffer ⇢ transcriber | Shortcut released or toggle pressed | `mic.stop()`, hide overlay  |

Edge cases: if both shortcuts are identical, *push‑to‑talk* takes precedence.

---

## 11  Paste Logic

```swift
func paste(_ text: String) {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
    let src = CGEventSource(stateID: .combinedSessionState)
    let vKey: CGKeyCode = 0x09 // ‘v’
    CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: true)?.setFlags(.maskCommand).post(tap: .cgAnnotatedSessionEventTap)
    CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: false)?.setFlags(.maskCommand).post(tap: .cgAnnotatedSessionEventTap)
}
```

macOS will prompt for **Accessibility** the first time this runs.

---

## 12  Build & Run Checklist

1. Xcode ▸ Scheme ▸ *Dictaum* ▸ **Run** → verify menu‑bar icon appears.
2. Tap default shortcut (⌥⌘D) → Microphone dialog appears → allow.
3. Speak → text is pasted into TextEdit.
4. Verify overlay animates and disappears.
5. Open **Settings** (⌘,) → change shortcuts → test again.
6. Enable “Launch at login”, quit app, log out/in → app auto starts.

---

## 13  Future Enhancements (backlog)

- Language detection & automatic language switch.
- VAD (Voice Activity Detection) to auto‑stop after silence.
- Optional punctuation / capitalization heuristics.
- iCloud sync of settings via `AppStorage` + `NSUbiquitousKeyValueStore`.
- Customizable overlay theme & placement.

---

> **Hand‑off note:** This `requirements.md` captures the full scope, APIs, dependencies and UI expectations. The next step is to scaffold the code‑base, beginning with project template ➜ Swift package resolution ➜ entitlements ➜ module stubs.

