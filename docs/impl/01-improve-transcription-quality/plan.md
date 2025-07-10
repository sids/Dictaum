# Implementation Plan: Improve Transcription Quality

This document outlines the phased implementation plan for enhancing Dictaum's transcription quality, based on the analysis and requirements documents. The plan follows a prioritization approach emphasizing quick wins, critical fixes, differentiators, and then longer-term features.

## Phase Status Management

As we implement this plan phase-by-phase, we will track progress using the following status system:
- **TODO**: Phase not yet started
- **DOING**: Phase currently under implementation
- **DONE**: Phase completed and tested

## Testing Strategy

We will thoroughly test after every logical implementation point, even within a single phase. This includes:
- Automated testing where possible (unit tests, WER harness, performance metrics)
- Manual testing requests to the user for functionality that cannot be automated
- User acceptance testing for UX improvements and subjective quality assessments

The user will be asked to test changes when automated testing is insufficient or when subjective evaluation is needed (e.g., transcription quality, user interface improvements, audio processing effectiveness).

## Phase 1: Quick Wins - Audio Front-end & Decoder Parameters
**Status**: TODO

### Objective
Implement low-effort, high-payoff improvements to audio processing and core transcription parameters to achieve immediate quality gains.

### Requirements Covered
- REQ-AUD-001 through REQ-AUD-006 (Audio front-end processing)
- REQ-ACC-001 through REQ-ACC-009 (Core transcription accuracy)
- REQ-LANG-001, REQ-LANG-002 (Language support)

### Implementation Direction

#### 1.1 Audio Front-end Enhancements
- **Pre-roll buffer implementation**: Start audio tap 200-300ms before UI indicates recording
- **Fade-in processing**: Apply 20ms fade-in to prevent abrupt start artifacts
- **High-pass filtering**: Implement `AVAudioUnitEQ` with ~80Hz cutoff for noise reduction
- **AGC implementation**: Use `AudioDeviceSetProperty(kAudioDevicePropertyVolumeScalar, …)` for consistent levels
- **Audio level monitoring**: Log peak/RMS before/after processing, target -12 dBFS ± 3 dB

#### 1.2 Decoder Parameter Experimentation
- **Temperature tuning**: Systematic testing of 0.1-0.4 values vs current 0.0
- **Beam search evaluation**: Test beam_size values 1→3→5 for accuracy vs performance
- **bestOf parameter**: Test values 1→3→5 with temperature 0.2-0.4
- **Timestamp enabling**: Set `withoutTimestamps: false` for future features
- **topP exploration**: If available, test nucleus sampling 0.9→0.95

#### 1.3 Testing Infrastructure
- **WER harness**: Develop test suite with 10-15 representative WAV files and ground truth
- **Automated testing**: Unit tests for parameter sweeps with WER and latency metrics
- **Language selection**: UI for multilingual model language configuration

### Success Criteria
- Measurable WER improvement on test harness
- Reduced first-syllable dropout incidents
- Consistent audio level processing (-12 dBFS ± 3 dB)
- Automated testing infrastructure operational

---

## Phase 2: Duplication Fixes
**Status**: TODO

### Objective
Address segment duplication and hallucination issues that affect transcription reliability.

### Requirements Covered
- REQ-FIX-001, REQ-FIX-002 (Duplicate and hallucination mitigation)
- REQ-ERR-001, REQ-ERR-002 (Enhanced error handling)

### Implementation Direction

#### 2.1 Stable-Whisper Heuristic
- **Log-probability scoring**: Implement segment re-scoring to detect unreliable segments
- **Threshold-based filtering**: Drop segments with log-probability drops > τ threshold
- **Custom logic development**: May require WhisperKit wrapper enhancements

#### 2.2 Content-Aware Overlap Merging
- **Token-based matching**: Use decoded words/token IDs for overlap detection (not raw bytes)
- **Jaccard similarity**: Implement matching algorithm for segment boundary detection
- **Duplicate trimming**: Remove redundant content at chunk boundaries

#### 2.3 Enhanced Error Handling
- **Graceful degradation**: Better handling of problematic audio segments
- **User feedback**: Inform users when audio is difficult to transcribe
- **Fallback strategies**: Multiple recovery approaches for failed segments

### Success Criteria
- Elimination of duplicate text in transcriptions
- Reduced hallucination incidents
- Robust error recovery mechanisms
- Clear user feedback for transcription issues

---

## Phase 3: Differentiators - Prompts & UX
**Status**: TODO

### Objective
Implement contextual transcription features and confidence-driven UX improvements that differentiate Dictaum from basic transcription tools.

### Requirements Covered
- REQ-CTX-001 through REQ-CTX-005 (Contextual transcription and prompting)
- REQ-UX-001 through REQ-UX-005 (User experience enhancements)

### Implementation Direction

#### 3.1 Contextual Prompting
- **Prefill prompts**: Enable `usePrefillPrompt: true` and `usePrefillCache: true`
- **Custom vocabulary**: User-configurable jargon/technical term lists
- **Hot-word biasing**: Prepend key terms like `[GraphQL], [Dictaum]` to initial_prompt
- **Style prompts**: Casing, punctuation, and formatting preferences
- **Domain presets**: Preconfigured settings for healthcare, legal, coding contexts

#### 3.2 Confidence-Driven UX
- **Confidence scoring**: Extract word/segment-level confidence from WhisperKit
- **Visual indicators**: Highlight low-confidence words (≤ 0.4 threshold)
- **Deferred pasting**: Optional clipboard write delay until confidence threshold met
- **User confirmation**: Require ⌘↩ for low-confidence transcriptions
- **Learning data**: Anonymous logging of (word, confidence, was_edited) locally

#### 3.3 Model Selection Guidance
- **Clear model explanations**: Benefits of .en models for English users
- **Domain-specific recommendations**: Model selection based on use case
- **Performance vs accuracy tradeoffs**: User education on model choices

### Success Criteria
- Reduced user correction rates through confidence gating
- Improved transcription accuracy for technical/domain-specific terms
- Enhanced user understanding of model capabilities
- Measurable improvement in user satisfaction

---

## Phase 4: Major Features - Streaming
**Status**: TODO

### Objective
Re-architect the application to support real-time streaming transcription for improved user experience.

### Requirements Covered
- REQ-STR-001 through REQ-STR-005 (Real-time transcription)
- NFR-PERF-001, NFR-PERF-002 (Performance requirements)

### Implementation Direction

#### 4.1 Streaming Architecture
- **Audio chunking**: Implement 5-10s chunks with appropriate overlap
- **WhisperKit streaming**: Utilize streaming APIs for real-time processing
- **State management**: Handle complex streaming state transitions
- **Buffer management**: Efficient audio buffer handling for continuous processing

#### 4.2 Progressive UI Updates
- **Real-time display**: Show transcribed text as it becomes available
- **Segment updates**: Handle text refinement as context improves
- **Visual feedback**: Indicate processing status and confidence levels
- **Final segment handling**: Manage completed vs in-progress segments

#### 4.3 Performance Optimization
- **Background processing**: Ensure transcription on `userInitiated` QoS queue
- **UI responsiveness**: Maintain smooth interface during continuous processing
- **Resource management**: Efficient memory and CPU usage for streaming
- **Latency minimization**: Optimize for real-time user experience

### Success Criteria
- Sub-second latency for streaming transcription
- Smooth UI performance during continuous operation
- Seamless segment transitions without duplicates
- Improved perceived responsiveness

---

## Phase 5: Future Capabilities
**Status**: TODO

### Objective
Implement advanced features and optimizations for long-term competitive advantage.

### Requirements Covered
- REQ-FTR-001 through REQ-FTR-003 (Future capabilities)
- NFR-RES-001 through NFR-RES-003 (Resource optimization)
- NFR-COMP-001 (Compliance)

### Implementation Direction

#### 5.1 Advanced Features
- **Word-level timestamps**: Karaoke-style highlighting and auto-punctuation
- **Speaker detection**: Basic energy/pitch-based speaker change detection
- **Voice Activity Detection**: Automatic recording start/stop based on speech presence
- **Long recording chunking**: Automatic segmentation for recordings >2 minutes

#### 5.2 Resource Optimization
- **Metal memory management**: Automatic model unloading after inactivity
- **NPU utilization**: Investigate Apple Neural Engine offload for power efficiency
- **Threading optimization**: Fine-tuned queue management for performance
- **Memory footprint**: Optimize for sustained operation

#### 5.3 Machine Learning Enhancements
- **On-device LoRA fine-tuning**: Adapt models to user corrections locally
- **Adaptive confidence thresholds**: Learn optimal confidence levels per user
- **Personalized vocabulary**: Build user-specific term recognition
- **Active learning**: Improve accuracy through user feedback loops

#### 5.4 Compliance and Future-Proofing
- **Model licensing**: Ensure App Store compliance for ML models
- **Notarization**: Handle Apple's ML model notarization requirements
- **Privacy preservation**: Maintain local processing while adding intelligence
- **API evolution**: Prepare for WhisperKit and Core ML updates

### Success Criteria
- Personalized transcription accuracy improvements
- Reduced power consumption through NPU utilization
- Advanced features that differentiate from competitors
- Full compliance with App Store requirements

---

## Implementation Notes

### Development Approach
- Each phase should be completed before moving to the next
- All changes must be measurable through the WER harness
- User testing should validate UX improvements
- Performance regression testing required for each phase

### Risk Mitigation
- Maintain backward compatibility throughout implementation
- Feature flags for experimental capabilities
- Rollback capability for each phase
- Comprehensive testing before user-facing releases

### Success Metrics
- Word Error Rate (WER) improvement
- User correction frequency reduction
- Latency measurements
- User satisfaction scores
- Resource utilization metrics

This plan provides a structured approach to systematically improve Dictaum's transcription quality while maintaining development velocity and user experience.