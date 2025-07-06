# Requirements for Improving Transcription Quality

This document outlines the requirements for enhancing the audio transcription capabilities of the Dictaum application.

## 1. Functional Requirements for Enhancement

These requirements aim to improve transcription accuracy, performance, and user experience, building upon the analysis of the current system.

### 1.1. Core Transcription Accuracy and Features
*   **REQ-ACC-001**: The system **shall** allow experimentation with different `temperature` values (e.g., 0.1 to 0.4) in `DecodingOptions` to assess impact on transcription quality for various speech types. The optimal setting should be configurable or dynamically chosen if feasible.
*   **REQ-ACC-002**: The system **shall** be investigated for compatibility with beam search. If `WhisperKit` supports beam search (e.g., `beam_size` parameter), it **shall** be evaluated for accuracy improvements versus performance cost, and implemented if beneficial.
*   **REQ-ACC-003**: The system **shall** enable timestamp generation during transcription (e.g., set `withoutTimestamps: false`).
*   **REQ-ACC-004**: Generated timestamps **should** be evaluated for use in advanced segment stitching (e.g., paragraph breaks based on pause durations) or for potential future features like audio-text alignment.
*   **REQ-ACC-005**: The system **should** investigate the utility of segment-level confidence scores or log probabilities from `WhisperKit`, if available, for indicating transcription certainty or for debugging.

### 1.2. Language Support
*   **REQ-LANG-001**: For multilingual Whisper models, the system **shall** provide a mechanism for users to select the desired transcription language. The `language` parameter in `DecodingOptions` must be dynamically set based on this selection.
*   **REQ-LANG-002**: The system **should** explore the feasibility of automatic language detection if supported by `WhisperKit` (e.g., by passing a null or empty language code to `DecodingOptions` when a multilingual model is active).

### 1.3. Real-time Transcription (Streaming)
*   **REQ-STR-001**: The system **shall** be re-architected to support streaming transcription, providing users with real-time (or near real-time) text feedback as they speak.
*   **REQ-STR-002**: For streaming, the system **shall** implement robust audio chunking (e.g., 5-10 second chunks, or based on `WhisperKit` recommendations) to feed the streaming API.
*   **REQ-STR-003**: The streaming implementation **shall** manage overlapping audio chunks appropriately to maintain transcription context, aligning with Whisper's typical 30-second processing window.
*   **REQ-STR-004**: The user interface **shall** be updated to display progressively transcribed segments during a streaming session.
*   **REQ-STR-005**: The system **shall** manage segment finalization and updates effectively during streaming.

### 1.4. Audio Processing and Segmentation
*   **REQ-AUD-001**: The system **shall** implement Voice Activity Detection (VAD) to offer users an option for automatic recording stop/start or to assist in segmenting speech during long pauses.
*   **REQ-AUD-002**: For non-streaming, very long recordings (e.g., exceeding 2 minutes), the system **should** investigate manual chunking into overlapping segments (e.g., 30 seconds with 5-10 second overlap) for sequential transcription to potentially improve stability or quality, mimicking Whisper's internal processing.

### 1.5. Contextual Transcription
*   **REQ-CTX-001**: The system **shall** enable and evaluate the effectiveness of prompt-based contextualization by setting `usePrefillPrompt: true` and `usePrefillCache: true` in `DecodingOptions`.
*   **REQ-CTX-002**: When contextualization is active, the prompt **shall** typically consist of recently confirmed transcribed text, especially relevant for streaming or sequential chunk transcription.

### 1.6. User Experience and Guidance
*   **REQ-UX-001**: The system **shall** continue to provide clear guidance on model selection, detailing trade-offs (speed, accuracy, resource use, language capabilities).
*   **REQ-UX-002**: The system **shall** ensure users understand the benefits of English-only (`.en`) models if their primary language is English.

### 1.7. Robustness and Error Handling
*   **REQ-ERR-001**: The system **shall** implement enhanced error handling, particularly for streaming transcription (e.g., for individual chunk processing failures) and for problematic audio inputs (e.g., excessive noise, silence).
*   **REQ-ERR-002**: The system **should** provide user feedback when parts of the audio are difficult to transcribe, if such information can be derived from the transcription process (e.g., low confidence scores).

## 2. Non-Functional Requirements
*   **NFR-PERF-001**: Any implemented enhancements **must** strive to maintain or improve the perceived performance and responsiveness of the application. Performance impacts of features like beam search or streaming must be carefully evaluated.
*   **NFR-RES-001**: Resource utilization (CPU, memory) **shall** be monitored during the implementation of new features. Optimizations should be applied to ensure the application remains lightweight and efficient.
*   **NFR-CONF-001**: Key experimental parameters (e.g., temperature, beam size, VAD thresholds, chunk durations for streaming/manual chunking) **should** be configurable, at least during development and testing phases, to facilitate tuning.
```
