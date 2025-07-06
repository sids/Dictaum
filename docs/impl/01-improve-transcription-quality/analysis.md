# Whisper Transcription Analysis and Recommendations

This document outlines the current implementation of Whisper audio transcription in the Dictaum application and provides recommendations for potential tuning and experimentation to improve accuracy, latency, and user experience.

## 1. Current Implementation Details (Baseline)

This section summarizes the key aspects of the Dictaum application's transcription functionality as of the last review.

### 1.1. Audio Pipeline (`MicRecorder.swift`)
*   **Audio Source**: Utilizes `AVAudioEngine` and `AVAudioInputNode`.
*   **Buffering**: Captures audio via an input tap with a `bufferSize` of 1024 frames.
*   **Format Conversion**: Converts raw audio to **16kHz, mono, 32-bit float PCM** using `AVAudioConverter`. This is the format required by Whisper.
*   **Data Accumulation**: Accumulates all audio samples for a single dictation session into a single `[Float]` array (`recordingBuffer`).
*   **VAD (Voice Activity Detection)**: No VAD is currently implemented; recording starts and stops based purely on user input.
*   **Transcription Unit**: The entire recorded audio segment is passed to the transcription engine at once after the recording stops.

### 1.2. Transcription Engine (`Transcriber.swift` using `WhisperKit`)
*   **Model Loading**: `WhisperKit` is initialized either from a local `modelFolder` or by model name. Key parameters: `verbose: true`, `logLevel: .debug`, `prewarm: true`, `load: true`, `download: false`.
*   **Core Decoding Options** (`DecodingOptions`):
    *   `task: .transcribe`
    *   `language: "english"` (Hardcoded)
    *   `temperature: 0.0` (Greedy decoding)
    *   `temperatureIncrementOnFallback: 0.2`
    *   `temperatureFallbackCount: 3`
    *   `topK: 5`
    *   `usePrefillPrompt: false`
    *   `usePrefillCache: false`
    *   `skipSpecialTokens: true`
    *   `withoutTimestamps: true`
*   **Segment Stitching**: Text from all segments is joined with a single space and trimmed.

### 1.3. Workflow (`DictationController.swift`)
*   Follows a "record-then-transcribe" model.
*   **No streaming transcription**: User does not see real-time transcribed text.

### 1.4. Model Management (`ModelManager.swift`)
*   Manages a list of available Whisper models.
*   Handles model downloads and "warms up" models post-download.

## 2. Recommendations for Experimentation and Tuning

The following areas could be explored to potentially enhance transcription accuracy, performance, and user experience.

### 2.1. Audio Front-end Enhancements
Low-effort, high-payoff tweaks to the audio input chain.
*   **Prevent Missed First Words/Syllables**:
    *   **Tactic**: Start the audio input tap 200-300ms *before* UI indicates "recording".
    *   **Tactic**: Apply a fade-in to the first ~20ms of audio.
    *   **Benefit**: Eliminates the common "first-syllable drop".
*   **Reduce Background Noise**:
    *   **Tactic**: Insert an `AVAudioUnitEQ` with a high-pass filter (~80Hz).
    *   **Tactic**: Experiment with `AVAudioUnitVarispeed` (at 0 dB speed change) on Apple Silicon. Note: Apple’s echo/noise cancellation engages only under `AVAudioSessionModeVoiceChat` or `VideoChat`; testing should use these modes for consistency.
    *   **Benefit**: Cleaner audio for Whisper, improving accuracy.
*   **Manage Input Level Swings**:
    *   **Tactic**: Enable **AGC (Automatic Gain Control)**. On macOS, use `AudioDeviceSetProperty(kAudioDevicePropertyVolumeScalar, …)`. (`setPreferredInputGain:` is iOS-only).
    *   **Benefit**: Maintains consistent audio levels, keeping Whisper out of low-energy fallback paths.
*   **Measurement**:
    *   **Recommendation**: Log peak/RMS audio levels before and after AGC & EQ adjustments. Target ≈ −12 dBFS ± 3 dB to provide a concrete success criterion.

### 2.2. Decoding Parameters (`DecodingOptions`)
Fine-tuning these parameters significantly impacts transcription.
*   **Temperature**:
    *   **Current**: `0.0` (greedy).
    *   **Experiment**: Systematically test `0.1`–`0.4`.
    *   **Benefit**: Higher values can yield more natural output but increase randomness.
*   **Dynamic Temperature Fallback**:
    *   **Concept**: Instead of a fixed `temperatureFallbackCount = 3`, adjust based on audio duration, e.g., `ceil(chunkDuration / 30s)`.
    *   **Benefit**: Keeps short dictations snappy (fewer fallbacks) while giving longer recordings more chances to recover from low-confidence segments.
*   **`bestOf` Parameter**:
    *   **Concept**: Generates `N` candidates and chooses the best. `WhisperKit` currently exposes `bestOf` and `beam_size` as mutually exclusive.
    *   **Experiment**: Try `1`→`3`→`5` (with `temperature = 0.2–0.4`).
    *   **Benefit**: Can improve **WER (Word Error Rate)** by 2-3 points for noisy speech.
*   **`topP` (Nucleus Sampling)**:
    *   **Experiment**: If exposed, try `0.9`→`0.95`.
    *   **Benefit**: Useful with low temperatures to prevent rare words from being pruned.
*   **Beam Search (`beam_size`)**:
    *   **Concept**: Deterministic, improves accuracy but slower. Mutually exclusive with `bestOf` in current `WhisperKit`.
    *   **Experiment**: Try `1`→`3`→`5`.
    *   **Benefit**: Strong accuracy baseline for A/B testing against `bestOf`.
*   **Timestamps**:
    *   **Recommendation**: Enable timestamp generation (`withoutTimestamps: false`).
    *   **Benefit**: Essential for advanced segment stitching, potential audio-text alignment, debugging, and features like karaoke-style highlighting.
*   **Confidence Scores**:
    *   **Recommendation**: Explore segment/word-level confidence scores or log probabilities from `WhisperKit`.
    *   **Benefit**: Useful for highlighting uncertain text, deferring actions, or logging for active learning.
*   **Measurement**:
    *   **Recommendation**: Implement a WER harness: a test suite with 10-15 representative WAV files and their ground truth transcripts. Xcode unit tests should run transcriptions with different parameter sweeps, printing WER and median latency for each. This prevents subjective "sounds better" assessments and allows graphing of gains.

### 2.3. Addressing Duplicate or Hallucinated Segments
Crucial for transcription reliability, especially in continuous or streaming modes.
*   **Stable-Whisper Heuristic**:
    *   **Concept**: Re-score candidate segments; drop those whose log-probability falls significantly (by > τ) compared to a stable reference.
    *   **Implementation**: May require custom logic if not native to `WhisperKit`.
*   **Overlap-Merge with Content-Alignment (for chunked/streaming audio)**:
    *   **Concept**: For chunked audio (e.g., 30s chunks + 5s overlap), compare the end of the previous transcribed segment with the beginning of the new one. Use Jaccard matching on **decoded words or token IDs** (not raw bytes, as Whisper emits sub-word tokens) to find and trim duplicates.
    *   **Benefit**: Ensures smooth, non-repetitive transitions between segments.

### 2.4. Language Support
*   **User Language Selection**: For multilingual models, allow UI selection of transcription language, dynamically setting `DecodingOptions.language`.
*   **Automatic Language Detection**: Explore feasibility if `WhisperKit` supports it for multilingual models.

### 2.5. Real-time Transcription (Streaming)
This is a significant architectural change for improved UX.
*   **Implement Streaming**: Re-architect to support streaming using `WhisperKit`'s APIs.
    *   **Audio Chunking**: Implement robust chunking (e.g., 5-10s, or per `WhisperKit` guidance).
    *   **Context Management**: Manage overlapping chunks (see 2.3 for merge strategies).
    *   **UI Updates**: Display transcribed segments progressively.
    *   **Segment Finalization**: Handle segment updates gracefully.
*   **Benefit**: Improves perceived responsiveness; allows quicker corrections.
*   **Challenges**: Complex state management; higher transient resource usage.

### 2.6. Audio Processing and Segmentation (Offline Contexts)
For non-streaming modes or pre-processing.
*   **VAD (Voice Activity Detection)**: Implement VAD for automatic recording stop/start or to segment speech during long pauses.
*   **Long Recording Chunking**: For very long non-streaming recordings (>2 min), consider manual, overlapping chunking (e.g., 30s + 5-10s overlap) for sequential transcription.
    *   **Benefit**: Can improve stability by mimicking Whisper's internal processing.

### 2.7. Contextual Transcription and Prompting
Guide Whisper for better accuracy with specific terms or styles.
*   **`usePrefillPrompt` / `usePrefillCache`**:
    *   **Recommendation**: Enable and evaluate, especially for streaming/sequential chunking, using recent text as prompt.
*   **Hot-word Biasing**:
    *   **Concept**: Prepend a short list of important terms (e.g., `[GraphQL], [Dictaum]`) to the `initial_prompt` once per chunk.
    *   **Benefit**: Tilts the log-probability distribution towards these proper nouns or key terms.
*   **Custom Vocabulary / Jargon Prompts**:
    *   **Concept**: Prepend a comma-separated glossary (e.g., "GraphQL, Kubernetes, Kafka") to the initial prompt.
    *   **Benefit**: Increases likelihood of correct transcription for these terms.
*   **Expected Casing / Punctuation Style Prompts**:
    *   **Concept**: Provide style hints in the prompt (e.g., "US English, sentence-case, Oxford comma.").
    *   **Benefit**: Guides Whisper towards preferred formatting.
*   **App-wide Persona Prompts**:
    *   **Concept**: For specialized modes, use a persona prompt (e.g., "You are a coding assistant; prefer monospace for code.").
    *   **Benefit**: Broadly tailors output to a use case.

### 2.8. User Experience (UX) Enhancements
Improve interaction with and perception of transcription quality.
*   **Model Selection Guidance**: Continue clear guidance on model trade-offs.
*   **English-Model Awareness**: Ensure users understand benefits of `.en` models for English.
*   **Confidence-driven UX Polish**:
    *   **Highlight Low-Confidence**: If word-level confidence (e.g., ≤ 0.4) is available, highlight these words.
        *   **Benefit**: Signals potential errors for quick correction.
    *   **Deferred Clipboard Write**: Delay auto-pasting until confidence > threshold or user confirms (e.g., ⌘↩).
        *   **Benefit**: Avoids flashing low-quality/incomplete text.
    *   **Anonymized Logging for Active Learning**: Log (word, confidence, was_edited?) locally.
        *   **Benefit**: Data for future fine-tuning or error pattern identification.
    *   **Measurement**:
        *   **Recommendation**: A/B log the "clipboard write delay" feature against user correction rates to prove that confidence gating reduces edits.

### 2.9. Hardware, Runtime, and Model Variant Hygiene
Optimizations for the execution environment.
*   **Metal Memory Management**:
    *   **Tactic**: Consider `transcriber.unload()` after N seconds of inactivity to free Metal memory (1-2GB on M-series). Reload on next use.
    *   **Benefit**: Saves memory. Trade-off: latency for next transcription.
*   **Threading Strategy**:
    *   **Recommendation**: Ensure Whisper runs on background queue (e.g., `qos: .userInitiated`), UI on main queue.
    *   **Benefit**: Prevents UI frame drops.
*   **Domain-Specific Model Presets**:
    *   **Recommendation**: Offer "domain presets" (e.g., healthcare, legal) that force specific models (e.g., `large-v3` for medical terms over `large-v3-Turbo`).
    *   **Benefit**: Better accuracy for specialized vocabularies.

### 2.10. Robustness and Error Handling
*   **Enhanced Error Handling**: Improve for streaming (chunk failures) and problematic audio.
*   **Feedback for Difficult Audio**: Provide user feedback if parts are hard to transcribe (e.g., via low confidence).

### 2.11. Future Considerations & Roadmap Flags
Longer-term ideas.
*   **Word-Level Timestamps for Advanced Features (Existing)**:
    *   **Benefit**: Enable karaoke-style highlighting, auto-punctuation.
*   **Speaker Change Detection (Existing)**:
    *   **Benefit**: Basic labeling ("User:" vs "System:") from energy/pitch heuristics.
*   **On-device LoRA Fine-tuning (3-6 mo horizon)**:
    *   **Concept**: Fine-tune models on user corrections directly on-device using Low-Rank Adaptation (LoRA).
    *   **Benefit**: Keeps user data private; feasible within a few hours on Apple Silicon.
*   **NPU Offload (6-12 mo horizon)**:
    *   **Concept**: Utilize Apple Neural Engine (ANE) directly once Core ML exposes "ANE-only" execution more robustly.
    *   **Benefit**: Could reduce laptop power draw by ~30%.
*   **Model License Checks & Notarization (Per-release)**:
    *   **Recommendation**: Stay updated on Apple's ML model notarization requirements. Ensure Whisper weights used are App Store-compliant.
    *   **Benefit**: Compliance and smoother App Store reviews.

### Prioritization Approach (Suggested by External Agent)
1.  **Quick Wins**: Audio front-end (2.1), initial decoder parameters (2.2).
2.  **Duplication Fixes**: Address segment duplication/hallucinations (2.3).
3.  **Differentiators**: Prompt enhancements (2.7), confidence UX (2.8).
4.  **Major Features/Longer Term**: Streaming (2.5), Hardware/Runtime (2.9), Future Considerations (2.11).


By systematically experimenting, Dictaum's transcription quality and performance can be provably optimized.

---
## Glossary
*   **AGC**: Automatic Gain Control. A process that automatically adjusts audio input volume to maintain a consistent level.
*   **VAD**: Voice Activity Detection. A technology used to detect the presence or absence of human speech.
*   **WER**: Word Error Rate. A common metric for measuring the accuracy of a speech recognition system; lower is better.
*   **RMS**: Root Mean Square. A statistical measure of the magnitude of a varying quantity, often used for audio signal loudness.
*   **dBFS**: Decibels Full Scale. A unit of measurement for amplitude levels in digital audio systems. 0 dBFS is the maximum possible digital level.
*   **LoRA**: Low-Rank Adaptation. A technique for efficiently fine-tuning large pre-trained models.
*   **NPU**: Neural Processing Unit. A specialized processor for AI/ML computations, like Apple's Neural Engine (ANE).
---
