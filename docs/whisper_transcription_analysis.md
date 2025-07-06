# Whisper Transcription Analysis and Recommendations

This document outlines the current implementation of Whisper audio transcription in the Dictaum application and provides recommendations for potential tuning and experimentation to improve accuracy and user experience.

## Current Implementation Details

The application utilizes `WhisperKit` for local speech-to-text transcription. The core components involved are `Transcriber.swift`, `MicRecorder.swift`, `DictationController.swift`, and `ModelManager.swift`.

### 1. Audio Capture and Preprocessing (`MicRecorder.swift`)

*   **Audio Source**: `AVAudioEngine` with `AVAudioInputNode`.
*   **Buffering**: Audio is captured via an input tap with a `bufferSize` of 1024 frames.
*   **Format Conversion**: Raw audio from the tap is converted to **16kHz, mono, 32-bit float PCM** format using `AVAudioConverter`. This is the format required by Whisper.
*   **Recording Accumulation**: All converted audio samples for a single dictation session are accumulated into a single `[Float]` array (`recordingBuffer`).
*   **No VAD**: Recording starts and stops based purely on user input (shortcut keys). No voice activity detection is currently implemented.
*   **Full-Buffer Transcription**: The entire recorded audio segment is passed to the transcription engine at once after the recording stops. No intermediate chunking for transcription is performed during the recording.

### 2. WhisperKit Configuration (`Transcriber.swift`)

*   **Model Loading**:
    *   `WhisperKit` is initialized either from a local `modelFolder` (if downloaded) or by model name (delegating potential download to `ModelManager` initially, but `Transcriber` itself sets `download: false` in its direct `WhisperKit` init).
    *   Key initialization parameters for `WhisperKit`:
        *   `verbose: true`
        *   `logLevel: .debug`
        *   `prewarm: true` (attempts to load the model into memory for faster access)
        *   `load: true` (loads model data immediately)
        *   `download: false`
*   **Transcription Parameters (`DecodingOptions`)**:
    *   `task: .transcribe` (for speech-to-text in the source language).
    *   `language: "english"` (Hardcoded to English. Multilingual models are available but this setting restricts them).
    *   `temperature: 0.0` (Greedy decoding - selects the most probable token at each step).
    *   `temperatureIncrementOnFallback: 0.2`
    *   `temperatureFallbackCount: 3` (Allows temperature to increase if Whisper detects issues like high compression ratio or low average log probability, potentially improving transcription of repetitive or unclear audio).
    *   `topK: 5` (When temperature is > 0, sampling is restricted to the top K most probable tokens. With `temperature: 0.0`, this has minimal effect as the single most probable token is chosen).
    *   `usePrefillPrompt: false` (Does not use previous transcriptions as prompts for the current one).
    *   `usePrefillCache: false` (Does not cache activations from previous transcriptions to speed up current one).
    *   `skipSpecialTokens: true` (Removes special tokens like `<|startoftranscript|>` from the output).
    *   `withoutTimestamps: true` (Does not request word or segment timestamps).
    *   `clipTimestamps: []` (Not applicable as timestamps are not requested).

### 3. Segment Stitching (`Transcriber.swift`)

*   The `transcribe` function in `WhisperKit` returns segments.
*   These segments' text components are joined together with a single space:
    `results.flatMap { $0.segments.map { $0.text } }.joined(separator: " ")`.
*   The final string is then trimmed of leading/trailing whitespaces and newlines.

### 4. Overall Workflow (`DictationController.swift`)

1.  User starts recording.
2.  `MicRecorder` captures, converts, and accumulates audio into a single buffer.
3.  User stops recording.
4.  The entire audio buffer is passed to `Transcriber.swift`.
5.  `Transcriber.swift` uses `WhisperKit` with the aforementioned `DecodingOptions` to transcribe the entire buffer.
6.  The resulting text is pasted into the active application.
7.  **No streaming transcription**: The user does not see transcribed text in real-time. Transcription only occurs after the recording is complete.

### 5. Model Management (`ModelManager.swift`)

*   Manages a list of available Whisper models (Tiny, Base, Small, Large v3, Large v3 Turbo - with English-only and multilingual variants).
*   Handles downloading models via `WhisperKit`.
*   "Warms up" models post-download by transcribing a short, generated audio snippet. This helps ensure the Core ML model is compiled and ready for use.

## Recommendations for Experimentation and Tuning

The following areas could be explored to potentially enhance transcription accuracy, performance, and user experience.

### 1. Streaming Transcription

*   **Concept**: Instead of transcribing the entire audio at the end, process audio in chunks as it arrives. This can provide real-time (or near real-time) feedback to the user.
*   **WhisperKit Support**: `WhisperKit` appears to support streaming transcription. This would be a significant architectural change.
*   **Implementation Ideas**:
    *   Feed audio chunks (e.g., 5-10 seconds) to `WhisperKit`'s streaming API.
    *   Manage overlapping chunks to ensure context is maintained (Whisper typically processes 30-second windows).
    *   Update the UI progressively with transcribed segments.
*   **Benefits**:
    *   Improved perceived responsiveness.
    *   Allows users to see and correct mistakes sooner if an editing interface were added.
*   **Challenges**:
    *   More complex state management.
    *   Handling segment finalization and updates.
    *   Potentially higher transient resource usage.

### 2. Decoding Parameters (`DecodingOptions`)

*   **Temperature**:
    *   **Current**: `0.0` (greedy).
    *   **Experiment**: Try slightly higher temperatures (e.g., `0.1`, `0.2`, up to `0.4`). This can sometimes produce more natural-sounding or accurate transcriptions for less clear speech, but increases the risk of hallucinations or less predictable output.
    *   **Note**: If temperature is increased, `topK` (or `topP`/nucleus sampling if available and preferred) becomes more influential.
*   **Beam Search**:
    *   **WhisperKit Support**: Check if `WhisperKit` exposes options for beam search (`beam_size` parameter in OpenAI Whisper).
    *   **Concept**: Instead of just picking the single best next token (greedy) or sampling, beam search keeps track of several hypotheses (beams) and explores them. It can lead to higher accuracy at the cost of speed.
    *   **Experiment**: If available, try `beam_size: 5`.
*   **Language Configuration**:
    *   **Current**: Hardcoded to `"english"`.
    *   **Experiment**:
        *   Allow users to select a language if a multilingual model is chosen.
        *   Explore language auto-detection if `WhisperKit` supports it (pass `nil` or an empty string for language in some Whisper implementations). This works best with larger, multilingual models.
*   **Timestamps**:
    *   **Current**: `withoutTimestamps: true`.
    *   **Experiment**: Set to `false`. While not directly used for pasting plain text, timestamps can be invaluable for:
        *   Aligning text with audio if an editor or playback feature is ever considered.
        *   More sophisticated segment stitching (e.g., inserting paragraph breaks based on longer pauses between segments).
        *   Debugging transcription issues.

### 3. Audio Chunking and VAD (especially for non-streaming)

*   Even if full streaming isn't implemented, the definition of a "complete" audio segment could be refined.
*   **Voice Activity Detection (VAD)**:
    *   **Concept**: Implement VAD to automatically detect the end of speech.
    *   **Benefit**: Could allow for more natural stopping of recordings, or automatically segment longer dictations into logical chunks for sequential transcription if the user pauses for a significant duration.
    *   **Implementation**: Use a simple energy-based VAD or a more sophisticated library.
*   **Maximum Segment Duration**:
    *   If users record very long sessions, feeding extremely long audio files (e.g., many minutes) to Whisper at once might not be optimal. Whisper processes audio in 30-second windows internally.
    *   **Experiment**: For very long recordings (e.g., > 2 minutes), consider manually chunking the audio into overlapping segments (e.g., 30 seconds with 5-10 second overlap) and transcribing them sequentially, then stitching the results. This mimics Whisper's internal processing more explicitly and might offer more control.

### 4. Segment Stitching and Post-processing

*   **Current**: Simple text join with a space.
*   **Experiment**:
    *   If timestamps are enabled, analyze pauses between segments. Longer pauses might indicate paragraph breaks.
    *   WhisperKit might provide segment-level confidence scores. These could be used to highlight uncertain parts or for alternative transcriptions if available.
    *   Explore more advanced text normalization or formatting rules based on application needs.

### 5. Prompting / Contextualization

*   **Current**: `usePrefillPrompt: false`, `usePrefillCache: false`.
*   **Scenario**: If the app were to handle longer, continuous dictation where the user might pause and resume, or for transcribing a sequence of related audio chunks.
*   **Experiment**:
    *   Enable `usePrefillPrompt: true` and `usePrefillCache: true`.
    *   The "prompt" would be the transcription of the previous segment. This can help Whisper maintain context, improve accuracy for jargon or specific names mentioned earlier, and ensure consistent formatting.
    *   This is most relevant for streaming or sequential chunk-based transcription.

### 6. Model Selection and Guidance

*   **Current**: Provides a good range of models.
*   **Consideration**:
    *   Offer more explicit guidance to users on model trade-offs (speed vs. accuracy vs. resource usage). The current UI already does this well with tags like "Fastest", "Balanced".
    *   For English-only users, ensure they understand that English-only models (`.en`) are often faster and sometimes more accurate for English than their multilingual counterparts of the same size.

### 7. Error Handling and Resilience

*   **Current**: Handles model loading errors and transcription errors.
*   **Consideration**:
    *   If streaming is implemented, ensure robust error handling for individual chunk processing.
    *   Provide clearer feedback to the user if a specific part of the audio is problematic (e.g., too noisy, silent). This might be possible if segment-level confidence or log probabilities are accessible.

By systematically experimenting with these areas, it should be possible to further optimize the transcription quality and overall performance of Dictaum. It's recommended to start with changes that have the highest potential impact on the current usage model, such as tuning `DecodingOptions` and then considering larger architectural changes like streaming if real-time feedback is a priority.
