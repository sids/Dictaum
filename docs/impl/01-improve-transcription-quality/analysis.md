# Whisper Transcription Analysis and Recommendations

This document outlines the current implementation of Whisper audio transcription in the Dictaum application and provides recommendations for potential tuning and experimentation to improve accuracy and user experience.

## 1. Current Implementation Details (Baseline)

This section summarizes the key aspects of the Dictaum application's transcription functionality as of the last review.

### 1.1. Audio Pipeline (`MicRecorder.swift`)
*   **Audio Source**: Utilizes `AVAudioEngine` and `AVAudioInputNode`.
*   **Buffering**: Captures audio via an input tap with a `bufferSize` of 1024 frames.
*   **Format Conversion**: Converts raw audio to **16kHz, mono, 32-bit float PCM** using `AVAudioConverter`. This is the format required by Whisper.
*   **Data Accumulation**: Accumulates all audio samples for a single dictation session into a single `[Float]` array (`recordingBuffer`).
*   **VAD**: No Voice Activity Detection is implemented; recording starts and stops based purely on user input (shortcut keys).
*   **Transcription Unit**: The entire recorded audio segment is passed to the transcription engine at once after the recording stops. No intermediate chunking for transcription is performed during the recording.

### 1.2. Transcription Engine (`Transcriber.swift` using `WhisperKit`)
*   **Model Loading**: `WhisperKit` is initialized either from a local `modelFolder` (if downloaded) or by model name. Key initialization parameters for `WhisperKit`:
    *   `verbose: true`
    *   `logLevel: .debug`
    *   `prewarm: true` (attempts to load the model into memory for faster access)
    *   `load: true` (loads model data immediately)
    *   `download: false` (as `ModelManager` handles downloads separately)
*   **Core Decoding Options** (`DecodingOptions`):
    *   `task: .transcribe` (for speech-to-text in the source language).
    *   `language: "english"` (Hardcoded to English. Multilingual models are available but this setting restricts them).
    *   `temperature: 0.0` (Greedy decoding - selects the most probable token at each step).
    *   `temperatureIncrementOnFallback: 0.2`
    *   `temperatureFallbackCount: 3` (Allows temperature to increase if Whisper detects issues like high compression ratio or low average log probability).
    *   `topK: 5` (When temperature is > 0, sampling is restricted to the top K most probable tokens. With `temperature: 0.0`, this has minimal effect).
    *   `usePrefillPrompt: false` (Does not use previous transcriptions as prompts for the current one).
    *   `usePrefillCache: false` (Does not cache activations from previous transcriptions).
    *   `skipSpecialTokens: true` (Removes special tokens like `<|startoftranscript|>` from the output).
    *   `withoutTimestamps: true` (Does not request word or segment timestamps).
*   **Segment Stitching**: Text from all segments is joined together with a single space and then trimmed.

### 1.3. Workflow (`DictationController.swift`)
*   The application follows a "record-then-transcribe" model:
    1. User manually starts recording.
    2. `MicRecorder` captures, converts, and accumulates audio.
    3. User manually stops recording.
    4. The entire audio buffer is passed to `Transcriber.swift`.
    5. `Transcriber.swift` uses `WhisperKit` to transcribe the buffer.
    6. The resulting text is pasted.
*   **No streaming transcription**: The user does not see transcribed text in real-time.

### 1.4. Model Management (`ModelManager.swift`)
*   Manages a list of available Whisper models (Tiny, Base, Small, Large v3, Large v3 Turbo - with English-only and multilingual variants).
*   Handles downloading models via `WhisperKit`.
*   "Warms up" models post-download by transcribing a short, generated audio snippet.

## 2. Recommendations for Experimentation and Tuning

The following areas could be explored to potentially enhance transcription accuracy, performance, and user experience.

### 2.1. Decoding Parameters (`DecodingOptions`)
*   **Temperature**: Experiment with `temperature` values (e.g., `0.1` to `0.4`) to assess impact on transcription quality. Currently `0.0` (greedy).
*   **Beam Search**: Investigate if `WhisperKit` supports beam search (e.g., `beam_size` parameter). Evaluate for accuracy improvements versus performance cost.
*   **Timestamps**: Enable timestamp generation (`withoutTimestamps: false`). These can be useful for advanced segment stitching (e.g., paragraph breaks based on pauses) or future features like audio-text alignment.
*   **Confidence Scores**: Explore using segment-level confidence scores or log probabilities from `WhisperKit`, if available, for indicating transcription certainty or for debugging.

### 2.2. Language Support
*   **User Language Selection**: For multilingual models, allow users to select the transcription language.
*   **Automatic Language Detection**: Explore feasibility of automatic language detection if `WhisperKit` supports it.

### 2.3. Real-time Transcription (Streaming)
*   **Implement Streaming**: Re-architect to support streaming transcription for real-time user feedback using `WhisperKit`'s streaming capabilities.
    *   This involves robust audio chunking (e.g., 5-10 second chunks or as per `WhisperKit` guidance).
    *   Manage overlapping audio chunks to maintain context (aligning with Whisper's 30-second window).
    *   Update UI progressively with transcribed segments.
    *   Handle segment finalization and updates.
*   **Benefits**: Improved perceived responsiveness, potential for quicker corrections.
*   **Challenges**: More complex state management, potential for higher transient resource usage.

### 2.4. Audio Processing and Segmentation
*   **Voice Activity Detection (VAD)**: Implement VAD for automatic recording stop/start or to segment speech during long pauses.
*   **Long Recording Chunking**: For non-streaming, very long recordings (e.g., > 2 minutes), consider manual chunking into overlapping segments (e.g., 30 seconds with 5-10 second overlap) for sequential transcription.

### 2.5. Contextual Transcription
*   **Prompting**: Enable and evaluate prompt-based contextualization (`usePrefillPrompt: true`, `usePrefillCache: true`).
    *   The prompt would typically be recently confirmed transcribed text. This is most relevant for streaming or sequential chunk transcription.

### 2.6. User Experience and Guidance
*   **Model Selection Guidance**: Continue to provide clear guidance on model trade-offs (speed, accuracy, resources, language capabilities).
*   **English-Model Awareness**: Ensure users understand benefits of `.en` models for English.

### 2.7. Robustness and Error Handling
*   **Enhanced Error Handling**: Improve error handling, especially for streaming (e.g., individual chunk failures) and problematic audio (e.g., noise, silence).
*   **Feedback for Difficult Audio**: Provide user feedback if parts of audio are hard to transcribe (e.g., using confidence scores).

By systematically experimenting with these areas, it should be possible to further optimize the transcription quality and overall performance of Dictaum.
