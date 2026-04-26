# Voice Router

Voice Router is an iPhone utility for one job:

**press once → speak naturally → get clipboard-ready text immediately.**

The app keeps a local history so nothing gets lost, and it can optionally clean up the transcript with Apple Intelligence before copying.

## Original Ask

The product brief behind this repo was narrower than the earlier implementation:

- Trigger capture quickly, ideally from the **Action Button**.
- Show a clear **top-of-screen / Dynamic Island-adjacent visual cue** so the user knows capture has started.
- Let the user **speak naturally**.
- **Transcribe and copy** the result to the clipboard.
- If enabled in settings, **format the transcript with Apple Intelligence** before copying.

## What This Repo Had Drifted Into

When this codebase was picked up again, it had moved away from that brief:

- The app was positioned as a broader **voice router** that classified notes, reminders, ideas, and inbox items.
- Output formatting was driven by a **rule-based intent router** instead of a simple transcript-to-clipboard flow.
- There was **no settings surface** for Apple Intelligence formatting.
- Action Button support was only hinted at, not implemented as a proper **App Shortcut** flow.

## What It Does Now

The app has been refocused around the original workflow:

- **One-tap capture** with live speech transcription.
- **Auto-finish after a short pause** for a faster “press once, speak, done” flow.
- **Clipboard-first output** instead of note/task routing.
- **Apple Intelligence formatting toggle** with raw transcript fallback when the on-device model is unavailable.
- **App Shortcut entry point** for Action Button setup, plus a `voicerouter://capture` fallback trigger.
- **Local capture history** with transcript, clipboard output, status, and retry/delete actions.
- **Redesigned SwiftUI UI** centered around a stronger top capture indicator, clearer transcript area, and focused settings/history sheets.

## Build Notes

- The repo uses **XcodeGen**. If the `.xcodeproj` is missing, generate it from `project.yml` first.
- Speech recognition requires a **physical iPhone** to test properly.
- Apple Intelligence formatting is guarded behind availability checks. If the build, OS, locale, or device does not support it, Voice Router falls back to copying the raw transcript.

## How to Run

1. Generate the Xcode project from `project.yml`.
2. Open the generated Xcode project.
3. Select your iPhone as the run destination.
4. Confirm your Development Team under **Signing & Capabilities**.
5. Build and run.

## Suggested Device Setup

1. Open the app once and grant **Microphone** and **Speech Recognition** access.
2. In the app, decide whether **Apple Intelligence formatting** should be enabled.
3. Assign the **Start Capture** shortcut to the iPhone Action Button.
4. Press the Action Button and speak naturally.

## Future Extensions

- Replace the in-app top capsule with a true **Live Activity / Dynamic Island** implementation if you want system-level feedback outside the foreground app.
- Add **share sheet / paste targets** for direct handoff into notes, reminders, or specific apps.
- Add **language selection** and per-language transcription preferences.
