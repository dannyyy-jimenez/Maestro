# iOS Simulator speech-input proof of concept

**Status: experimental, unverified.** This is a host-side TTS playback harness, **not** a working Maestro YAML command or proven microphone injection.

## Goal

Determine whether audio played to a macOS virtual loopback output can be captured as microphone input by a booted iOS Simulator. Do not wire a public command until this is demonstrated with recorded samples.

## Run on a Mac

1. Boot an iOS Simulator.
2. Install a trusted virtual loopback audio device (for example, BlackHole) and configure the macOS default output to the loopback output. Be aware that this can temporarily silence normal speaker playback.
3. In Simulator, choose the loopback input if the Simulator's **I/O > Audio Input** menu supports it. Menu availability and routing vary by Xcode version.
4. Run a microphone-recording test app in the Simulator. Grant microphone permission and begin recording.
5. Run `bash experiments/ios-speech-injection/speak.sh "Hello, I would like to order a burger"` from the repository root.
6. Stop recording, export the captured audio, and verify the speech is actually present. Repeat with physical microphone muted/disconnected to rule out acoustic leakage.

## What this proves / doesn't prove

The script uses the built-in macOS `say` tool to synthesize an AIFF file in a temporary location and `afplay` to play it. No user-supplied WAV file is required. The temporary file is deleted on exit.

**Success requires verification in the simulator's recorded microphone stream.** Hearing the phrase on the host is not success. A virtual output device alone is not sufficient unless Simulator can use the matching input. If Simulator cannot select the input, this approach is not viable and we must investigate a different device-level route.

## Next steps

- Record sample audio through `AVAudioEngine.inputNode` in a minimal iOS fixture app and assert non-silence and phrase recognition.
- Test cleanly on a CI macOS runner and two concurrent simulators.
- Decide on a supported, deterministic audio routing backend.
- Only then implement `textToSpeech` through YAML, Orchestra, Maestro, Driver, and iOS driver, with FakeDriver integration tests.

The helper intentionally stays outside Maestro's YAML sandbox; it is a local experiment, not a proposed mechanism for arbitrary shell execution from a test flow.
