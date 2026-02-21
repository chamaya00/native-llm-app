# native-llm-app

An iOS chat app that uses Apple's Foundation Models framework for fully on-device LLM inference. No server, no API keys—everything runs on the device.

## TestFlight Testing Guide

### Prerequisites

Before you can test, you need:

- **An iPhone or iPad with an A17 Pro, M1, or newer chip** — Apple Intelligence (and the on-device LLM) only runs on these devices. Older devices will see an "unsupported device" message, which is expected behavior.
- **iOS 26.0 or later** installed on the device.
- **The TestFlight app** installed from the App Store (search "TestFlight" by Apple).
- **Apple Intelligence enabled** on the device:
  - Go to **Settings → Apple Intelligence & Siri**
  - Toggle on **Apple Intelligence**
  - If prompted, download any required language model assets and wait for them to finish installing

### Step 1: Accept the TestFlight Invitation

You should have received a TestFlight invite email from Apple. Open it on your device and tap **"View in TestFlight"**, or open the TestFlight app directly and look for **LLM Chat** under "Apps to Test".

If you haven't received an invite, ask the developer to add you as a tester in App Store Connect.

### Step 2: Install the App

In TestFlight, tap **Install** next to LLM Chat. The app will download and appear on your home screen.

### Step 3: Test the App

Open **LLM Chat** from your home screen.

**Things to verify:**

1. **Chat interface loads** — You should see an empty conversation with a text field at the bottom.

2. **Send a message** — Type something like "Hello, how are you?" and tap the send button (or press Return). Verify:
   - Your message appears in a blue bubble on the right.
   - A typing indicator (animated dots) appears while the model is thinking.
   - A response appears in a gray bubble on the left with a brain icon.

3. **Multi-turn conversation** — Send several follow-up messages to confirm the model maintains context (e.g., "Tell me a joke", then "Explain it to me").

4. **Long response handling** — Ask something that produces a long answer (e.g., "Explain quantum computing in detail") and verify the scroll view works correctly.

5. **Error state** — If the on-device model is unavailable (e.g., Apple Intelligence is off), the app should display a clear error message rather than crashing.

6. **Unsupported device** (if you have one to test) — On a device that doesn't support Apple Intelligence, the app should show an "unsupported device" screen instead of the chat UI.

### Submitting Feedback

- **Shake the device** while in the app to open TestFlight's built-in feedback form — you can attach a screenshot and a note.
- For bugs or feature requests, open an issue on [GitHub](https://github.com/chamaya00/native-llm-app/issues).

---

## Project Overview

| Area | Technology |
|------|------------|
| UI | SwiftUI |
| On-device LLM | Apple Foundation Models (iOS 26+) |
| Project generation | XcodeGen |
| CI/CD | GitHub Actions + Fastlane |

## Architecture

```
LLMChat/
├── Sources/
│   ├── App/            # App entry point
│   ├── Views/          # ChatView, MessageBubble
│   ├── ViewModels/     # ChatViewModel (@Observable)
│   └── Services/       # LLMService (Foundation Models)
├── Resources/          # Assets, Info.plist
└── fastlane/           # Build and deploy lanes
```

The app uses `LanguageModelSession` from the Foundation Models framework to run inference entirely on-device. On simulators it returns a mock response so the UI can be validated without a real device.
