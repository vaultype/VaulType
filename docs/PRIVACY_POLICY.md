# Privacy Policy

**Effective Date:** February 23, 2026
**Last Updated:** February 23, 2026

## Overview

VaulType is a privacy-first speech-to-text application for macOS. All processing happens entirely on your device. We do not collect, store, or transmit any personal data.

## Data Collection

**VaulType does not collect any data.** Specifically:

- **No audio data** is transmitted. All speech recognition runs locally using on-device AI models.
- **No transcription data** is sent to any server. Your text stays on your Mac.
- **No analytics or telemetry** are collected. There are no tracking pixels, usage metrics, or crash reporters that phone home.
- **No personal information** is requested, stored, or shared.

## On-Device Processing

VaulType uses locally-running machine learning models (whisper.cpp for speech recognition and llama.cpp for text processing). These models run entirely on your Mac's CPU and GPU. No cloud APIs are involved in the transcription or text processing pipeline.

## Network Usage

VaulType makes network requests only for the following purposes:

- **Model downloads:** Speech recognition and language models are downloaded from Hugging Face CDN (huggingface.co) when you first set up the app or choose to download additional models. Only the model files are downloaded; no user data is sent.
- **Update checks (direct distribution only):** The non-App Store version checks for software updates via Sparkle. This sends a standard HTTP request to fetch the appcast XML file. No personal data is included.

No other network communication occurs during normal use.

## Data Storage

All application data is stored locally on your Mac:

- **Dictation history** is stored in a local SwiftData database under `~/Library/Application Support/VaulType/`.
- **AI models** are stored in `~/Library/Application Support/VaulType/Models/`.
- **User preferences** are stored in standard macOS user defaults.

You can delete all stored data by removing the VaulType application support directory.

## Permissions

VaulType requests the following system permissions:

- **Microphone:** Required to capture speech for transcription. Audio is processed locally and never transmitted.
- **Accessibility / Text Input:** Required to type transcribed text into other applications. This permission is used solely for text injection at your cursor position.

## Third-Party Services

VaulType does not integrate with any third-party analytics, advertising, or data processing services.

## Children's Privacy

VaulType does not knowingly collect any information from children or any other users.

## Changes to This Policy

If we update this privacy policy, the changes will be posted here with an updated effective date.

## Contact

For questions about this privacy policy, please open an issue at:
https://github.com/vaultype/VaulType/issues
