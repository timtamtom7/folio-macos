import Foundation
import SQLite

final class AnnotationService {
    private var db: Connection? { DatabaseManager.shared.getConnection() }

    func saveAnnotation(_ annotation: Annotation) {
        guard let db = db else { return }

        let annotations = Table("annotations")
        let id = SQLite.Expression<String>("id")
        let articleId = SQLite.Expression<String>("article_id")
        let content = SQLite.Expression<String>("content")
        let highlightColor = SQLite.Expression<String?>("highlight_color")
        let selectedText = SQLite.Expression<String?>("selected_text")
        let createdAt = SQLite.Expression<String>("created_at")
        let updatedAt = SQLite.Expression<String>("updated_at")

        let formatter = ISO8601DateFormatter()

        do {
            try db.run(annotations.insert(or: .replace,
                id <- annotation.id.uuidString,
                articleId <- annotation.articleId.uuidString,
                content <- annotation.content,
                highlightColor <- annotation.highlightColor,
                selectedText <- annotation.selectedText,
                createdAt <- formatter.string(from: annotation.createdAt),
                updatedAt <- formatter.string(from: annotation.updatedAt)
            ))
        } catch {
            print("Error saving annotation: \(error)")
        }
    }

    func getAnnotations(forArticle articleId: UUID) -> [Annotation] {
        guard let db = db else { return [] }

        let annotations = Table("annotations")
        let id = SQLite.Expression<String>("id")
        let fkArticleId = SQLite.Expression<String>("article_id")
        let content = SQLite.Expression<String>("content")
        let highlightColor = SQLite.Expression<String?>("highlight_color")
        let selectedText = SQLite.Expression<String?>("selected_text")
        let createdAt = SQLite.Expression<String>("created_at")
        let updatedAt = SQLite.Expression<String>("updated_at")

        let formatter = ISO8601DateFormatter()

        let query = annotations.filter(fkArticleId == articleId.uuidString).order(createdAt.desc)

        var result: [Annotation] = []
        do {
            for row in try db.prepare(query) {
                let annotation = Annotation(
                    id: UUID(uuidString: row[id]) ?? UUID(),
                    articleId: UUID(uuidString: row[fkArticleId]) ?? UUID(),
                    content: row[content],
                    highlightColor: row[highlightColor],
                    selectedText: row[selectedText],
                    createdAt: formatter.date(from: row[createdAt]) ?? Date(),
                    updatedAt: formatter.date(from: row[updatedAt]) ?? Date()
                )
                result.append(annotation)
            }
        } catch {
            print("Error getting annotations: \(error)")
        }
        return result
    }

    func deleteAnnotation(id: UUID) {
        guard let db = db else { return }

        let annotations = Table("annotations")
        let idCol = SQLite.Expression<String>("id")

        let row = annotations.filter(idCol == id.uuidString)
        do {
            try db.run(row.delete())
        } catch {
            print("Error deleting annotation: \(error)")
        }
    }

    func searchAnnotations(query: String) -> [Annotation] {
        guard let db = db else { return [] }

        let annotations = Table("annotations")
        let id = SQLite.Expression<String>("id")
        let fkArticleId = SQLite.Expression<String>("article_id")
        let content = SQLite.Expression<String>("content")
        let highlightColor = SQLite.Expression<String?>("highlight_color")
        let selectedText = SQLite.Expression<String?>("selected_text")
        let createdAt = SQLite.Expression<String>("created_at")
        let updatedAt = SQLite.Expression<String>("updated_at")

        let formatter = ISO8601DateFormatter()
        let pattern = "%\(query)%"

        let searchQuery = annotations.filter(content.like(pattern) || selectedText.like(pattern))

        var result: [Annotation] = []
        do {
            for row in try db.prepare(searchQuery) {
                let annotation = Annotation(
                    id: UUID(uuidString: row[id]) ?? UUID(),
                    articleId: UUID(uuidString: row[fkArticleId]) ?? UUID(),
                    content: row[content],
                    highlightColor: row[highlightColor],
                    selectedText: row[selectedText],
                    createdAt: formatter.date(from: row[createdAt]) ?? Date(),
                    updatedAt: formatter.date(from: row[updatedAt]) ?? Date()
                )
                result.append(annotation)
            }
        } catch {
            print("Error searching annotations: \(error)")
        }
        return result
    }
}
