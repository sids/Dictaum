<div align="center">
  <img src="waveform.badge.microphone.svg" alt="Dictaum Logo" width="128" height="128">
  
  # Dictaum
  
  **Speech-to-Text for Pros**
  
  A lightweight macOS menu bar app for real-time speech-to-text transcription with local processing. Dictaum captures audio via configurable keyboard shortcuts and automatically pastes transcribed text into any application.
</div>

![macOS](https://img.shields.io/badge/macOS-15.0+-blue)
![Swift](https://img.shields.io/badge/Swift-6.0-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
  - [TestFlight Beta](#testflight-beta)
  - [Mac App Store](#mac-app-store-coming-soon)
  - [Build from Source](#build-from-source)
- [Usage](#usage)
- [Tuning and Optimization](#tuning-and-optimization)
  - [Choosing Models](#choosing-models)
  - [Advanced Parameter Tuning](#advanced-parameter-tuning)
  - [Testing and Comparison](#testing-and-comparison)
- [Building](#building)
  - [Prerequisites](#prerequisites)
  - [Build Steps](#build-steps)
  - [Running Tests](#running-tests)
- [Architecture](#architecture)
- [Contributing](#contributing)
  - [Getting Started](#getting-started)
  - [Code Style](#code-style)
  - [Reporting Issues](#reporting-issues)
- [Privacy](#privacy)
- [Troubleshooting](#troubleshooting)
  - [Common Issues](#common-issues)
- [License](#license)
- [Acknowledgments](#acknowledgments)
- [Author](#author)

## Features

- 🎙️ **Real-time transcription** - Speech-to-text with minimal latency
- 🔒 **100% local processing** - All transcription happens on-device using WhisperKit (Core ML)
- ⌨️ **Global keyboard shortcuts** - Toggle or push-to-talk modes
- 📊 **Visual feedback** - Animated waveform overlay during transcription
- 🎯 **Auto-paste** - Transcribed text automatically inserted at cursor position
- 📝 **Transcription history** - Store, search, and replay past transcriptions with audio
- 🎛️ **Multiple models** - Choose between speed and accuracy
- 🚀 **Native performance** - Built with SwiftUI for macOS

## Requirements

- macOS 15.0 or later
- Apple Silicon Mac (M1/M2/M3) or Intel Mac with AVX support
- ~500MB-2GB disk space for ML models

## Installation

### TestFlight Beta
Join the beta and help test Dictaum:
- [Join TestFlight Beta](https://testflight.apple.com/join/Zc99R38Q)

### Mac App Store (Coming Soon)
Dictaum will be available on the Mac App Store soon.

### Build from Source
See [Building](#building) section below for instructions on building and running Dictaum locally.

## Usage

1. **First Launch**
   - Grant microphone access when prompted
   - Grant accessibility permissions for auto-paste functionality
   - Download a WhisperKit model from Settings → Models tab (small model recommended for balance of speed/accuracy)

2. **Transcription** (Default: `Ctrl+Esc`)
   - **Toggle mode**: Tap once and begin dictation; tap again to transcribe and paste
   - **Push-to-talk**: Press and hold; dictate to transcribe only while the button is held
   - Visual waveform appears at bottom of screen during transcription
   - Transcribed text automatically pastes at cursor position when transcription ends
   - Customize shortcut in Settings → Shortcuts tab

3. **History** (Optional)
   - Enable history in Settings → History tab to store transcriptions with audio
   - Access history window via Settings → History → "Open History Window"
   - Search, replay audio, and export past transcriptions
   - Configure retention period and maximum entries

4. **Settings**
   - Click menu bar icon → Settings
   - Configure keyboard shortcuts
   - Choose transcription model
   - Verify permissions status

## Tuning and Optimization

Dictaum provides extensive options to optimize transcription quality for your specific needs through model selection and parameter tuning.

### Choosing Models

Models are available in different sizes, each with trade-offs between speed and accuracy:

- **tiny** (~40MB) - Fastest processing, basic accuracy
- **base** (~150MB) - Good balance for most users
- **small** (~500MB) - Higher accuracy with moderate speed
- **medium** (~1.5GB) - Best accuracy for general use
- **large** (~3GB) - Maximum accuracy, slower processing

**Recommendation**: Start with the **small** model (or **small.en** for English-only use) for everyday use, then test larger models if you need better accuracy for technical or domain-specific content.

### Advanced Parameter Tuning

Access Settings → Advanced tab to fine-tune transcription parameters:

#### Presets (Recommended)
- **Conservative** - Fast processing with basic accuracy (Temp: 0.0, Beam: 1)
- **Balanced** ⭐ - Optimal balance of speed and accuracy (Temp: 0.2, Beam: 3)  
- **Creative** - Highest accuracy with slower processing (Temp: 0.4, Beam: 5)

#### Custom Parameters
Switch to "Custom" preset for manual control:

- **Temperature** (0.0-1.0) - Controls randomness. Lower = more consistent, higher = more creative
- **Beam Size** (1-5) - Search width. Higher = more accurate but slower
- **Best Of** (1-5) - Number of candidates to consider (only when temperature > 0)
- **Top K** (1-50) - Limits vocabulary choices. Lower = more focused

#### Quality Control (Custom Mode Only)
- **Log Probability Threshold** - Reject low-confidence transcriptions
- **Compression Ratio Threshold** - Detect and filter repetitive output
- **Suppress Blank** - Remove empty tokens from transcription start

### Testing and Comparison

Use the History feature to test different models and parameters:

1. **Enable History** - Settings → History → Enable audio & transcription history
2. **Record Test Samples** - Use consistent phrases to test different configurations
3. **Compare Results** - Open History window to view transcription quality metrics
4. **Parameter Analysis** - Each history entry shows the exact model and parameters used
5. **Audio Replay** - Listen to original audio alongside transcription to assess accuracy

**Pro Tip**: Record the same phrase with different models/parameters, then use the History window to compare accuracy and processing time side-by-side.

## Building

### Prerequisites
- Xcode 16.0 or later
- macOS 15.0 SDK or later

### Build Steps

1. Clone the repository:
```bash
git clone https://github.com/yourusername/dictaum.git
cd dictaum
```

2. Open in Xcode:
```bash
open Dictaum.xcodeproj
```

3. Select your development team in project settings (required for code signing)

4. Build and run:
   - Press `Cmd+R` in Xcode, or
   - Use command line:
```bash
xcodebuild -project Dictaum.xcodeproj -scheme Dictaum -configuration Release build
```

5. Find the built app:
   - The app will be located at `build/Release/Dictaum.app`
   - You can open it directly: `open build/Release/Dictaum.app`
   - Or drag it to your Applications folder for permanent installation

### Running Tests

```bash
# Run all tests
xcodebuild test -project Dictaum.xcodeproj -scheme Dictaum -destination 'platform=macOS'

# Run unit tests only
xcodebuild test -project Dictaum.xcodeproj -scheme Dictaum -destination 'platform=macOS' -only-testing:DictaumTests
```

## Architecture

Dictaum uses a modular architecture with clear separation of concerns:

- **DictationController** - Central state machine managing the transcription workflow
- **MicRecorder** - Audio capture and processing using AVAudioEngine
- **Transcriber** - WhisperKit integration for speech-to-text
- **PasteService** - Text insertion via accessibility APIs
- **OverlayWindow** - Non-activating waveform visualization
- **HistoryManager** - Store and manage transcription history with audio files

See [CLAUDE.md](CLAUDE.md) for detailed architecture documentation.

## Contributing

We welcome contributions! Please follow these guidelines:

### Getting Started

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests to ensure everything works
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to your branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Code Style

- Follow existing Swift conventions in the codebase
- Use SwiftUI for new UI components
- Ensure all async operations use proper error handling
- Add tests for new functionality

### Reporting Issues

- Use GitHub Issues for bug reports and feature requests
- Include macOS version and hardware details
- Provide steps to reproduce for bugs
- Check existing issues before creating new ones

## Privacy

Dictaum is designed with privacy in mind:
- All speech processing happens locally on your Mac
- No audio or text data is sent to external servers
- Only network access is for downloading ML models from Hugging Face
- History data stored locally in `~/Library/Application Support/Dictaum/History`
- No analytics or telemetry

## Troubleshooting

### Common Issues

**"Dictaum can't be opened because Apple cannot check it for malicious software"**
- Right-click the app and select "Open" to bypass Gatekeeper

**No transcription appearing**
- Check microphone permissions in System Settings → Privacy & Security
- Ensure a model is downloaded in Preferences → Models
- Try a different microphone input device

**Auto-paste not working**
- Grant accessibility permissions in System Settings → Privacy & Security → Accessibility
- Some apps may block programmatic paste - try manual paste (Cmd+V) after transcription

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [WhisperKit](https://github.com/argmaxinc/WhisperKit) - Core ML implementation of OpenAI's Whisper
- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) - Global keyboard shortcuts in SwiftUI
- OpenAI Whisper team for the original speech recognition model

## Author

Created by [Siddhartha Reddy Kothakapu](https://sids.in/)

---

<p align="center">
  Made with ❤️ for the macOS community
</p>