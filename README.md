<p align="center">
  <img src="assets/icon-rounded.png" width="128" alt="VaulType Icon">
</p>
<h1 align="center">VaulType</h1>
<p align="center"><em>Your voice stays private. Text appears at your cursor.</em></p>

<p align="center">
  <!-- Badges -->
  <a href="https://github.com/vaultype/VaulType/releases/latest"><img alt="Download" src="https://img.shields.io/github/v/release/vaultype/VaulType?label=Download&logo=apple&color=7B61FF"></a>
  <a href="https://apps.apple.com/app/vaultype/id6759566772"><img alt="Mac App Store" src="https://img.shields.io/badge/Mac_App_Store-available-0D96F6?logo=appstore&logoColor=white"></a>
  <img alt="Platform" src="https://img.shields.io/badge/platform-macOS%2014%2B-blue?logo=apple">
  <img alt="Swift" src="https://img.shields.io/badge/Swift-5.9%2B-orange?logo=swift">
  <img alt="License" src="https://img.shields.io/badge/license-GPL--3.0-green">
  <img alt="Build" src="https://img.shields.io/github/actions/workflow/status/vaultype/VaulType/build.yml?branch=main">
</p>

---

## What is VaulType?

VaulType is a **privacy-first, macOS-native speech-to-text application** that lets you dictate text into any app where your cursor is active — without ever sending your voice to the cloud.

Unlike alternatives that rely on cloud services for full functionality, VaulType runs entirely offline using local AI models:

- **[whisper.cpp](https://github.com/ggerganov/whisper.cpp)** for speech recognition with Metal GPU acceleration
- **[llama.cpp](https://github.com/ggerganov/llama.cpp)** for intelligent text post-processing with local LLMs

The app lives in your macOS menu bar and provides global hotkey-activated dictation with six purpose-built processing modes — from raw transcription to LLM-powered text structuring, grammar correction, and prompt formatting.

> **Vault** = your voice stays locked on your device
> **Type** = text appears at your cursor

## Key Features

| Feature | Description |
|---------|-------------|
| **Zero-Network Architecture** | All speech recognition and LLM processing happens locally. No cloud, no telemetry, no data leaves your Mac. |
| **Dual Local AI Pipeline** | whisper.cpp (STT) + llama.cpp (LLM) bundled in one app — no separate installs, accounts, or cloud services needed. |
| **Six Processing Modes** | Raw, Clean, Structure, Prompt, Code, and Custom modes for every use case. |
| **Universal Text Injection** | Dictate into any macOS app — terminals, browsers, IDEs, Slack, and more.¹ |
| **Voice Commands** | Launch apps, manage windows, and control your Mac with voice.¹ |
| **App-Aware Context** | Auto-selects formatting mode based on the active application. |
| **Editable Overlay** | Review and edit transcribed text in a floating window before injection. |
| **90+ Languages** | Multilingual support with automatic language detection using Whisper's multilingual models. English-only models available for faster performance. |

> ¹ In the **Mac App Store version**, dictated text is copied to the clipboard for you to paste with ⌘V (App Store sandbox rules don't allow apps to type into other apps), and voice commands are limited to launching/switching apps, running Shortcuts, and custom aliases. The **direct download** types text at your cursor and includes the full command set. See [App Store vs. Direct Download](#app-store-vs-direct-download).

## Tech Stack

| Component | Technology |
|-----------|-----------|
| UI Framework | Swift 5.9+ / SwiftUI / AppKit |
| Speech Recognition | whisper.cpp (C/C++) with Metal acceleration |
| LLM Inference | llama.cpp (C/C++) with Metal acceleration |
| Audio Capture | AVAudioEngine |
| Text Injection | CGEvent API / Clipboard |
| Local Storage | SwiftData |
| Build System | Xcode 15+ / Swift Package Manager / CMake |
| CI/CD | GitHub Actions |
| Auto-Updates | Sparkle (direct) / App Store |
| Distribution | Mac App Store / DMG / Homebrew Cask |

## Quick Start

### Install via Homebrew (recommended)

```bash
brew tap vaultype/vaultype
brew install --cask vaultype
```

### Install from GitHub Releases

1. Download the latest `.dmg` from [GitHub Releases](https://github.com/vaultype/vaultype/releases)
2. Open the DMG and drag VaulType to Applications
3. Launch VaulType from Applications

### Install from the Mac App Store

<a href="https://apps.apple.com/app/vaultype/id6759566772">Download VaulType on the Mac App Store</a> — a sandboxed version with the same on-device Whisper + LLM pipeline. Due to App Store sandbox rules it delivers text via the clipboard (press ⌘V to paste) instead of typing at your cursor, and omits a few system-level features. See [App Store vs. Direct Download](#app-store-vs-direct-download).

### First Run

1. **Grant Permissions** — VaulType will request Microphone access; the direct download also requests Accessibility (used to type text at your cursor)
2. **Download a Model** — Open Settings and download a Whisper model (recommended: `small` for balanced speed/accuracy)
3. **Set Your Hotkey** — Default is double-tap Fn or hold Right Option
4. **Start Dictating** — Press your hotkey, speak, and release. Text appears at your cursor (direct) or is copied for ⌘V paste (App Store).

> 💡 For detailed setup instructions, see the [Quick Start Guide](docs/getting-started/QUICK_START.md).

### Build from Source

```bash
# Clone the repository
git clone https://github.com/vaultype/vaultype.git
cd vaultype

# Build whisper.cpp and llama.cpp
./scripts/build-deps.sh

# Open in Xcode
open VaulType.xcodeproj

# Build and run (⌘R)
```

> See the full [Setup Guide](docs/getting-started/SETUP_GUIDE.md) for prerequisites and detailed instructions.

## Processing Modes

VaulType's dual AI pipeline gives you six modes for different use cases:

| Mode | What It Does | Best For |
|------|-------------|----------|
| **Raw** | No LLM processing — inject speech exactly as recognized | Quick notes, real-time chat |
| **Clean** | Fix spelling, grammar, punctuation, capitalization | Emails, messages, documents |
| **Structure** | Format as bullet lists, numbered steps, or tables | Meeting notes, outlines |
| **Prompt** | Reformat speech into clear, well-structured AI prompts | Claude, ChatGPT, LLM tools |
| **Code** | Format as code comments, commit messages, docstrings | Development workflows |
| **Custom** | User-defined prompt templates | Anything you need |

## Project Structure

```
VaulType/
├── VaulType/                    # Main app target
│   ├── App/                     # App entry point, menu bar
│   ├── Views/                   # SwiftUI views (settings, overlay)
│   ├── Services/                # Core services
│   │   ├── AudioCaptureService  # Microphone + AVAudioEngine
│   │   ├── WhisperService       # whisper.cpp Swift wrapper
│   │   ├── LLMService           # llama.cpp Swift wrapper
│   │   ├── TextInjectionService # CGEvent / clipboard injection
│   │   ├── CommandParser        # Voice command parsing
│   │   └── HotkeyManager       # Global hotkey registration
│   ├── Models/                  # SwiftData models
│   ├── Utilities/               # Helpers, extensions
│   └── Resources/               # Assets, prompt templates
├── WhisperKit/                  # whisper.cpp bridging module
├── LlamaKit/                   # llama.cpp bridging module
├── VaulTypeTests/               # Unit tests
├── VaulTypeUITests/             # UI tests
├── scripts/                     # Build scripts
└── docs/                        # Documentation
```

## Screenshots

<p align="center">
  <img src="assets/screenshots/history.png" width="270" alt="Dictation History">
  &nbsp;&nbsp;
  <img src="assets/screenshots/models.png" width="270" alt="Model Management">
  &nbsp;&nbsp;
  <img src="assets/screenshots/menubar.png" width="270" alt="Menu Bar">
</p>

## Why VaulType?

- **Zero cloud, by architecture** — there are no cloud features to opt into. Speech recognition and LLM processing run entirely on your Mac; the only network requests are optional model downloads.
- **Free and open source** — GPL-3.0. No tiers, no subscriptions, no lifetime licenses. Read the code, audit it, or build it yourself.
- **Both AI engines built in** — whisper.cpp and llama.cpp ship inside the app with Metal GPU acceleration. No separate installs, accounts, or local server setups.
- **Six processing modes** — Raw, Clean, Structure, Prompt, Code, and Custom, with app-aware context that picks the right mode per app.
- **Voice commands** — launch and switch apps, run Shortcuts, and define custom aliases by voice; the direct version adds window management, volume, and system controls.
- **Native menu bar app** — Swift/SwiftUI for macOS 14+, hotkey-driven (including fn/Globe), out of your way until you need it.

## App Store vs. Direct Download

Both versions share the same on-device Whisper + LLM pipeline, six processing modes, dictation history, custom vocabulary, app profiles, and hotkeys (including fn/Globe). They differ where App Store sandbox rules apply:

| | Direct Download (DMG / Homebrew) | Mac App Store |
|---|---|---|
| Text delivery | Types at your cursor (CGEvent), clipboard fallback | Copies to clipboard — HUD prompts you to press ⌘V |
| Voice commands | Full set: apps, windows, volume, brightness, screenshots, system toggles | Launch/switch apps, run Shortcuts, custom aliases |
| Global shortcut aliases | Yes (voice-triggered keystrokes) | — |
| Plugins | Yes | — |
| Battery-aware throttling | Yes (IOKit) | — |
| Updates | Sparkle (in-app) | App Store |
| Sandboxed | No (Developer ID, notarized) | Yes |

If you want dictation that types directly at your cursor and full system voice control, use the direct download. If you prefer App Store installs and updates, the App Store version covers the core dictation experience.

## Documentation

### Getting Started
- [Quick Start Guide](docs/getting-started/QUICK_START.md) — Up and running in 5 minutes
- [Setup Guide](docs/getting-started/SETUP_GUIDE.md) — Full development environment setup
- [Development Guide](docs/getting-started/DEVELOPMENT_GUIDE.md) — Contributing and extending VaulType

### Architecture
- [Architecture](docs/architecture/ARCHITECTURE.md) — System design and component breakdown
- [Tech Stack](docs/architecture/TECH_STACK.md) — Technology choices and rationale
- [Database Schema](docs/architecture/DATABASE_SCHEMA.md) — SwiftData models and relationships

### Features
- [Speech Recognition](docs/features/SPEECH_RECOGNITION.md) — whisper.cpp integration
- [LLM Processing](docs/features/LLM_PROCESSING.md) — llama.cpp and processing modes
- [Text Injection](docs/features/TEXT_INJECTION.md) — How text reaches your cursor
- [Voice Commands](docs/features/VOICE_COMMANDS.md) — System control via voice
- [Model Management](docs/features/MODEL_MANAGEMENT.md) — Downloading and managing AI models
- [Permissions](docs/features/PERMISSIONS.md) — macOS permissions guide

### Operations
- [Deployment Guide](docs/deployment/DEPLOYMENT_GUIDE.md) — Building and distributing releases
- [CI/CD](docs/deployment/CI_CD.md) — GitHub Actions pipelines
- [Monitoring & Logging](docs/operations/MONITORING_LOGGING.md) — Diagnostics and debugging
- [Troubleshooting](docs/operations/TROUBLESHOOTING.md) — Common issues and solutions

### Reference
- [FAQ](docs/reference/FAQ.md) — Frequently asked questions
- [Roadmap](docs/reference/ROADMAP.md) — Development phases and future plans
- [Performance Optimization](docs/reference/PERFORMANCE_OPTIMIZATION.md) — Tuning for speed and efficiency
- [API Documentation](docs/api/API_DOCUMENTATION.md) — Internal Swift APIs

## Contributing

We welcome contributions! See [CONTRIBUTING.md](docs/contributing/CONTRIBUTING.md) for guidelines.

```bash
# Fork and clone
git clone https://github.com/YOUR_USERNAME/vaultype.git

# Create a feature branch
git checkout -b feature/your-feature

# Make changes and test
xcodebuild test -scheme VaulType

# Submit a pull request
```

## License

VaulType is licensed under the [GNU General Public License v3.0](LICENSE).

Third-party components:
- [whisper.cpp](https://github.com/ggerganov/whisper.cpp) — MIT License
- [llama.cpp](https://github.com/ggerganov/llama.cpp) — MIT License
- [Sparkle](https://github.com/sparkle-project/Sparkle) — MIT License

See [Legal Compliance](docs/security/LEGAL_COMPLIANCE.md) for full attribution and licensing details.

---

<p align="center">
  <strong>VaulType</strong> — Privacy-first dictation for macOS.<br>
  Your voice. Your Mac. No cloud required.
</p>
