# RFC: iOS Simulator text-to-speech microphone injection

Status: **Proposal / investigation — not implemented**

## Motivation
Voice-driven applications need a black-box E2E command that exercises the microphone and actual speech-recognition pipeline. Injecting text into an input field or playing audio on the host does not test that pipeline.

## Proposed user-facing API

```yaml
- launchApp
- tapOn: "Microphone"
- textToSpeech: "Hello, I'd like to order a burger"
- assertVisible: "Burger"
```

A future expanded form could accept `text`, `language`, `rate`, and `voice`, but the initial API should remain a scalar string.

## Architecture

Follow the repository's documented command path:
`YamlCommandReader -> MaestroCommand -> Orchestra -> Maestro -> Driver -> Device`.

- `maestro-orchestra-models`: JSON-serializable command representation.
- `maestro-orchestra`: YAML decoding, script evaluation and dispatch.
- `maestro-client`: target-independent driver capability.
- iOS-specific implementation: host-side TTS and a validated audio-input route to the booted simulator.
- `maestro-test`: parsing, dispatch and failure-mode tests using FakeDriver.

**Important:** iOS Simulator audio-input injection is not yet proven. Do not claim that `say`, AVSpeechSynthesizer, or host speaker playback feeds the simulator microphone. First create a minimal test app using AVAudioEngine input tap, record the received samples, and confirm that injected speech reaches that input.

## Proof-of-concept acceptance gate

1. Boot a clean iOS Simulator and launch a microphone-recording fixture app.
2. Generate a spoken phrase without requiring a checked-in WAV.
3. Route synthesized audio to the simulator's microphone input.
4. Assert that recorded input contains the injected phrase, not silence or host ambient noise.
5. Verify repeatability, simulator isolation, CI compatibility, and cleanup on failure.

Only after this gate should the public YAML command be wired through Maestro.

## Maintainer questions

1. Is `textToSpeech` preferable to `inputAudio`?
2. Should audio injection live in `Driver` or an optional capability?
3. Are host virtual audio devices acceptable for Maestro Cloud?
4. Should an audio fixture mode be included in the first PR?
5. What is the preferred unsupported-platform error behavior?

## Contribution guidance

This is a Type B feature per CONTRIBUTING.md: request design feedback before a large implementation. Keep Orchestra and Maestro platform-agnostic, avoid arbitrary user-supplied process execution, and test using FakeDriver.

## Current state

Design proposal only. No working microphone injection, new YAML parser, or simulator integration is included in this branch yet.
