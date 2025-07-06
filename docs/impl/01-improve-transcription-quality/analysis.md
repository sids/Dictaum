# Whisper Transcription Analysis and Recommendations

This document outlines the current implementation of Whisper audio transcription in the Dictaum application and provides recommendations for potential tuning and experimentation to improve accuracy, latency, and user experience.

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

### 2.1. Audio Front-end Enhancements
These tweaks to the audio input chain can often provide significant improvements with relatively low effort.
*   **Prevent Missed First Words/Syllables**:
    *   **Tactic**: Start the audio input tap 200-300ms *before* the UI indicates "recording". This pre-roll buffer can capture initial plosives or quick starts often missed.
    *   **Tactic**: Apply a fade-in to the first ~20ms of the audio (linear ramp or using `kAudioUnitParameterID_Volume`) to avoid abrupt starts.
    *   **Benefit**: Eliminates the common "first-syllable drop" issue.
*   **Reduce Background Noise**:
    *   **Tactic**: Insert an `AVAudioUnitEQ` with a high-pass filter around 80Hz to cut out low-frequency hum and rumble.
    *   **Tactic**: Experiment with Apple’s `AVAudioUnitVarispeed` (at 0 dB speed change) on Apple Silicon devices, as it can activate built-in noise suppression algorithms.
    *   **Benefit**: Cleaner audio for Whisper, potentially improving accuracy without resorting to heavier ML-based denoisers.
*   **Manage Input Level Swings**:
    *   **Tactic**: Enable Automatic Gain Control (AGC). This might involve using `AVAudioSessionModeMeasurement` and `setPreferredInputGain:`.
    *   **Benefit**: Helps maintain a more consistent audio level, keeping Whisper out of its "low energy" fallback paths which can degrade accuracy.

### 2.2. Decoding Parameters (`DecodingOptions`)
Fine-tuning these parameters can significantly impact transcription results.
*   **Temperature**:
    *   **Current**: `0.0` (greedy decoding).
    *   **Experiment**: Systematically test values like `0.1`, `0.2`, up to `0.4`. Higher temperatures can yield more natural or creative output but increase randomness and potential for hallucinations.
*   **`bestOf` Parameter**:
    *   **Concept**: When using temperature-based sampling, this generates multiple (`N`) candidate transcriptions and chooses the one with the highest overall probability.
    *   **Experiment**: Try `bestOf` values of `1` (default if not specified), `3`, then `5`, especially when `temperature` is between `0.2-0.4`.
    *   **Benefit**: Can improve Word Error Rate (WER) by 2-3 points for noisy speech by giving sampling more chances to find a good candidate.
*   **`topP` (Nucleus Sampling)**:
    *   **Concept**: An alternative to `topK` sampling that selects the smallest set of tokens whose cumulative probability exceeds a threshold `P`.
    *   **Experiment**: If `WhisperKit` exposes `topP`, try values like `0.9` or `0.95`.
    *   **Benefit**: Can be useful with low temperatures to prevent rare but correct words from being pruned, offering a different way to control randomness than `topK`.
*   **Beam Search (`beam_size`)**:
    *   **Concept**: A deterministic search algorithm that explores multiple hypotheses (beams) at each step. Generally slower than sampling but can be more accurate.
    *   **Experiment**: If `WhisperKit` supports it, try `beam_size` values of `1` (equivalent to greedy if no other sampling is on), `3`, then `5`.
    *   **Benefit**: Provides a strong accuracy baseline to compare against stochastic methods like temperature sampling with `bestOf`.
*   **Timestamps**:
    *   **Current**: `withoutTimestamps: true`.
    *   **Recommendation**: Enable timestamp generation (`withoutTimestamps: false`).
    *   **Benefit**: Essential for features like karaoke-style highlighting, aligning text with audio, more sophisticated segment stitching (e.g., paragraph breaks based on pause durations between segments), and debugging.
*   **Confidence Scores**:
    *   **Recommendation**: Explore if `WhisperKit` provides segment-level or word-level confidence scores or log probabilities.
    *   **Benefit**: Can be used for highlighting uncertain parts of the transcription, deferring actions until confidence is high, or for logging/analysis to improve the system (see Confidence-driven UX).

### 2.3. Addressing Duplicate or Hallucinated Segments
These issues can become more prominent with continuous transcription or certain audio types.
*   **Stable-Whisper Heuristic**:
    *   **Concept**: A technique to re-score candidate segments and discard those whose log-probability falls by more than a certain threshold (τ) compared to a more stable reference.
    *   **Implementation**: This may require custom logic (approx. 70 lines of Swift cited as an example) if not built into `WhisperKit`.
*   **Overlap-Merge with Content-Alignment**:
    *   **Concept**: When chunking audio (e.g., 30s chunks with 5s overlap), compare the end of the previous transcribed chunk with the beginning of the new one. Use a similarity measure (e.g., Jaccard index on token sequences) to find and trim duplicated content.
    *   **Benefit**: Particularly useful for streaming mode to ensure smooth transitions between segments.

### 2.4. Language Support
*   **User Language Selection**: For multilingual models, allow users to select the transcription language from the UI. This selection should dynamically set the `language` parameter in `DecodingOptions`.
*   **Automatic Language Detection**: Explore the feasibility of automatic language detection if `WhisperKit` supports it (e.g., by passing `nil` or an empty string for the language parameter when a multilingual model is active). This typically works best with larger models.

### 2.5. Real-time Transcription (Streaming)
*   **Implement Streaming**: Re-architect the application to support streaming transcription using `WhisperKit`'s available streaming APIs. This provides real-time (or near real-time) feedback.
    *   This involves robust audio chunking (e.g., 5-10 second chunks, or as per `WhisperKit` guidance).
    *   Manage overlapping audio chunks to maintain transcription context (aligning with Whisper's typical 30-second processing window).
    *   Update the UI progressively with transcribed segments.
    *   Handle segment finalization and updates gracefully.
*   **Benefits**: Significantly improves perceived responsiveness and user experience. Allows users to see and potentially correct mistakes sooner if an editing interface were added.
*   **Challenges**: More complex state management, careful handling of segment boundaries, and potentially higher transient resource usage.

### 2.6. Audio Processing and Segmentation (Non-Streaming Contexts)
*   **Voice Activity Detection (VAD)**: Implement VAD to offer users an option for automatic recording stop/start. This can also help in segmenting speech during long pauses if full streaming isn't implemented.
*   **Long Recording Chunking**: For non-streaming scenarios with very long recordings (e.g., > 2 minutes), consider manually chunking the audio into overlapping segments (e.g., 30 seconds with 5-10 second overlap) for sequential transcription. This can improve stability and more closely mimic Whisper's internal fixed-window processing.

### 2.7. Contextual Transcription and Prompting
Enhancing Whisper's understanding of the current context can significantly improve accuracy for specific terms or styles.
*   **`usePrefillPrompt` / `usePrefillCache`**:
    *   **Current**: Both `false`.
    *   **Recommendation**: Enable and evaluate their effectiveness, especially for streaming or sequential chunk transcription. The "prompt" would typically be recently confirmed transcribed text.
*   **Custom Vocabulary / Jargon Prompts**:
    *   **Concept**: Prepend a comma-separated list of domain-specific terms or jargon (e.g., "GraphQL, Kubernetes, Kafka, CRDTs") to the initial prompt for Whisper.
    *   **Benefit**: Increases the likelihood of these terms being transcribed correctly.
*   **Expected Casing / Punctuation Style Prompts**:
    *   **Concept**: Provide hints about the desired output style in the prompt (e.g., "US English, sentence-case, Oxford comma.").
    *   **Benefit**: Can guide Whisper towards a more consistent and preferred formatting.
*   **App-wide Persona Prompts**:
    *   **Concept**: For more specialized versions or modes, a persona prompt could be used (e.g., "You are a coding assistant; prefer monospace for code.").
    *   **Benefit**: Tailors the output more broadly to a specific use case.

### 2.8. User Experience (UX) Enhancements
Beyond raw accuracy, these can improve how users interact with and perceive transcription quality.
*   **Model Selection Guidance**: Continue providing clear guidance on model trade-offs (speed, accuracy, resource usage, language capabilities). The current UI with tags is a good start.
*   **English-Model Awareness**: Ensure users understand the benefits of English-only (`.en`) models if their primary language is English (often faster and sometimes more accurate for English than multilingual counterparts of the same size).
*   **Confidence-driven UX Polish**:
    *   **Highlight Low-Confidence Words**: If word-level confidence is available (e.g., ≤ 0.4 probability), highlight these words (e.g., in yellow) in the displayed transcription to signal potential errors and invite quick corrections.
    *   **Deferred Clipboard Write**: Delay automatically pasting to the clipboard until overall confidence for a segment is above a certain threshold, or until the user explicitly confirms (e.g., with a shortcut like ⌘↩). This avoids flashing low-quality or incomplete text.
    *   **Anonymized Logging for Active Learning**: Log tuples of (word, confidence, was_edited_by_user?) to a local SQLite database. This data can be invaluable for future fine-tuning or identifying common error patterns.

### 2.9. Hardware, Runtime, and Model Variant Hygiene
Optimizations related to the execution environment and model specifics.
*   **Metal Memory Management**:
    *   **Issue**: Core ML models, especially large ones, can consume significant Metal memory (1-2 GB on M-series Macs).
    *   **Tactic**: Consider calling `transcriber.unload()` or a similar `WhisperKit` API to release model resources after a period of inactivity (e.g., N seconds). The model would be reloaded on next use.
    *   **Trade-off**: Saves memory but introduces latency for the next transcription.
*   **Threading Strategy**:
    *   **Recommendation**: Ensure Whisper transcription runs on an appropriate background queue (e.g., `DispatchQueue.global(qos: .userInitiated)`).
    *   **Recommendation**: Keep UI updates strictly on the main queue (`.userInteractive` or `@MainActor`).
    *   **Benefit**: Prevents transcription workload from causing frame drops or unresponsiveness in the UI, especially if live updates are implemented.
*   **Domain-Specific Model Presets**:
    *   **Observation**: Some model variants might perform better for specific domains (e.g., `large-v3-Turbo` is fast but noted as slightly worse on medical terms than `large-v3`).
    *   **Recommendation**: If catering to specific professional users (e.g., healthcare, legal), offer a "domain preset" in settings that forces the selection of a model known to perform better for that domain's vocabulary, even if it's slightly slower or larger.

### 2.10. Robustness and Error Handling
*   **Enhanced Error Handling**: Improve error handling, especially for streaming (e.g., individual chunk processing failures) and for problematic audio inputs (e.g., excessive noise, silence).
*   **Feedback for Difficult Audio**: Provide user feedback when parts of the audio are difficult to transcribe, if such information can be derived from the transcription process (e.g., low confidence scores).

### 2.11. Future Considerations
Longer-term ideas to keep on the radar.
*   **Word-Level Timestamps for Advanced Features**: Beyond basic alignment, word-level timestamps (if accurate and accessible from `WhisperKit`) can enable:
    *   Karaoke-style highlighting of text as audio plays (if playback is added).
    *   Automatic punctuation insertion based on pause durations between words.
*   **Speaker Change Detection**:
    *   **Concept**: Even without full speaker diarization (which is complex), simple heuristics based on changes in audio energy and pitch could detect likely speaker changes.
    *   **Benefit**: Could allow for basic labeling like "User:" vs "System:" or "Speaker 1:" vs "Speaker 2:", useful for transcribing conversations or interactions with voice assistants.

### Prioritization Approach (Suggested by External Agent)
1.  **Quick Wins**: Focus on audio front-end tweaks (Section 2.1) and initial decoder parameter sweeps (Section 2.2 like temperature, `bestOf`). These are often low-effort with high payoff.
2.  **Duplication Fixes**: Address duplicate/hallucinated segments (Section 2.3), as this is critical for reliable transcription, especially if moving to streaming.
3.  **Prompt Enhancements & Confidence UX**: Work on advanced prompting (Section 2.7) and confidence-driven UX (Section 2.8) to differentiate Dictaum.
4.  **Hardware & Future Work**: Address hardware/runtime hygiene (Section 2.9) and longer-term future considerations (Section 2.11) as schedule permits. Streaming (Section 2.5) is a larger architectural change that would also fall into a major feature development cycle.

By systematically experimenting with these areas, it should be possible to further optimize the transcription quality and overall performance of Dictaum.
