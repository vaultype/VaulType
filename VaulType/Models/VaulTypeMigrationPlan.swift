import Foundation
import SwiftData

// MARK: - Schema Versions

enum VaulTypeSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            DictationEntry.self,
            PromptTemplate.self,
            AppProfile.self,
            VocabularyEntry.self,
            UserSettings.self,
            ModelInfo.self
        ]
    }
}

// MARK: - Migration Plan

enum VaulTypeMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [
            VaulTypeSchemaV1.self
        ]
    }

    static var stages: [MigrationStage] {
        []
    }
}
