import Foundation
import SwiftData

/// The persisted shape of the database, pinned to a version.
///
/// Without this, SwiftData infers an unversioned schema and attempts a
/// lightweight migration on every launch. Additive changes survive that;
/// renaming a property, changing its type, or making an optional non-optional
/// does not — the store then fails to open, taking real progression with it.
///
/// Adding a model or an optional property: extend V1 in place.
/// Anything structural: add `LifeRankSchemaV2`, append it to `schemas`, and add
/// a `MigrationStage` describing the change.
enum LifeRankSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            ActivityRecord.self,
            XPEventRecord.self,
            CharacterRecord.self,
            ObjectiveCompletionRecord.self,
            IgnoredWorkoutRecord.self,
        ]
    }
}

enum LifeRankMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [LifeRankSchemaV1.self] }

    /// Empty until a second version exists.
    static var stages: [MigrationStage] { [] }
}

extension ModelContainer {
    /// The app's live store. A failure here means the database could not be
    /// opened or migrated — the data on disk is untouched, so the recovery is
    /// to reinstall and restore a backup (DESIGN.md §30) rather than to carry
    /// on against an empty database and quietly write over the gap.
    static func lifeRank() -> ModelContainer {
        let schema = Schema(versionedSchema: LifeRankSchemaV1.self)

        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: LifeRankMigrationPlan.self,
                configurations: ModelConfiguration(schema: schema)
            )
        } catch {
            fatalError(
                """
                LifeRank could not open its database: \(error)

                Your data on disk has not been modified. Reinstall the app and \
                restore your most recent JSON backup.
                """
            )
        }
    }
}
