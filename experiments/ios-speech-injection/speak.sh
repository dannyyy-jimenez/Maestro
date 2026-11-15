#!/usr/bin/env bash
# EXPERIMENT ONLY: generate speech and play it through the host's default output.
# This does NOT by itself inject audio into an iOS Simulator microphone.
set -euo pipefail
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This experiment requires macOS." >&2
  exit 2
fi
if [[ $# -ne 1 || -z "$1" ]]; then
  echo 'Usage: bash speak.sh "Hello, I would like to order a burger"' >&2
  exit 2
fi
for executable in say afplay; do
  command -v "$executable" >/dev/null || { echo "Missing: $executable" >&2; exit 2; }
done
audio_file="$(mktemp "${TMPDIR:-/tmp}/maestro-tts.XXXXXXXX.aiff")"
trap 'rm -f "$audio_file"' EXIT
say -o "$audio_file" -- "$1"
# Route the macOS default audio output to a virtual loopback device manually.
# Then configure the simulator's audio input to use the corresponding loopback input.
afplay "$audio_file"
