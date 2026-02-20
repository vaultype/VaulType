# Homebrew Cask formula for VaulType
# To install locally: brew install --cask ./Casks/vaultype.rb
# To submit to homebrew-cask: https://github.com/Homebrew/homebrew-cask/blob/HEAD/CONTRIBUTING.md

cask "vaultype" do
  version "1.0.0"
  sha256 "PLACEHOLDER_SHA256"

  url "https://github.com/vaultype/VaulType/releases/download/v#{version}/VaulType-#{version}.dmg"
  name "VaulType"
  desc "Privacy-first speech-to-text for macOS — runs 100% locally"
  homepage "https://github.com/vaultype/VaulType"

  depends_on macos: ">= :sonoma"
  depends_on arch: :arm64

  app "VaulType.app"

  zap trash: [
    "~/Library/Application Support/VaulType",
    "~/Library/Preferences/com.vaultype.app.plist",
    "~/Library/Caches/com.vaultype.app",
  ]
end
