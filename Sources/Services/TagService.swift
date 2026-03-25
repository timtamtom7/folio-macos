import Foundation

final class TagService {
    static let shared = TagService()
    
    private let tagsKey = "article_tags"
    private let tagDefinitionsKey = "tag_definitions"
    
    private init() {}
    
    // MARK: - Tag Definitions
    
    func getAllTags() -> [Tag] {
        guard let data = UserDefaults.standard.data(forKey: tagDefinitionsKey),
              let tags = try? JSONDecoder().decode([Tag].self, from: data) else {
            return []
        }
        return tags
    }
    
    func saveTag(_ tag: Tag) {
        var tags = getAllTags()
        if let index = tags.firstIndex(where: { $0.id == tag.id }) {
            tags[index] = tag
        } else {
            tags.append(tag)
        }
        saveTags(tags)
    }
    
    func deleteTag(id: UUID) {
        var tags = getAllTags()
        tags.removeAll { $0.id == id }
        saveTags(tags)
        
        // Also remove all article-tag associations
        var articleTags = getAllArticleTags()
        articleTags.removeAll { $0.tagId == id }
        saveArticleTags(articleTags)
    }
    
    private func saveTags(_ tags: [Tag]) {
        if let data = try? JSONEncoder().encode(tags) {
            UserDefaults.standard.set(data, forKey: tagDefinitionsKey)
        }
    }
    
    // MARK: - Article Tags
    
    func getAllArticleTags() -> [ArticleTag] {
        guard let data = UserDefaults.standard.data(forKey: tagsKey),
              let articleTags = try? JSONDecoder().decode([ArticleTag].self, from: data) else {
            return []
        }
        return articleTags
    }
    
    func getTags(forArticle articleId: UUID) -> [Tag] {
        let articleTags = getAllArticleTags().filter { $0.articleId == articleId }
        let allTags = getAllTags()
        return articleTags.compactMap { at in
            allTags.first { $0.id == at.tagId }
        }
    }
    
    func getArticles(withTag tagId: UUID) -> [UUID] {
        return getAllArticleTags().filter { $0.tagId == tagId }.map { $0.articleId }
    }
    
    func addTag(_ tagId: UUID, toArticle articleId: UUID) {
        var articleTags = getAllArticleTags()
        // Don't add duplicates
        if !articleTags.contains(where: { $0.articleId == articleId && $0.tagId == tagId }) {
            articleTags.append(ArticleTag(articleId: articleId, tagId: tagId))
            saveArticleTags(articleTags)
        }
    }
    
    func removeTag(_ tagId: UUID, fromArticle articleId: UUID) {
        var articleTags = getAllArticleTags()
        articleTags.removeAll { $0.articleId == articleId && $0.tagId == tagId }
        saveArticleTags(articleTags)
    }
    
    func removeAllTags(fromArticle articleId: UUID) {
        var articleTags = getAllArticleTags()
        articleTags.removeAll { $0.articleId == articleId }
        saveArticleTags(articleTags)
    }
    
    private func saveArticleTags(_ articleTags: [ArticleTag]) {
        if let data = try? JSONEncoder().encode(articleTags) {
            UserDefaults.standard.set(data, forKey: tagsKey)
        }
    }
}
