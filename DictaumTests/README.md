# Testing Audio Files

## WER (Word Error Rate) Testing

The WER harness in `WERHarness.swift` can use real audio files for more accurate testing. Currently, it falls back to synthetic audio generation when real files are not available.

### Adding Real Audio Files

To add real audio files for testing:

1. **Create test audio files** with the following names:
   - `short_greeting.wav` - A short greeting like "Hello, how are you today?"
   - `technical_terms.wav` - Technical speech: "The API endpoint returns JSON data with authentication tokens."
   - `numbers_and_dates.wav` - Numbers/dates: "Meeting scheduled for January 15th at 3:30 PM."
   - `fast_speech.wav` - Fast speech: "This is a test of rapid speech recognition capabilities."
   - `quiet_speech.wav` - Quiet speech: "Testing transcription with low volume audio input."

2. **Audio file requirements**:
   - Format: WAV files (any sample rate, mono or stereo)
   - Duration: 2-5 seconds each
   - Content: Clear speech matching the expected transcription text
   - Quality: Good signal-to-noise ratio

3. **Add to test bundle**:
   - Add the WAV files to the `DictaumTests` target in Xcode
   - Ensure they're included in the test bundle resources

### Expected Transcriptions

The test harness expects these exact transcriptions:

```
short_greeting.wav → "Hello, how are you today?"
technical_terms.wav → "The API endpoint returns JSON data with authentication tokens."
numbers_and_dates.wav → "Meeting scheduled for January 15th at 3:30 PM."
fast_speech.wav → "This is a test of rapid speech recognition capabilities."
quiet_speech.wav → "Testing transcription with low volume audio input."
```

### Running Tests

```bash
# Run WER tests
xcodebuild test -project Dictaum.xcodeproj -scheme Dictaum -destination 'platform=macOS' -only-testing:DictaumTests/WERHarness

# Run parameter experiments
xcodebuild test -project Dictaum.xcodeproj -scheme Dictaum -destination 'platform=macOS' -only-testing:DictaumTests/WERHarness/testTemperatureExperiment
```

### Synthetic Audio Fallback

When real audio files are not available, the system generates synthetic audio that mimics speech patterns:

- **short_greeting.wav**: Simple sine wave with exponential decay
- **technical_terms.wav**: Complex modulation with multiple frequencies
- **numbers_and_dates.wav**: Rhythmic pattern with on/off segments
- **fast_speech.wav**: High-frequency modulation
- **quiet_speech.wav**: Low amplitude with gentle modulation

This allows the testing infrastructure to work even without real audio files, though results will be less meaningful.

## Audio Processing Tests

The `AudioProcessingTests.swift` file tests the audio processing pipeline:

- Pre-roll buffer functionality
- Fade-in processing
- High-pass filtering
- Audio level monitoring
- Complete processing pipeline

These tests use synthetic audio and don't require external files.

## Creating Test Audio

To create your own test audio files:

1. **Record using built-in tools**:
   ```bash
   # Record 5 seconds of audio
   sox -t coreaudio -d short_greeting.wav trim 0 5
   ```

2. **Convert existing audio**:
   ```bash
   # Convert to WAV format
   ffmpeg -i input.mp3 -ar 16000 -ac 1 output.wav
   ```

3. **Generate synthetic speech** (for testing purposes):
   ```bash
   # Using macOS say command
   say "Hello, how are you today?" -o short_greeting.wav
   ```

## Best Practices

- **Ground truth accuracy**: Ensure expected transcriptions exactly match what's spoken
- **Audio quality**: Use clear, noise-free recordings
- **Consistent volume**: Aim for similar audio levels across all test files
- **Diverse content**: Include different speech patterns, accents, and speaking speeds
- **Version control**: Consider storing test audio files in Git LFS for version control