# Requirements for Improving Transcription Quality

This document outlines the requirements for enhancing the audio transcription capabilities of the Dictaum application. Enhancements should generally follow a prioritization that addresses quick wins and critical fixes first, then differentiators, then longer-term items.

## 1. Functional Requirements for Enhancement

These requirements aim to improve transcription accuracy, performance, and user experience, building upon the analysis of the current system and additional tuning opportunities.

### 1.1. Audio Front-end Processing
*   **REQ-AUD-001**: The system **shall** implement Voice Activity Detection (VAD) to offer users an option for automatic recording stop/start or to assist in segmenting speech during long pauses.
*   **REQ-AUD-002**: For non-streaming, very long recordings (e.g., exceeding 2 minutes), the system **should** investigate manual chunking into overlapping segments (e.g., 30 seconds with 5-10 second overlap) for sequential transcription to potentially improve stability or quality.
*   **REQ-AUD-003**: To prevent missed initial words or syllables, the system **shall** implement a pre-roll audio buffer (e.g., start audio tap 200-300ms before UI indicates recording) and **should** apply an audio fade-in (e.g., first 20ms) to the beginning of recordings.
*   **REQ-AUD-004**: The system **shall** provide mechanisms for background noise reduction, such as implementing a high-pass filter (e.g., `AVAudioUnitEQ` at ~80Hz) and **should** evaluate using `AVAudioUnitVarispeed` on Apple Silicon for its built-in noise suppression.
*   **REQ-AUD-005**: The system **shall** investigate and implement Automatic Gain Control (AGC) (e.g., via `AVAudioSessionModeMeasurement` and `setPreferredInputGain:`) to maintain consistent audio input levels.

### 1.2. Core Transcription Accuracy and Decoding Parameters
*   **REQ-ACC-001**: The system **shall** allow experimentation with different `temperature` values (e.g., 0.1 to 0.4) in `DecodingOptions`. The optimal setting should be configurable or dynamically chosen if feasible.
*   **REQ-ACC-002**: The system **shall** be investigated for compatibility with beam search (e.g., `beam_size` parameter, suggested sweep `1`→`3`→`5`). It **shall** be evaluated for accuracy improvements versus performance cost, and implemented if beneficial as a baseline or option.
*   **REQ-ACC-003**: The system **shall** enable timestamp generation during transcription (e.g., set `withoutTimestamps: false`).
*   **REQ-ACC-004**: Generated timestamps **should** be evaluated for use in advanced segment stitching (e.g., paragraph breaks based on pause durations) or for potential future features like audio-text alignment and advanced word-level timestamp usage (see REQ-FTR-001).
*   **REQ-ACC-005**: The system **should** investigate the utility of segment-level or word-level confidence scores or log probabilities from `WhisperKit`, if available, for indicating transcription certainty, debugging, or driving UX features (see REQ-UX-003).
*   **REQ-ACC-006**: The system **shall** investigate and allow experimentation with the `bestOf` parameter (e.g., suggested sweep `1`→`3`→`5` with `temperature = 0.2–0.4`) in `DecodingOptions` to improve results for noisy speech.
*   **REQ-ACC-007**: If exposed by `WhisperKit`, the system **should** investigate and allow experimentation with `topP` (nucleus sampling) (e.g., suggested sweep `0.9`→`0.95`) as an alternative or complement to `topK` and `temperature`.

### 1.3. Duplicate and Hallucination Mitigation
*   **REQ-FIX-001**: The system **should** investigate and implement heuristics like the "Stable-Whisper heuristic" (re-scoring segments and dropping unstable ones based on log-probability changes) to reduce hallucinations or unwanted repetitions.
*   **REQ-FIX-002**: For chunked or streaming transcription, the system **shall** implement content-aware overlap merging (e.g., Jaccard-matching token sequences between adjacent chunks) to prevent duplicated content at segment boundaries.

### 1.4. Language Support
*   **REQ-LANG-001**: For multilingual Whisper models, the system **shall** provide a mechanism for users to select the desired transcription language. The `language` parameter in `DecodingOptions` must be dynamically set based on this selection.
*   **REQ-LANG-002**: The system **should** explore the feasibility of automatic language detection if supported by `WhisperKit` when a multilingual model is active.

### 1.5. Real-time Transcription (Streaming)
*   **REQ-STR-001**: The system **shall** be re-architected to support streaming transcription, providing users with real-time (or near real-time) text feedback as they speak.
*   **REQ-STR-002**: For streaming, the system **shall** implement robust audio chunking (e.g., 5-10 second chunks, or based on `WhisperKit` recommendations) to feed the streaming API.
*   **REQ-STR-003**: The streaming implementation **shall** manage overlapping audio chunks appropriately (see REQ-FIX-002) to maintain transcription context, aligning with Whisper's typical 30-second processing window.
*   **REQ-STR-004**: The user interface **shall** be updated to display progressively transcribed segments during a streaming session.
*   **REQ-STR-005**: The system **shall** manage segment finalization and updates effectively during streaming.

### 1.6. Contextual Transcription and Prompting
*   **REQ-CTX-001**: The system **shall** enable and evaluate the effectiveness of basic prompt-based contextualization by setting `usePrefillPrompt: true` and `usePrefillCache: true` in `DecodingOptions`, using recently confirmed text as prompt.
*   **REQ-CTX-002**: The system **shall** allow users to provide custom vocabulary lists or jargon (e.g., comma-separated terms) as part of the initial prompt to WhisperKit to improve recognition of specific terms.
*   **REQ-CTX-003**: The system **should** investigate using prompts to guide WhisperKit towards expected casing and punctuation styles.
*   **REQ-CTX-004**: The system **may** explore app-wide persona prompts for highly specialized versions or modes (e.g., "You are a coding assistant").

### 1.7. User Experience (UX) and Guidance
*   **REQ-UX-001**: The system **shall** continue to provide clear guidance on model selection, detailing trade-offs (speed, accuracy, resource use, language capabilities).
*   **REQ-UX-002**: The system **shall** ensure users understand the benefits of English-only (`.en`) models if their primary language is English.
*   **REQ-UX-003**: Based on confidence scores (see REQ-ACC-005), the system **shall** implement UX enhancements such as:
    *   Highlighting low-confidence words/segments (e.g., ≤0.4 probability).
    *   Optionally deferring clipboard writes until confidence is above a threshold or user confirms.
    *   Optionally logging anonymized (word, confidence, was_edited) data locally for future analysis or active learning.
*   **REQ-UX-004**: The system **should** allow users to select domain-specific presets (e.g., "Medical", "Legal") that automatically choose recommended models (e.g., `large-v3` over `large-v3-Turbo` for medical terms) and potentially specific prompts or decoding parameters.

### 1.8. Robustness and Error Handling
*   **REQ-ERR-001**: The system **shall** implement enhanced error handling, particularly for streaming transcription (e.g., for individual chunk processing failures) and for problematic audio inputs (e.g., excessive noise, silence).
*   **REQ-ERR-002**: The system **should** provide user feedback when parts of the audio are difficult to transcribe, if such information can be derived from the transcription process.

### 1.9. Future Capabilities
*   **REQ-FTR-001**: The system **should** investigate using word-level timestamps for advanced features like karaoke-style highlighting during playback (if implemented) or pause-based auto-punctuation.
*   **REQ-FTR-002**: The system **may** investigate simple speaker change detection heuristics (e.g., based on energy/pitch changes) for basic labeling in multi-speaker scenarios.

## 2. Non-Functional Requirements
*   **NFR-PERF-001**: Any implemented enhancements **must** strive to maintain or improve the perceived performance and responsiveness of the application. Performance impacts of features like beam search or streaming must be carefully evaluated.
*   **NFR-PERF-002**: Transcription tasks **shall** be pinned to appropriate background threads (e.g., `DispatchQueue.global(qos: .userInitiated)`) while UI updates remain on the main/interactive thread to prevent UI stutters.
*   **NFR-RES-001**: Resource utilization (CPU, memory) **shall** be monitored during the implementation of new features. Optimizations should be applied to ensure the application remains lightweight and efficient.
*   **NFR-RES-002**: The system **shall** implement mechanisms to manage Metal memory usage, such as unloading models from memory after a configurable period of inactivity and reloading them on demand.
*   **NFR-CONF-001**: Key experimental parameters (e.g., temperature, beam size, `bestOf`, `topP`, VAD thresholds, buffer/chunk durations, confidence thresholds) **should** be configurable, at least during development and testing phases, to facilitate tuning.
```
