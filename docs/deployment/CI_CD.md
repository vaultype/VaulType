Last Updated: 2026-02-13

# CI/CD Pipeline

> GitHub Actions workflows for building, testing, signing, notarizing, and releasing VaulType.

## Table of Contents

- [Overview](#overview)
- [Workflow Architecture](#workflow-architecture)
- [Build Workflow](#build-workflow)
- [Test Workflow](#test-workflow)
- [Release Pipeline](#release-pipeline)
- [Code Signing in CI](#code-signing-in-ci)
- [Notarization Automation](#notarization-automation)
- [Sparkle Appcast Update](#sparkle-appcast-update)
- [Homebrew Cask Automation](#homebrew-cask-automation)
- [Nightly Builds](#nightly-builds)
- [Secrets Management](#secrets-management)
- [Next Steps](#next-steps)

---

## Overview

VaulType uses GitHub Actions for all CI/CD operations. Since VaulType is a native macOS application, all builds run on macOS runners with Xcode.

```
┌──────────────────────────────────────────────────────────────┐
│                     CI/CD Pipeline Overview                    │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  Push/PR to main ──► Build ──► Test ──► Lint                 │
│                                                               │
│  Tag v* ──► Build ──► Sign ──► Notarize ──► DMG ──► Release │
│                  │                                  │         │
│                  └──► Sparkle Appcast Update ────────┘         │
│                  └──► Homebrew Cask PR ──────────────┘         │
│                                                               │
│  Schedule (nightly) ──► Build ──► Test ──► Report             │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

### Runners

| Workflow | Runner | Reason |
|----------|--------|--------|
| Build & Test | `macos-14` (Apple Silicon) | Native macOS build, Metal support |
| Release | `macos-14` | Code signing, notarization |
| Lint | `macos-14` | SwiftLint requires macOS |

---

## Workflow Architecture

### File Structure

```
.github/
├── workflows/
│   ├── build.yml          # Build on push/PR
│   ├── test.yml           # Run tests on push/PR
│   ├── release.yml        # Full release pipeline on tag
│   ├── nightly.yml        # Nightly build and test
│   └── homebrew-update.yml # Homebrew Cask PR on release
├── actions/
│   ├── setup-xcode/       # Composite action: install Xcode + deps
│   └── sign-and-notarize/ # Composite action: code sign + notarize
└── CODEOWNERS
```

---

## Build Workflow

Triggered on every push and pull request to `main`.

```yaml
# .github/workflows/build.yml
name: Build

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

concurrency:
  group: build-${{ github.ref }}
  cancel-in-progress: true

jobs:
  build:
    name: Build VaulType
    runs-on: macos-14

    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          submodules: recursive

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.4.app

      - name: Install Dependencies
        run: |
          brew install cmake create-dmg swiftlint
          ./scripts/build-deps.sh

      - name: Build
        run: |
          xcodebuild build \
            -project VaulType.xcodeproj \
            -scheme VaulType \
            -configuration Debug \
            -destination "platform=macOS,arch=arm64" \
            CODE_SIGN_IDENTITY="" \
            CODE_SIGNING_REQUIRED=NO \
            | xcpretty

      - name: SwiftLint
        run: swiftlint lint --strict --reporter github-actions-logging

      - name: Upload Build Artifact
        uses: actions/upload-artifact@v4
        with:
          name: VaulType-Debug
          path: build/Debug/VaulType.app
          retention-days: 7
```

---

## Test Workflow

```yaml
# .github/workflows/test.yml
name: Test

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  unit-tests:
    name: Unit Tests
    runs-on: macos-14

    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          submodules: recursive

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.4.app

      - name: Build Dependencies
        run: ./scripts/build-deps.sh

      - name: Download Test Models
        run: |
          # Download tiny Whisper model for integration tests
          ./scripts/download-model.sh whisper-tiny test-models/

      - name: Run Unit Tests
        run: |
          xcodebuild test \
            -project VaulType.xcodeproj \
            -scheme VaulType \
            -destination "platform=macOS,arch=arm64" \
            -testPlan UnitTests \
            -resultBundlePath TestResults/unit.xcresult \
            CODE_SIGN_IDENTITY="" \
            CODE_SIGNING_REQUIRED=NO \
            | xcpretty --report junit

      - name: Run Integration Tests
        run: |
          xcodebuild test \
            -project VaulType.xcodeproj \
            -scheme VaulType \
            -destination "platform=macOS,arch=arm64" \
            -testPlan IntegrationTests \
            -resultBundlePath TestResults/integration.xcresult \
            CODE_SIGN_IDENTITY="" \
            CODE_SIGNING_REQUIRED=NO \
            | xcpretty --report junit

      - name: Publish Test Results
        uses: EnricoMi/publish-unit-test-result-action/macos@v2
        if: always()
        with:
          files: build/reports/*.xml

      - name: Upload Test Results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: test-results
          path: TestResults/
          retention-days: 30

  ui-tests:
    name: UI Tests
    runs-on: macos-14

    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          submodules: recursive

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.4.app

      - name: Build Dependencies
        run: ./scripts/build-deps.sh

      - name: Run UI Tests
        run: |
          xcodebuild test \
            -project VaulType.xcodeproj \
            -scheme VaulTypeUITests \
            -destination "platform=macOS,arch=arm64" \
            -resultBundlePath TestResults/ui.xcresult \
            CODE_SIGN_IDENTITY="" \
            CODE_SIGNING_REQUIRED=NO \
            | xcpretty

      - name: Upload Screenshots
        uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: ui-test-screenshots
          path: TestResults/ui.xcresult/Attachments/
```

### Build Matrix

For testing across macOS versions (when Apple Silicon runners support multiple OS versions):

```yaml
strategy:
  matrix:
    xcode: ['15.2', '15.4', '16.0']
    include:
      - xcode: '15.2'
        macos: 'macos-14'
      - xcode: '15.4'
        macos: 'macos-14'
      - xcode: '16.0'
        macos: 'macos-15'
```

---

## Release Pipeline

Triggered when a version tag is pushed.

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

permissions:
  contents: write

jobs:
  release:
    name: Build & Release
    runs-on: macos-14
    environment: production

    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          submodules: recursive

      - name: Extract Version
        id: version
        run: echo "version=${GITHUB_REF_NAME#v}" >> "$GITHUB_OUTPUT"

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.4.app

      - name: Install Dependencies
        run: |
          brew install cmake create-dmg
          ./scripts/build-deps.sh

      # --- Code Signing Setup ---
      - name: Install Signing Certificate
        env:
          CERTIFICATE_BASE64: ${{ secrets.DEVELOPER_ID_CERTIFICATE_BASE64 }}
          CERTIFICATE_PASSWORD: ${{ secrets.DEVELOPER_ID_CERTIFICATE_PASSWORD }}
          KEYCHAIN_PASSWORD: ${{ secrets.KEYCHAIN_PASSWORD }}
        run: |
          # Create temporary keychain
          KEYCHAIN_PATH="$RUNNER_TEMP/signing.keychain-db"
          security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"
          security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
          security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_PATH"

          # Import certificate
          CERT_PATH="$RUNNER_TEMP/certificate.p12"
          echo -n "$CERTIFICATE_BASE64" | base64 --decode -o "$CERT_PATH"
          security import "$CERT_PATH" \
            -P "$CERTIFICATE_PASSWORD" \
            -A -t cert -f pkcs12 \
            -k "$KEYCHAIN_PATH"

          # Set keychain search list
          security list-keychain -d user -s "$KEYCHAIN_PATH"

      # --- Build ---
      - name: Archive
        run: |
          xcodebuild archive \
            -project VaulType.xcodeproj \
            -scheme VaulType \
            -configuration Release \
            -archivePath build/VaulType.xcarchive \
            -destination "generic/platform=macOS"

      - name: Export
        run: |
          xcodebuild -exportArchive \
            -archivePath build/VaulType.xcarchive \
            -exportOptionsPlist ExportOptions.plist \
            -exportPath build/export

      # --- DMG ---
      - name: Create DMG
        run: ./scripts/create-dmg.sh "${{ steps.version.outputs.version }}"

      # --- Notarize ---
      - name: Notarize
        env:
          APPLE_ID: ${{ secrets.APPLE_ID }}
          TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
          APP_PASSWORD: ${{ secrets.APPLE_APP_PASSWORD }}
        run: |
          xcrun notarytool submit \
            "build/VaulType-${{ steps.version.outputs.version }}-universal.dmg" \
            --apple-id "$APPLE_ID" \
            --team-id "$TEAM_ID" \
            --password "$APP_PASSWORD" \
            --wait --timeout 30m

          xcrun stapler staple \
            "build/VaulType-${{ steps.version.outputs.version }}-universal.dmg"

      # --- Compute Checksums ---
      - name: Compute SHA256
        id: checksum
        run: |
          DMG="build/VaulType-${{ steps.version.outputs.version }}-universal.dmg"
          SHA=$(shasum -a 256 "$DMG" | awk '{print $1}')
          echo "sha256=$SHA" >> "$GITHUB_OUTPUT"
          echo "SHA256: $SHA"

      # --- GitHub Release ---
      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          draft: true
          generate_release_notes: true
          files: |
            build/VaulType-${{ steps.version.outputs.version }}-universal.dmg
          body: |
            ## VaulType ${{ github.ref_name }}

            ### Installation
            - **Homebrew:** `brew install --cask vaultype`
            - **DMG:** Download from the assets below

            ### Checksums
            ```
            SHA256: ${{ steps.checksum.outputs.sha256 }}
            ```

            ### System Requirements
            - macOS 14.0 (Sonoma) or later
            - Apple Silicon recommended

      # --- Update Sparkle Appcast ---
      - name: Update Appcast
        env:
          SPARKLE_ED_KEY: ${{ secrets.SPARKLE_ED_PRIVATE_KEY }}
        run: |
          DMG="build/VaulType-${{ steps.version.outputs.version }}-universal.dmg"
          SIZE=$(stat -f%z "$DMG")

          # Sign with Sparkle EdDSA
          SIGNATURE=$(./vendor/Sparkle/bin/sign_update "$DMG" -f "$SPARKLE_ED_KEY")

          # Generate appcast entry (script updates appcast.xml)
          ./scripts/update-appcast.sh \
            "${{ steps.version.outputs.version }}" \
            "$SIZE" \
            "$SIGNATURE" \
            "${{ steps.checksum.outputs.sha256 }}"

      # --- Cleanup ---
      - name: Cleanup Keychain
        if: always()
        run: security delete-keychain "$RUNNER_TEMP/signing.keychain-db" || true
```

---

## Code Signing in CI

### Certificate Management

```
┌─────────────────────────────────────────────────────────┐
│                Certificate Flow in CI                     │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Developer ID Certificate (.p12)                         │
│      │                                                   │
│      ▼ Base64 encode                                     │
│  DEVELOPER_ID_CERTIFICATE_BASE64 (GitHub Secret)         │
│      │                                                   │
│      ▼ Decode in CI                                      │
│  Temporary Keychain ──► codesign ──► Signed App          │
│      │                                                   │
│      ▼ Cleanup                                           │
│  Delete Temporary Keychain                               │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Exporting Your Certificate

```bash
# Export from Keychain Access as .p12 file, then:
base64 -i DeveloperIDApplication.p12 -o cert.b64

# Add cert.b64 contents as GitHub secret: DEVELOPER_ID_CERTIFICATE_BASE64
# Add the .p12 password as: DEVELOPER_ID_CERTIFICATE_PASSWORD
```

> 🔒 **Security Note:** Use GitHub Environments with required reviewers for the `production` environment to protect signing secrets.

---

## Notarization Automation

### Timeout Handling

Notarization can take 5-30 minutes. The `--wait --timeout 30m` flag handles this:

```yaml
- name: Notarize with Retry
  env:
    APPLE_ID: ${{ secrets.APPLE_ID }}
    TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
    APP_PASSWORD: ${{ secrets.APPLE_APP_PASSWORD }}
  run: |
    DMG="build/VaulType-${VERSION}-universal.dmg"

    # Submit and wait
    RESULT=$(xcrun notarytool submit "$DMG" \
      --apple-id "$APPLE_ID" \
      --team-id "$TEAM_ID" \
      --password "$APP_PASSWORD" \
      --wait --timeout 30m 2>&1)

    echo "$RESULT"

    # Check for success
    if echo "$RESULT" | grep -q "status: Accepted"; then
      echo "Notarization succeeded!"
      xcrun stapler staple "$DMG"
    else
      echo "Notarization failed. Fetching log..."
      SUBMISSION_ID=$(echo "$RESULT" | grep "id:" | head -1 | awk '{print $2}')
      xcrun notarytool log "$SUBMISSION_ID" \
        --apple-id "$APPLE_ID" \
        --team-id "$TEAM_ID" \
        --password "$APP_PASSWORD"
      exit 1
    fi
```

---

## Sparkle Appcast Update

### Appcast Update Script

```bash
#!/bin/bash
# scripts/update-appcast.sh

VERSION="$1"
SIZE="$2"
SIGNATURE="$3"
SHA256="$4"
DATE=$(date -u +"%a, %d %b %Y %H:%M:%S %z")

ITEM=$(cat <<EOF
    <item>
      <title>Version ${VERSION}</title>
      <pubDate>${DATE}</pubDate>
      <sparkle:version>${VERSION//./}</sparkle:version>
      <sparkle:shortVersionString>${VERSION}</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <description><![CDATA[
        <p>See release notes at
        https://github.com/vaultype/vaultype/releases/tag/v${VERSION}</p>
      ]]></description>
      <enclosure
        url="https://github.com/vaultype/vaultype/releases/download/v${VERSION}/VaulType-${VERSION}-universal.dmg"
        type="application/octet-stream"
        sparkle:edSignature="${SIGNATURE}"
        length="${SIZE}"
      />
    </item>
EOF
)

# Insert new item at the top of the channel
sed -i '' "/<channel>/a\\
${ITEM}
" appcast.xml

echo "Appcast updated for v${VERSION}"
```

### Deploying the Appcast

Host `appcast.xml` on GitHub Pages or the project website:

```yaml
- name: Deploy Appcast
  uses: peaceiris/actions-gh-pages@v4
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
    publish_dir: ./appcast
    destination_dir: appcast
```

---

## Homebrew Cask Automation

```yaml
# .github/workflows/homebrew-update.yml
name: Update Homebrew Cask

on:
  release:
    types: [published]

jobs:
  update-cask:
    name: Update Homebrew Cask Formula
    runs-on: macos-14

    steps:
      - name: Extract Version and SHA
        id: info
        run: |
          VERSION="${{ github.event.release.tag_name }}"
          VERSION="${VERSION#v}"
          echo "version=$VERSION" >> "$GITHUB_OUTPUT"

          # Download DMG and compute SHA
          DMG_URL="https://github.com/${{ github.repository }}/releases/download/${{ github.event.release.tag_name }}/VaulType-${VERSION}-universal.dmg"
          curl -L -o /tmp/vaultype.dmg "$DMG_URL"
          SHA=$(shasum -a 256 /tmp/vaultype.dmg | awk '{print $1}')
          echo "sha256=$SHA" >> "$GITHUB_OUTPUT"

      - name: Update Homebrew Cask
        uses: macauley/action-homebrew-bump-cask@v1
        with:
          token: ${{ secrets.HOMEBREW_GITHUB_TOKEN }}
          cask: vaultype
          version: ${{ steps.info.outputs.version }}
          sha256: ${{ steps.info.outputs.sha256 }}
          url: "https://github.com/${{ github.repository }}/releases/download/${{ github.event.release.tag_name }}/VaulType-${{ steps.info.outputs.version }}-universal.dmg"
```

---

## Nightly Builds

```yaml
# .github/workflows/nightly.yml
name: Nightly Build

on:
  schedule:
    - cron: '0 4 * * *'  # 4 AM UTC daily
  workflow_dispatch:

jobs:
  nightly:
    name: Nightly Build & Test
    runs-on: macos-14

    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          submodules: recursive

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.4.app

      - name: Build Dependencies
        run: ./scripts/build-deps.sh

      - name: Build Release
        run: |
          xcodebuild build \
            -project VaulType.xcodeproj \
            -scheme VaulType \
            -configuration Release \
            -destination "platform=macOS,arch=arm64" \
            CODE_SIGN_IDENTITY="" \
            CODE_SIGNING_REQUIRED=NO

      - name: Run All Tests
        run: |
          xcodebuild test \
            -project VaulType.xcodeproj \
            -scheme VaulType \
            -destination "platform=macOS,arch=arm64" \
            CODE_SIGN_IDENTITY="" \
            CODE_SIGNING_REQUIRED=NO \
            | xcpretty

      - name: Notify on Failure
        if: failure()
        uses: slackapi/slack-github-action@v1
        with:
          payload: |
            {
              "text": "VaulType nightly build failed! See: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

---

## Secrets Management

### Required GitHub Secrets

| Secret | Description | Used In |
|--------|-------------|---------|
| `DEVELOPER_ID_CERTIFICATE_BASE64` | Base64 Developer ID certificate (.p12) | Release |
| `DEVELOPER_ID_CERTIFICATE_PASSWORD` | Password for .p12 file | Release |
| `KEYCHAIN_PASSWORD` | Temporary keychain password | Release |
| `APPLE_ID` | Apple ID email for notarization | Release |
| `APPLE_TEAM_ID` | Apple Developer Team ID | Release |
| `APPLE_APP_PASSWORD` | App-specific password for notarization | Release |
| `SPARKLE_ED_PRIVATE_KEY` | Sparkle EdDSA signing key | Release |
| `HOMEBREW_GITHUB_TOKEN` | PAT with `public_repo` scope | Homebrew |
| `SLACK_WEBHOOK_URL` | Slack webhook for notifications | Nightly |

### Environment Protection

```yaml
# In release.yml, protect with environment approval:
jobs:
  release:
    environment: production  # Requires manual approval
```

Configure in GitHub Settings > Environments > `production`:
- Required reviewers: at least 1
- Deployment branches: only `main` and `v*` tags

> 🔒 **Security Note:** Rotate secrets periodically. Apple app-specific passwords expire and may need regeneration.

---

## Next Steps

- [Deployment Guide](DEPLOYMENT_GUIDE.md) — Manual build and release process
- [Testing](../testing/TESTING.md) — Test strategy and execution
- [Monitoring & Logging](../operations/MONITORING_LOGGING.md) — Production diagnostics
- [Security](../security/SECURITY.md) — Code signing and security practices
