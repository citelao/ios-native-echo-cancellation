# EchoTest

A tiny iOS app for testing native Acoustic Echo Cancellation (AEC): it
plays your microphone input back to you after a delay, so you can hear
whether AEC is doing its job.

Companion to the macOS version at
[mac-native-echo-cancellation](../mac-native-echo-cancellation).

## Run

Open `EchoTest/EchoTest.xcodeproj` in Xcode and run on a device or
simulator (iOS 17+). On first launch, iOS will prompt for microphone
access. Tap **Start** to begin.

If you change `EchoTest/project.yml`, regenerate the project with
[XcodeGen](https://github.com/yonaskolb/XcodeGen):

```
cd EchoTest
xcodegen generate
```

## Usage

- **Echo Cancellation (AEC)** — toggles `AVAudioInputNode`'s voice
  processing (the same AEC unit iOS uses for calls). Restarts the audio
  engine when toggled.
- **Delay** — how long (0–2s) before your mic input is played back.
- **Level meter** — live RMS of the mic input.

Wear headphones when AEC is off, or you'll get real audio feedback.

## How it works

`AVAudioEngine` graph: `inputNode → AVAudioUnitDelay (100% wet) →
mainMixerNode → output`. AEC is `AVAudioInputNode.setVoiceProcessingEnabled(_:)`.
The audio session is configured as `.playAndRecord` with
`.defaultToSpeaker` so playback comes out the speaker rather than the
earpiece.
