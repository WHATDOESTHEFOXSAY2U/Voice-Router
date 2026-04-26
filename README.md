# Voice Router

Voice Router is an iPhone app for one job:

**press once, speak naturally, and get clipboard-ready text fast.**

It keeps the flow deliberately small:

- Live speech transcription
- Optional Apple Intelligence cleanup before copy
- Local capture history for recovery and retry
- App Shortcut support for the iPhone Action Button

## How It Feels

1. Start capture from the app or the Action Button shortcut.
2. Speak naturally.
3. Pause to finish automatically, or stop manually.
4. Paste the result anywhere.

## Run It

1. Generate the Xcode project from `project.yml` if the `.xcodeproj` is missing.
2. Open the project in Xcode.
3. Select an iPhone as the run destination.
4. Confirm your Development Team under **Signing & Capabilities**.
5. Build and run.

## First-Time Setup

1. Open the app and allow **Microphone** and **Speech Recognition** access.
2. In Settings inside the app, decide whether Apple Intelligence formatting should be enabled.
3. On iPhone, open **Settings > Action Button > Shortcut**.
4. Choose **Start Voice Capture** from Voice Router.

## Notes

- Speech recognition is best tested on a physical iPhone.
- If Apple Intelligence is unavailable for the current build, locale, or device, Voice Router falls back to the raw transcript.
- Fallback trigger: `voicerouter://capture`

## Stack

- SwiftUI
- App Intents / App Shortcuts
- Speech framework
- XcodeGen
