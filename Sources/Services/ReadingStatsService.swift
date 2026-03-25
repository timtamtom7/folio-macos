import Foundation
import SQLite

final class ReadingStatsService {
    private var db: Connection? { DatabaseManager.shared.getConnection() }

    func startSession(articleId: UUID) -> UUID {
        let session = ReadingSession(articleId: articleId)
        saveSession(session)
        return session.id
    }

    func endSession(sessionId: UUID, completed: Bool) {
        guard let db = db else { return }

        let sessions = Table("reading_sessions")
        let id = SQLite.Expression<String>("id")
        let completedCol = SQLite.Expression<Bool>("completed_reading")
        let durationCol = SQLite.Expression<Int>("duration_seconds")

        let formatter = ISO8601DateFormatter()

        do {
            if let row = try db.pluck(sessions.filter(id == sessionId.uuidString)) {
                let started = formatter.date(from: row[SQLite.Expression<String>("started_at")]) ?? Date()
                let duration = Int(Date().timeIntervalSince(started))
                try db.run(sessions.filter(id == sessionId.uuidString).update(
                    completedCol <- completed,
                    durationCol <- duration
                ))
            }
        } catch {
            print("Error ending session: \(error)")
        }
    }

    private func saveSession(_ session: ReadingSession) {
        guard let db = db else { return }

        let sessions = Table("reading_sessions")
        let id = SQLite.Expression<String>("id")
        let articleId = SQLite.Expression<String>("article_id")
        let startedAt = SQLite.Expression<String>("started_at")
        let durationCol = SQLite.Expression<Int>("duration_seconds")
        let completedCol = SQLite.Expression<Bool>("completed_reading")

        let formatter = ISO8601DateFormatter()

        do {
            try db.run(sessions.insert(
                id <- session.id.uuidString,
                articleId <- session.articleId.uuidString,
                startedAt <- formatter.string(from: session.startedAt),
                durationCol <- session.durationSeconds,
                completedCol <- session.completedReading
            ))
        } catch {
            print("Error saving session: \(error)")
        }
    }

    func getArticlesReadThisWeek() -> Int {
        guard let db = db else { return 0 }

        let sessions = Table("reading_sessions")
        let startedAt = SQLite.Expression<String>("started_at")
        let completedCol = SQLite.Expression<Bool>("completed_reading")

        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let formatter = ISO8601DateFormatter()

        do {
            return try db.scalar(sessions.filter(
                startedAt >= formatter.string(from: weekAgo) && completedCol == true
            ).count)
        } catch {
            return 0
        }
    }

    func getTotalReadingTime() -> Int {
        guard let db = db else { return 0 }

        let sessions = Table("reading_sessions")
        let durationCol = SQLite.Expression<Int>("duration_seconds")

        do {
            return try db.scalar(sessions.select(durationCol.sum)) ?? 0
        } catch {
            return 0
        }
    }
}
