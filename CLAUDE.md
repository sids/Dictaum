# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Dictaum is a macOS menu bar app that provides real-time speech-to-text transcription with local processing. The app captures audio via configurable keyboard shortcuts (toggle or push-to-talk modes), transcribes speech using WhisperKit (Core ML), and automatically pastes the transcribed text into the active application.

## Build and Development Commands

### Building and Running
```bash
# Open project in Xcode
open Dictaum.xcodeproj

# Build from command line (Debug)
xcodebuild -project Dictaum.xcodeproj -scheme Dictaum -configuration Debug build

# Build for Release
xcodebuild -project Dictaum.xcodeproj -scheme Dictaum -configuration Release build

# Clean build folder
xcodebuild -project Dictaum.xcodeproj -scheme Dictaum clean

# Build and run (opens in Xcode)
xcodebuild -project Dictaum.xcodeproj -scheme Dictaum -configuration Debug build && open build/Debug/Dictaum.app
```

### Testing
```bash
# Run all tests
xcodebuild test -project Dictaum.xcodeproj -scheme Dictaum -destination 'platform=macOS'

# Run unit tests only
xcodebuild test -project Dictaum.xcodeproj -scheme Dictaum -destination 'platform=macOS' -only-testing:DictaumTests

# Run UI tests only
xcodebuild test -project Dictaum.xcodeproj -scheme Dictaum -destination 'platform=macOS' -only-testing:DictaumUITests

# Run a specific test
xcodebuild test -project Dictaum.xcodeproj -scheme Dictaum -destination 'platform=macOS' -only-testing:DictaumTests/ModelManagerTests/testModelPaths

# Run tests with verbose output
xcodebuild test -project Dictaum.xcodeproj -scheme Dictaum -destination 'platform=macOS' -verbose
```

### Package Management
```bash
# Update dependencies
xcodebuild -resolvePackageDependencies -project Dictaum.xcodeproj -scheme Dictaum

# View resolved package versions
cat Dictaum.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
```

Dependencies:
- **WhisperKit** (main branch) - Core ML speech recognition
- **KeyboardShortcuts** (v2.3.0) - Global hotkey management
- **swift-transformers** (v0.1.15) - ML model support
- Package.resolved is committed and should be updated when dependencies change

### Code Signing and Notarization
```bash
# Archive for distribution
xcodebuild archive -project Dictaum.xcodeproj -scheme Dictaum -archivePath build/Dictaum.xcarchive

# Export for notarization
xcodebuild -exportArchive -archivePath build/Dictaum.xcarchive -exportPath build/export -exportOptionsPlist ExportOptions.plist
```

## Architecture Overview

The app follows a modular architecture with clear separation of concerns:

```
DictationController (Main State Machine)
├── MicRecorder (AVAudioEngine-based audio capture)
├── Transcriber (WhisperKit integration)
├── PasteService (Text insertion via CGEvent)
├── OverlayWindow (Non-activating waveform display)
├── ShortcutCenter (Global hotkey handling)
└── ModelManager (WhisperKit model lifecycle)
```

### Core State Flow

1. **Idle State**: App waits for hotkey activation
2. **Recording State**: MicRecorder captures audio, OverlayWindow shows waveform
3. **Processing State**: Transcriber converts audio to text
4. **Paste Action**: PasteService inserts text at cursor position
5. **Error State**: Graceful handling with user feedback

### Key Components

**DictationController** (`Controllers/DictationController.swift`): Central coordinator that manages the recording→transcription→paste workflow. Implements a state machine with states: idle, recording, processing, error. All state transitions happen here.

**MicRecorder** (`Services/MicRecorder.swift`): Handles audio capture using AVAudioEngine, downsamples to 16kHz mono for WhisperKit, and provides real-time RMS levels for waveform visualization. Uses producer-consumer pattern for buffer management.

**Transcriber** (`Services/Transcriber.swift`): Wraps WhisperKit for local speech-to-text. Async/await based API with configurable models. Handles model loading and transcription options.

**ModelManager** (`Services/ModelManager.swift`): Manages WhisperKit model lifecycle including download, verification, and loading. Provides progress tracking for downloads and handles model storage in Application Support.

**OverlayWindow** (`Views/OverlayWindow.swift`): Custom NSWindow subclass that displays an animated waveform at the bottom-center of the screen without stealing focus. Uses NSWindowLevel.floating and special window flags.

**ShortcutCenter** (`Controllers/ShortcutCenter.swift`): Manages global keyboard shortcuts using KeyboardShortcuts framework. Supports both toggle and push-to-talk modes with configurable shortcuts.

**HistoryWindowView** (`Views/HistoryWindowView.swift`): Standalone SwiftUI view for the History window, separate from Settings. Displays transcription history with search, playback, and export functionality. Opened via WindowGroup with ID "history-window".

**HistoryWindowMonitor** (`Services/HistoryWindowMonitor.swift`): Monitors History window lifecycle similar to SettingsWindowMonitor. Coordinates dock icon visibility when multiple windows are open.

## Privacy and Permissions

The app requires:
- **Microphone access**: For speech capture (NSMicrophoneUsageDescription)
- **Accessibility permissions**: For simulating Cmd+V to paste text (NSAppleEventsUsageDescription)

All transcription happens locally using Core ML - no data leaves the device except for model downloads from Hugging Face.

### Entitlements (`Dictaum.entitlements`)
- `com.apple.security.app-sandbox`: YES
- `com.apple.security.device.audio-input`: YES
- `com.apple.security.automation.apple-events`: YES
- `com.apple.security.network.client`: YES (for model downloads)
- `com.apple.security.files.user-selected.read-only`: YES

## Development Notes

### State Management
- Uses @MainActor for UI updates from background tasks
- Audio processing happens on dedicated queue, UI updates dispatched to main
- Settings stored in UserDefaults with @AppStorage wrappers
- State transitions are synchronous to prevent race conditions

### Menu Bar Integration
- Uses MenuBarExtra (not NSStatusItem) for modern SwiftUI integration
- Dock icon behavior managed by DockIconHelper based on user preferences
- Settings window activation requires temporary dock icon visibility
- Window management handled by SettingsWindowMonitor to track open state
- History window available as separate WindowGroup scene with ID "history-window"
- HistoryWindowMonitor tracks history window lifecycle for dock icon management

### Audio Processing
- 16kHz mono required for WhisperKit compatibility
- Real-time RMS calculation for 32-bar waveform visualization
- Automatic buffer management with configurable recording limits
- Audio levels calculated on capture queue, UI updates on main thread

### Model Management
- Models stored in `~/Library/Application Support/Dictaum/Models/`
- Download progress tracked with AsyncStream
- Model verification after download ensures integrity
- Supports multiple model variants with speed/accuracy tradeoffs

### Testing Considerations
- Unit tests use Swift Testing framework (`import Testing`)
- UI tests use XCTest framework
- Audio recording tests may require microphone access in test environment
- Model-related tests use mock paths to avoid file system dependencies

## Common Development Patterns

- All async operations use proper error handling with Result types
- UI state updates always happen on @MainActor
- Audio buffer processing follows producer-consumer pattern
- Settings changes trigger reactive updates via Combine publishers
- Window lifecycle events handled through NSWindow.Notifications
- Model downloads use URLSession with progress tracking

## Development Memories

- Always keep @CLAUDE.md up-to-date when you implement major features or capabilities, or when there are changes to the design / architecture / code organization.