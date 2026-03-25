import Foundation

final class AnalyticsService {
    static let shared = AnalyticsService()
    
    private let analyticsKey = "reading_analytics"
    
    private init() {}
    
    struct DailyAnalytics: Codable {
        let date: Date
        var articlesRead: Int
        var minutesRead: Int
        var feedsVisited: Int
        var streakDay: Int
    }
    
    // MARK: - Record Reading Activity
    
    func recordArticleRead(articleId: UUID) {
        var today = getTodayAnalytics()
        today.articlesRead += 1
        saveAnalytics(today)
        updateStreak()
    }
    
    func recordMinutesRead(_ minutes: Int) {
        var today = getTodayAnalytics()
        today.minutesRead += minutes
        saveAnalytics(today)
    }
    
    func recordFeedVisit(feedId: UUID) {
        var today = getTodayAnalytics()
        if !isFeedVisitedToday(feedId) {
            today.feedsVisited += 1
            markFeedVisitedToday(feedId)
        }
        saveAnalytics(today)
    }
    
    // MARK: - Get Analytics
    
    func getTodayAnalytics() -> DailyAnalytics {
        let today = startOfDay(Date())
        
        guard let data = UserDefaults.standard.data(forKey: analyticsKey),
              let allAnalytics = try? JSONDecoder().decode([DailyAnalytics].self, from: data),
              let todayAnalytics = allAnalytics.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) else {
            return DailyAnalytics(date: today, articlesRead: 0, minutesRead: 0, feedsVisited: 0, streakDay: 0)
        }
        
        return todayAnalytics
    }
    
    func getAnalytics(forRange range: DateRange) -> [DailyAnalytics] {
        guard let data = UserDefaults.standard.data(forKey: analyticsKey),
              let allAnalytics = try? JSONDecoder().decode([DailyAnalytics].self, from: data) else {
            return []
        }
        
        return allAnalytics.filter { $0.date >= range.start && $0.date <= range.end }
    }
    
    func getWeeklyAnalytics() -> [DailyAnalytics] {
        let start = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return getAnalytics(forRange: .init(start: start, end: Date()))
    }
    
    func getMonthlyAnalytics() -> [DailyAnalytics] {
        let start = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return getAnalytics(forRange: .init(start: start, end: Date()))
    }
    
    // MARK: - Streaks
    
    func getCurrentStreak() -> Int {
        return getTodayAnalytics().streakDay
    }
    
    private func updateStreak() {
        var today = getTodayAnalytics()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        
        if let data = UserDefaults.standard.data(forKey: analyticsKey),
           let allAnalytics = try? JSONDecoder().decode([DailyAnalytics].self, from: data),
           let yesterdayAnalytics = allAnalytics.first(where: { Calendar.current.isDate($0.date, inSameDayAs: yesterday) }) {
            
            if yesterdayAnalytics.articlesRead > 0 {
                today.streakDay = yesterdayAnalytics.streakDay + 1
            } else {
                today.streakDay = 1
            }
        } else {
            today.streakDay = 1
        }
        
        saveAnalytics(today)
    }
    
    // MARK: - Feed Visit Tracking
    
    private var visitedFeedsKey: String { "feeds_visited_\(dateKey(Date()))" }
    
    private func isFeedVisitedToday(_ feedId: UUID) -> Bool {
        guard let data = UserDefaults.standard.data(forKey: visitedFeedsKey),
              let ids = try? JSONDecoder().decode([UUID].self, from: data) else {
            return false
        }
        return ids.contains(feedId)
    }
    
    private func markFeedVisitedToday(_ feedId: UUID) {
        var ids: [UUID] = []
        if let data = UserDefaults.standard.data(forKey: visitedFeedsKey),
           let existingIds = try? JSONDecoder().decode([UUID].self, from: data) {
            ids = existingIds
        }
        ids.append(feedId)
        if let data = try? JSONEncoder().encode(ids) {
            UserDefaults.standard.set(data, forKey: visitedFeedsKey)
        }
    }
    
    // MARK: - Helpers
    
    private func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }
    
    private func dateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func saveAnalytics(_ analytics: DailyAnalytics) {
        var allAnalytics: [DailyAnalytics] = []
        
        if let data = UserDefaults.standard.data(forKey: analyticsKey),
           let existing = try? JSONDecoder().decode([DailyAnalytics].self, from: data) {
            allAnalytics = existing
        }
        
        // Remove analytics for this date if exists
        allAnalytics.removeAll { Calendar.current.isDate($0.date, inSameDayAs: analytics.date) }
        allAnalytics.append(analytics)
        
        // Keep only last 90 days
        let cutoff = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()
        allAnalytics = allAnalytics.filter { $0.date >= cutoff }
        
        if let data = try? JSONEncoder().encode(allAnalytics) {
            UserDefaults.standard.set(data, forKey: analyticsKey)
        }
    }
    
    // MARK: - Date Range
    
    struct DateRange {
        let start: Date
        let end: Date
    }
    
    // MARK: - Statistics
    
    struct Statistics {
        let totalArticlesRead: Int
        let totalMinutesRead: Int
        let averageArticlesPerDay: Double
        let currentStreak: Int
        let longestStreak: Int
        let topFeeds: [(feedId: UUID, count: Int)]
    }
    
    func getStatistics() -> Statistics {
        let analytics = getMonthlyAnalytics()
        
        let totalArticles = analytics.reduce(0) { $0 + $1.articlesRead }
        let totalMinutes = analytics.reduce(0) { $0 + $1.minutesRead }
        let avgArticles = analytics.isEmpty ? 0 : Double(totalArticles) / Double(analytics.count)
        let currentStreak = getCurrentStreak()
        
        // Calculate longest streak
        var longestStreak = 0
        var currentStreakCount = 0
        for day in analytics.sorted(by: { $0.date < $1.date }) {
            if day.articlesRead > 0 {
                currentStreakCount += 1
                longestStreak = max(longestStreak, currentStreakCount)
            } else {
                currentStreakCount = 0
            }
        }
        
        return Statistics(
            totalArticlesRead: totalArticles,
            totalMinutesRead: totalMinutes,
            averageArticlesPerDay: avgArticles,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            topFeeds: [] // Would need feed-specific tracking
        )
    }
}
