Last Updated: 2026-02-13

# Frequently Asked Questions

> Common questions about VaulType — privacy, compatibility, features, and troubleshooting.

## Table of Contents

- [General](#general)
- [Privacy & Security](#privacy--security)
- [Hardware & Compatibility](#hardware--compatibility)
- [Features](#features)
- [Models & Performance](#models--performance)
- [Troubleshooting](#troubleshooting)
- [Comparison with Alternatives](#comparison-with-alternatives)
- [Development & Contributing](#development--contributing)
- [Next Steps](#next-steps)

---

## General

### What is VaulType?

VaulType is a privacy-first, macOS-native speech-to-text application that lets you dictate text into any app where your cursor is active. It uses local AI models (whisper.cpp for speech recognition and llama.cpp for text post-processing) — nothing ever leaves your Mac.

### Why is it called VaulType?

The name captures the core philosophy:
- **Vault** — Your voice stays private, never leaving your device
- **Type** — Text appears at your cursor, as if you typed it

### Is VaulType free?

Yes. VaulType is open source under the GPL-3.0 license. It's free to download, use, and modify.

### Should I get the Mac App Store version or the direct download?

Both are free and share the same on-device Whisper + LLM pipeline, processing modes, history, vocabulary, and hotkeys. The differences come from App Store sandbox rules:

- **Direct download (DMG / Homebrew)** — types text directly at your cursor, full voice-command set (windows, volume, brightness, screenshots, system toggles), global shortcut aliases, plugins, battery-aware throttling, Sparkle auto-updates.
- **[Mac App Store](https://apps.apple.com/app/vaultype/id6759566772)** — copies dictated text to the clipboard and shows a "press ⌘V" prompt (sandboxed apps can't type into other apps), voice commands limited to launching/switching apps, running Shortcuts, and custom aliases; updates arrive through the App Store.

If you want text at your cursor and full system voice control, choose the direct download. If you prefer App Store installs and automatic store updates, the App Store version covers the complete core dictation experience.

### What languages does VaulType support?

VaulType supports **90+ languages** through Whisper's multilingual models (small, medium, large-v3), including English, Turkish, Spanish, French, German, Chinese, Japanese, Arabic, and many more. English-only models are also available for faster performance. Language can be auto-detected or manually selected.

### Does VaulType work offline?

**Yes, 100%.** VaulType is designed to work completely offline. All speech recognition and text processing happen locally on your Mac. The only network requests are:
- Model downloads (one-time, optional)
- Auto-update checks via Sparkle (can be disabled)

---

## Privacy & Security

### Is my audio sent to the cloud?

**No, absolutely not.** VaulType processes all audio locally using whisper.cpp. Your voice data never leaves your Mac. There is no cloud component, no API calls, and no telemetry.

### Is my dictation text stored anywhere?

By default, **no**. Text is transcribed, optionally processed by the LLM, and injected at your cursor — then discarded from memory. If you enable Dictation History (opt-in), transcriptions are stored locally in SwiftData on your Mac.

### Does VaulType collect any data?

**No.** VaulType has zero telemetry, zero analytics, and zero data collection by default. If you opt in to crash reporting (Sentry), only crash logs are sent — never audio, text, or usage data.

### Is it safe to use for sensitive work?

Yes. Since everything is local, VaulType is suitable for sensitive work including:
- Legal documents
- Medical notes
- Confidential business communications
- Personal journaling

> 🔒 VaulType cannot inject text into password fields — this is a deliberate security measure.

### What permissions does VaulType need and why?

| Permission | Why |
|-----------|-----|
| **Accessibility** | To inject text into the active app via CGEvent |
| **Microphone** | To capture your voice for speech recognition |
| **Automation** (optional) | For voice commands that control other apps via AppleScript |

See [PERMISSIONS.md](../features/PERMISSIONS.md) for a detailed breakdown.

---

## Hardware & Compatibility

### Which Mac do I need?

VaulType runs on any Mac with **macOS 14.0 (Sonoma)** or later:

- **Apple Silicon (M1/M2/M3/M4)** — Recommended. Metal GPU acceleration makes speech recognition 3-10x faster.
- **Intel Macs** — Supported with CPU-only inference. Use smaller models (tiny, base) for acceptable speed.

### How much RAM do I need?

| Configuration | Minimum RAM |
|--------------|-------------|
| Whisper tiny (Raw mode) | 8 GB |
| Whisper small (Raw mode) | 8 GB |
| Whisper small + LLM 3B | 16 GB |
| Whisper medium + LLM 3B | 16 GB |
| Whisper large-v3 + LLM | 32 GB |

> 💡 **Recommendation:** 16 GB for the best experience with both STT and LLM features.

### How much disk space do models need?

| Model | Size |
|-------|------|
| Whisper tiny | ~75 MB |
| Whisper base | ~142 MB |
| Whisper small | ~466 MB |
| Whisper medium | ~1.5 GB |
| Whisper large-v3 | ~3.0 GB |
| Qwen2.5-3B Q4 | ~2.0 GB |
| Phi-3.5-mini Q4 | ~2.5 GB |

You only need one Whisper model and optionally one LLM. Typical installation: **500 MB to 3 GB**.

### Does it work on macOS Sequoia?

Yes. VaulType is tested on macOS 14 (Sonoma) and macOS 15 (Sequoia).

---

## Features

### Can I use VaulType with Claude Code?

**Yes!** This is one of VaulType's best use cases. Use **Prompt Mode** to dictate into your terminal, and VaulType will automatically format your messy speech into clear, well-structured prompts for Claude Code.

Example: You say *"I want to refactor the authentication module to use JWT tokens instead of sessions and add proper error handling"* and VaulType formats it into a clean, structured prompt before injecting it into the terminal.

### Does it work in Terminal?

**Yes.** VaulType injects text into any macOS app, including Terminal.app, iTerm2, Warp, Alacritty, and Kitty. Use the Clipboard injection method for the best terminal compatibility.

### What are the processing modes?

| Mode | What It Does |
|------|-------------|
| **Raw** | No LLM processing — inject speech exactly as recognized |
| **Clean** | Fix spelling, grammar, punctuation, capitalization |
| **Structure** | Format as bullet lists, numbered steps, or tables |
| **Prompt** | Reformat into clear, well-structured AI prompts |
| **Code** | Format as code comments, commit messages, docstrings |
| **Custom** | Your own prompt templates for any formatting need |

### Can I create custom processing modes?

Yes. VaulType has a full prompt template system. You can:
- Write custom system and user prompts
- Use variables like `{text}`, `{language}`, `{app_name}`, `{context}`
- Import and export templates
- Assign modes to specific hotkeys or apps

### Does VaulType support push-to-talk?

Yes, two modes are available:
- **Push-to-talk** — Hold the hotkey to record, release to process
- **Toggle mode** — Press to start recording, press again to stop

### Can I use different modes for different apps?

Yes. **App-Aware Context** (Phase 3) lets you configure default modes per application. For example:
- Terminal → Prompt Mode
- Mail → Clean Mode
- Notes → Structure Mode
- VS Code → Code Mode

### Does VaulType have voice commands?

Yes (Phase 4). You can:
- Launch and switch between apps: *"Open Safari"*, *"Switch to Terminal"*
- Manage windows: *"Move window to left half"*
- Control system: *"Volume up"*, *"Mute"*, *"Do Not Disturb on"*
- Chain commands: *"Open Terminal and run npm start"*
- Create custom aliases: *"Deploy"* → run your deploy script

---

## Models & Performance

### Which Whisper model should I use?

| Model | Speed | Accuracy | Best For |
|-------|-------|----------|----------|
| **tiny** | Fastest | Good enough | Quick notes, Intel Macs |
| **base** | Fast | Good | General use on Intel |
| **small** | Balanced | Very good | **Recommended for most users** |
| **medium** | Slower | Excellent | Accuracy-critical, long dictation |
| **large-v3** | Slowest | Best | Maximum accuracy, M-series Pro/Max |

> 💡 **Start with `small`** — it's the sweet spot of speed and accuracy for Apple Silicon.

### Which LLM should I use for post-processing?

| Model | Size | Speed | Quality |
|-------|------|-------|---------|
| **Qwen2.5-3B Q4** | 2 GB | Fast | **Recommended** |
| **Phi-3.5-mini Q4** | 2.5 GB | Fast | Great for English |
| **Llama-3.2-3B Q4** | 2 GB | Fast | Good multilingual |

### How fast is transcription?

On Apple Silicon with Metal GPU acceleration:

| Model | 5s Audio | 30s Audio |
|-------|----------|-----------|
| tiny | ~0.3s | ~1.5s |
| base | ~0.5s | ~2.5s |
| small | ~1.0s | ~5s |
| medium | ~3s | ~15s |
| large-v3 | ~8s | ~40s |

*Measured on M1 MacBook Pro. M2/M3 are ~20-40% faster.*

### Can I use Ollama instead of built-in llama.cpp?

Yes. VaulType supports Ollama as an alternative LLM backend via its localhost REST API (port 11434). This is useful if you already have Ollama installed with models downloaded.

Configure in Settings > Advanced > LLM Backend > Ollama.

---

## Troubleshooting

### Text isn't appearing after I dictate

Most common causes:
1. **Accessibility permission not granted** — Check System Settings > Privacy & Security > Accessibility
2. **Cursor not in a text field** — Click into an editable area first
3. **Wrong injection method** — Try switching between CGEvent and Clipboard in Settings > Advanced

See [TROUBLESHOOTING.md](../operations/TROUBLESHOOTING.md) for detailed solutions.

### The app says "No model loaded"

You need to download a Whisper model:
1. Open VaulType Settings > Models
2. Click Download next to a model (recommended: `small`)
3. Wait for the download to complete

### Dictation is slow

Try these in order:
1. Use a smaller model (tiny or base)
2. Ensure Metal GPU is enabled (Settings > Advanced)
3. Close GPU-intensive apps
4. Use push-to-talk for shorter recordings

### VaulType doesn't appear in the menu bar

1. Check if VaulType is running: look in Activity Monitor
2. Relaunch from `/Applications/VaulType.app`
3. Check System Settings > Control Center > Menu Bar Only to ensure it's not hidden

### Audio level meter shows no activity

1. Verify microphone permission is granted
2. Select the correct input device in Settings > Audio
3. Check that the microphone works in Voice Memos

---

## Comparison with Alternatives

### How is VaulType different from Apple's built-in Dictation?

Apple's Dictation is a solid baseline and free with macOS (on-device on Apple Silicon for supported languages). VaulType is built for heavier dictation use: LLM post-processing with six modes (Raw, Clean, Structure, Prompt, Code, Custom), custom vocabulary, dictation history, app-aware mode switching, and voice commands. VaulType is also open source (GPL-3.0) with a zero-cloud architecture — there is no cloud path at all, so nothing can be sent off-device even by accident.

### How does VaulType compare to other dictation apps (MacWhisper, Superwhisper, VoiceInk, …)?

There are several good Whisper-based macOS dictation apps, and their features and pricing change frequently — check their websites for current details rather than relying on third-party comparisons. What sets VaulType apart is the combination of:

- **Fully open source** (GPL-3.0) and free, with no tiers or subscriptions
- **Zero cloud features by design** — speech recognition and LLM processing cannot leave your Mac
- **Both AI engines built in** — whisper.cpp and llama.cpp ship inside the app; no separate installs, accounts, or local server setups
- **Six processing modes** with app-aware context, including developer-focused Code and Prompt modes
- **Voice commands** for launching/switching apps, running Shortcuts, and custom aliases (plus window and system control in the direct version)

---

## Development & Contributing

### How can I contribute?

See [CONTRIBUTING.md](../contributing/CONTRIBUTING.md) for the full guide. The quickest ways to contribute:
- Report bugs via GitHub Issues
- Add new processing modes (create a prompt template + register it)
- Add new voice commands
- Improve documentation
- Test on different hardware and report compatibility

### What's the tech stack?

- **UI:** Swift 5.9+ / SwiftUI / AppKit
- **Speech:** whisper.cpp (C/C++) with Metal acceleration
- **LLM:** llama.cpp (C/C++) with Metal acceleration
- **Audio:** AVAudioEngine
- **Injection:** CGEvent API
- **Storage:** SwiftData
- **Build:** Xcode 15+ / SPM / CMake
- **CI/CD:** GitHub Actions

See [TECH_STACK.md](../architecture/TECH_STACK.md) for detailed rationale.

### What's on the roadmap?

| Phase | Focus | Status |
|-------|-------|--------|
| v0.1.0 | Menu bar + whisper.cpp + text injection | In development |
| v0.2.0 | LLM post-processing modes | Planned |
| v0.3.0 | App-aware context, history, overlay | Planned |
| v0.4.0 | Voice commands | Planned |
| v0.5.0 | Power user features, polish | Planned |
| v1.0 | Feature-complete stable release | Future |

See [ROADMAP.md](ROADMAP.md) for the full roadmap.

### Can I build VaulType from source?

Yes:

```bash
git clone https://github.com/vaultype/vaultype.git
cd vaultype
./scripts/build-deps.sh
open VaulType.xcodeproj
# Build and run (⌘R)
```

See [SETUP_GUIDE.md](../getting-started/SETUP_GUIDE.md) for detailed instructions.

---

## Next Steps

- [Quick Start](../getting-started/QUICK_START.md) — Get up and running in 5 minutes
- [Troubleshooting](../operations/TROUBLESHOOTING.md) — Detailed problem-solving guide
- [Contributing](../contributing/CONTRIBUTING.md) — How to contribute
- [Roadmap](ROADMAP.md) — What's coming next
