# Requirements for Improving Transcription Quality

This document outlines the requirements for enhancing the audio transcription capabilities of the Dictaum application. Enhancements should generally follow a prioritization that addresses quick wins and critical fixes first, then differentiators, then longer-term items. All experiments should be rigorously measured.

## 1. Functional Requirements for Enhancement

These requirements aim to improve transcription accuracy, performance, and user experience.

### 1.1. Audio Front-end Processing
*   **REQ-AUD-001**: The system **shall** implement Voice Activity Detection (VAD) to offer users an option for automatic recording stop/start or to assist in segmenting speech during long pauses.
*   **REQ-AUD-002**: For non-streaming, very long recordings (e.g., exceeding 2 minutes), the system **should** investigate manual chunking into overlapping segments (e.g., 30 seconds with 5-10 second overlap) for sequential transcription.
*   **REQ-AUD-003**: To prevent missed initial words or syllables, the system **shall** implement a pre-roll audio buffer (e.g., start audio tap 200-300ms before UI indicates recording) and **should** apply an audio fade-in (e.g., first 20ms) to the beginning of recordings.
*   **REQ-AUD-004**: The system **shall** provide mechanisms for background noise reduction, such as implementing a high-pass filter (e.g., `AVAudioUnitEQ` at ~80Hz). It **should** also evaluate using `AVAudioUnitVarispeed` on Apple Silicon for its built-in noise suppression (noting that this may require specific `AVAudioSessionMode` like `VoiceChat` or `VideoChat` for activation).
*   **REQ-AUD-005**: The system **shall** investigate and implement Automatic Gain Control (AGC) to maintain consistent audio input levels, using appropriate macOS APIs (e.g., `AudioDeviceSetProperty(kAudioDevicePropertyVolumeScalar, …)`).
*   **REQ-AUD-006**: The system **shall** log peak/RMS audio levels before and after AGC and EQ processing to verify effectiveness, targeting approximately -12 dBFS ± 3 dB.

### 1.2. Core Transcription Accuracy and Decoding Parameters
*   **REQ-ACC-001**: The system **shall** allow experimentation with different `temperature` values (e.g., 0.1 to 0.4) in `DecodingOptions`. The optimal setting should be configurable or dynamically chosen if feasible.
*   **REQ-ACC-002**: The system **shall** be investigated for compatibility with beam search (e.g., `beam_size` parameter, suggested sweep `1`→`3`→`5`). It **shall** be evaluated for accuracy improvements versus performance cost. (Note: Currently considered mutually exclusive with `bestOf` in WhisperKit).
*   **REQ-ACC-003**: The system **shall** enable timestamp generation during transcription (e.g., set `withoutTimestamps: false`).
*   **REQ-ACC-004**: Generated timestamps **should** be evaluated for use in advanced segment stitching, potential future features like audio-text alignment, and advanced word-level timestamp usage (see REQ-FTR-001).
*   **REQ-ACC-005**: The system **should** investigate the utility of segment-level or word-level confidence scores or log probabilities from `WhisperKit` for indicating transcription certainty, debugging, or driving UX features (see REQ-UX-003).
*   **REQ-ACC-006**: The system **shall** investigate and allow experimentation with the `bestOf` parameter (e.g., suggested sweep `1`→`3`→`5` with `temperature = 0.2–0.4`) in `DecodingOptions`. (Note: Currently considered mutually exclusive with `beam_size` in WhisperKit).
*   **REQ-ACC-007**: If exposed by `WhisperKit`, the system **should** investigate and allow experimentation with `topP` (nucleus sampling) (e.g., suggested sweep `0.9`→`0.95`).
*   **REQ-ACC-008**: The system **should** investigate implementing dynamic temperature fallback logic, where `temperatureFallbackCount` is adjusted based on chunk duration (e.g., `ceil(chunkDuration / 30s)`).
*   **REQ-ACC-009**: A Word Error Rate (WER) test harness **shall** be developed, including a representative set of audio samples (e.g., 10-15 WAVs) and ground truth transcripts, to objectively measure the impact of decoding parameter changes on accuracy and latency.

### 1.3. Duplicate and Hallucination Mitigation
*   **REQ-FIX-001**: The system **should** investigate and implement heuristics like the "Stable-Whisper heuristic" to reduce hallucinations or unwanted repetitions.
*   **REQ-FIX-002**: For chunked or streaming transcription, the system **shall** implement content-aware overlap merging, performing matching on decoded words or token IDs (not raw bytes), to prevent duplicated content at segment boundaries.

### 1.4. Language Support
*   **REQ-LANG-001**: For multilingual Whisper models, the system **shall** provide a mechanism for users to select the desired transcription language, dynamically setting `DecodingOptions.language`.
*   **REQ-LANG-002**: The system **should** explore automatic language detection if supported by `WhisperKit` when a multilingual model is active.

### 1.5. Real-time Transcription (Streaming)
*   **REQ-STR-001**: The system **shall** be evaluated for re-architecture to support streaming transcription.
*   **REQ-STR-002**: If streaming is implemented, the system **shall** implement robust audio chunking.
*   **REQ-STR-003**: If streaming is implemented, the system **shall** manage overlapping audio chunks appropriately (see REQ-FIX-002).
*   **REQ-STR-004**: If streaming is implemented, the UI **shall** be updated for progressive display.
*   **REQ-STR-005**: If streaming is implemented, the system **shall** manage segment finalization and updates.

### 1.6. Contextual Transcription and Prompting
*   **REQ-CTX-001**: The system **shall** enable and evaluate basic prompt-based contextualization (`usePrefillPrompt: true`, `usePrefillCache: true`).
*   **REQ-CTX-002**: The system **shall** allow users to provide custom vocabulary lists/jargon as part of the initial prompt.
*   **REQ-CTX-003**: The system **should** investigate using prompts for expected casing/punctuation styles.
*   **REQ-CTX-004**: The system **may** explore app-wide persona prompts.
*   **REQ-CTX-005**: The system **should** investigate hot-word biasing by prepending a short list of key terms (e.g., `[GraphQL], [Dictaum]`) to `initial_prompt` per chunk.

### 1.7. User Experience (UX) and Guidance
*   **REQ-UX-001**: The system **shall** continue clear guidance on model selection.
*   **REQ-UX-002**: The system **shall** ensure users understand benefits of `.en` models for English.
*   **REQ-UX-003**: Based on confidence scores (see REQ-ACC-005), the system **shall** implement UX enhancements:
    *   Highlighting low-confidence words/segments.
    *   Optionally deferring clipboard writes.
    *   Optionally logging anonymized (word, confidence, was_edited) data locally.
*   **REQ-UX-004**: The system **should** allow domain-specific presets for model selection and configuration.
*   **REQ-UX-005**: The impact of UX changes like deferred clipboard write **should** be A/B tested by logging user correction rates or other relevant metrics.

### 1.8. Robustness and Error Handling
*   **REQ-ERR-001**: The system **shall** implement enhanced error handling, especially for streaming and problematic audio.
*   **REQ-ERR-002**: The system **should** provide user feedback for difficult-to-transcribe audio.

### 1.9. Future Capabilities
*   **REQ-FTR-001**: The system **should** investigate using word-level timestamps for advanced features (karaoke highlighting, auto-punctuation).
*   **REQ-FTR-002**: The system **may** investigate simple speaker change detection.
*   **REQ-FTR-003**: The system **should** investigate the feasibility of on-device LoRA fine-tuning on user corrections in a 3-6 month horizon.

## 2. Non-Functional Requirements
*   **NFR-PERF-001**: Enhancements **must** maintain or improve perceived performance.
*   **NFR-PERF-002**: Transcription tasks **shall** use appropriate background threads (e.g., QoS `userInitiated`), UI updates on main/interactive thread.
*   **NFR-RES-001**: Resource use (CPU, memory) **shall** be monitored and optimized.
*   **NFR-RES-002**: The system **shall** manage Metal memory (e.g., unload idle models).
*   **NFR-RES-003**: The system **should** investigate NPU (ANE) offload capabilities for power reduction in a 6-12 month horizon.
*   **NFR-CONF-001**: Key experimental parameters **should** be configurable during development/testing.
*   **NFR-COMP-001**: The system **shall** undergo checks per release to ensure ML models (e.g., Whisper weights) are compliant with App Store policies, including notarization if required by Apple.
```
