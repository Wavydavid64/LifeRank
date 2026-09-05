import Foundation
import SwiftData

/// Exports and restores the whole database as JSON (DESIGN.md §30).
@MainActor
struct BackupService {
    let context: ModelContext

    func makeDocument() throws -> BackupDocument {
        let character = try context.fetch(FetchDescriptor<CharacterRecord>()).first

        return BackupDocument(
            version: BackupDocument.currentVersion,
            exportedAt: .now,
            rank: character?.rank ?? .starting,
            promotedAt: character?.promotedAt,
            activities: try context.fetch(FetchDescriptor<ActivityRecord>())
                .map(\.domain)
                .sorted { $0.date < $1.date },
            xpEvents: try context.fetch(FetchDescriptor<XPEventRecord>())
                .map(\.domain)
                .sorted { $0.date < $1.date },
            manualCompletions: try context.fetch(FetchDescriptor<ObjectiveCompletionRecord>())
                .map(\.objectiveID)
                .sorted(),
            ignoredWorkouts: try context.fetch(FetchDescriptor<IgnoredWorkoutRecord>())
                .map(\.externalIdentifier)
                .sorted(),
            configuration: .current
        )
    }

    func export() throws -> Data {
        try JSONEncoder.backup.encode(makeDocument())
    }

    /// Replaces everything in the database with the contents of the backup.
    /// Destructive by design — a restore is a restore, not a merge, because
    /// merging two XP ledgers would double-count shared history.
    func restore(from data: Data) throws {
        let document = try JSONDecoder.backup.decode(BackupDocument.self, from: data)

        guard document.version <= BackupDocument.currentVersion else {
            throw BackupError.unsupportedVersion(document.version)
        }

        try context.fetch(FetchDescriptor<ActivityRecord>()).forEach(context.delete)
        try context.fetch(FetchDescriptor<XPEventRecord>()).forEach(context.delete)
        try context.fetch(FetchDescriptor<ObjectiveCompletionRecord>()).forEach(context.delete)
        try context.fetch(FetchDescriptor<IgnoredWorkoutRecord>()).forEach(context.delete)
        try context.fetch(FetchDescriptor<CharacterRecord>()).forEach(context.delete)

        for activity in document.activities {
            context.insert(ActivityRecord(activity))
        }
        for event in document.xpEvents {
            context.insert(XPEventRecord(event))
        }
        for objectiveID in document.manualCompletions {
            context.insert(ObjectiveCompletionRecord(objectiveID: objectiveID))
        }
        for identifier in document.ignoredWorkouts {
            context.insert(IgnoredWorkoutRecord(externalIdentifier: identifier))
        }
        context.insert(CharacterRecord(rank: document.rank, promotedAt: document.promotedAt))

        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}
