# iOS Simulator microphone test

The experimental `textToSpeech` command synthesizes speech on macOS and plays it into a local iOS Simulator's microphone through BlackHole 2ch. The command waits for playback to finish. It uses the macOS speech voice and accepts a scalar string with Maestro variable interpolation.

## Setup

1. Install [BlackHole 2ch](https://existential.audio/blackhole/) on the Mac running Maestro.
2. Boot the target iOS Simulator. In Simulator's sound input menu, select **BlackHole 2ch**. The command also accepts Simulator's **System** input when the macOS default input is BlackHole 2ch.
3. Leave the Mac's output on its usual device. Maestro opens BlackHole directly for speech playback.
4. Grant microphone permission to the app and start listening before running `textToSpeech`.

BlackHole is shared by every process and simulator using that device. Run microphone tests serially on a host and reserve the device for the test. The experimental implementation requires a local iOS Simulator on macOS with Xcode command-line access. Hosted Maestro Cloud and physical iOS devices are outside its scope.

## Run the microphone fixture

From the repository root, with the target simulator booted:

```sh
./gradlew :maestro-cli:installDist
bash experiments/ios-speech-injection/install-mic-probe.sh <simulator-udid>
maestro-cli/build/install/maestro/bin/maestro --device <simulator-udid> test \
    experiments/ios-speech-injection/microphone-flow.yaml
```

The flow starts the fixture's microphone recorder, injects the phrase, stops recording, and checks that the recording contains a signal. To verify the phrase itself, inspect the WAV recorded by the fixture:

```sh
data_dir="$(xcrun simctl get_app_container <simulator-udid> org.maestro.local-mic-probe data)"
afplay "$data_dir/Documents/capture.wav"
```
