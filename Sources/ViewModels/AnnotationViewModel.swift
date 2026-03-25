import Foundation
import Combine

final class AnnotationViewModel: ObservableObject {
    @Published var annotations: [Annotation] = []
    @Published var selectedText: String?

    private let annotationService = AnnotationService()

    func loadAnnotations(for article: Article) {
        annotations = annotationService.getAnnotations(forArticle: article.id)
    }

    func addAnnotation(articleId: UUID, content: String, highlightColor: String?, selectedText: String? = nil) {
        let annotation = Annotation(
            articleId: articleId,
            content: content,
            highlightColor: highlightColor,
            selectedText: selectedText ?? self.selectedText
        )
        annotationService.saveAnnotation(annotation)
        self.selectedText = nil
        if let article = annotations.first {
            loadAnnotations(for: Article(id: articleId, feedId: UUID(), title: "", url: URL(string: "https://example.com")!, publishedAt: Date()))
        }
        // Reload from storage
        let updated = annotationService.getAnnotations(forArticle: articleId)
        annotations = updated
    }

    func deleteAnnotation(_ annotation: Annotation) {
        annotationService.deleteAnnotation(id: annotation.id)
        annotations.removeAll { $0.id == annotation.id }
    }
}
