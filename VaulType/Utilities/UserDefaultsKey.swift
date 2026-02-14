import Foundation

// MARK: - UserDefaults Key Registry

/// Centralized registry of all UserDefaults keys used by VaulType.
///
/// All keys use the `com.vaultype` prefix to avoid collisions with other
/// defaults domains. These keys store lightweight, non-sensitive state
/// that does not require SwiftData or Keychain.
enum UserDefaultsKey {
    // MARK: - Onboarding

    static let hasCompletedOnboarding = "com.vaultype.hasCompletedOnboarding"
    static let onboardingVersion = "com.vaultype.onboardingVersion"

    // MARK: - Feature Flags

    static let experimentalFeaturesEnabled = "com.vaultype.experimentalFeaturesEnabled"
    static let betaUpdatesEnabled = "com.vaultype.betaUpdatesEnabled"

    // MARK: - Window State

    static let settingsWindowFrame = "com.vaultype.settingsWindowFrame"
    static let historyWindowFrame = "com.vaultype.historyWindowFrame"
    static let lastActiveSettingsTab = "com.vaultype.lastActiveSettingsTab"

    // MARK: - Cache & Timestamps

    static let lastModelRegistryUpdate = "com.vaultype.lastModelRegistryUpdate"
    static let lastHistoryCleanup = "com.vaultype.lastHistoryCleanup"
    static let lastVocabularySync = "com.vaultype.lastVocabularySync"

    // MARK: - Usage State

    static let totalDictationCount = "com.vaultype.totalDictationCount"
    static let totalAudioDuration = "com.vaultype.totalAudioDuration"
    static let lastUsedLanguage = "com.vaultype.lastUsedLanguage"
    static let lastUsedMode = "com.vaultype.lastUsedMode"

    // MARK: - Permissions

    static let hasRequestedAccessibility = "com.vaultype.hasRequestedAccessibility"
    static let hasRequestedMicrophone = "com.vaultype.hasRequestedMicrophone"

    // MARK: - UI State

    static let menuBarIconStyle = "com.vaultype.menuBarIconStyle"
    static let recordingIndicatorPosition = "com.vaultype.recordingIndicatorPosition"
    static let historySearchScope = "com.vaultype.historySearchScope"
}

// MARK: - Type-Safe Property Wrapper

/// Property wrapper for type-safe UserDefaults access.
///
/// Usage:
/// ```swift
/// @AppDefault(UserDefaultsKey.hasCompletedOnboarding, defaultValue: false)
/// var hasCompletedOnboarding: Bool
/// ```
@propertyWrapper
struct AppDefault<Value> {
    let key: String
    let defaultValue: Value
    let defaults: UserDefaults

    init(
        _ key: String,
        defaultValue: Value,
        defaults: UserDefaults = .standard
    ) {
        self.key = key
        self.defaultValue = defaultValue
        self.defaults = defaults
    }

    var wrappedValue: Value {
        get {
            defaults.object(forKey: key) as? Value ?? defaultValue
        }
        set {
            defaults.set(newValue, forKey: key)
        }
    }
}
