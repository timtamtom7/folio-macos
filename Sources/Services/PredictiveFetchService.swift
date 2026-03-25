import Foundation

final class PredictiveFetchService {
    static let shared = PredictiveFetchService()
    
    private let predictionsKey = "feed_predictions"
    private let historyKey = "feed_update_history"
    
    private init() {}
    
    struct FeedPrediction: Codable {
        let feedId: UUID
        var predictedHour: Int
        var predictedMinute: Int
        var confidence: Double // 0.0 - 1.0
        var patternType: PatternType
        var updatedAt: Date
        
        enum PatternType: String, Codable {
            case hourly
            case twiceDaily
            case daily
            case weekly
            case irregular
        }
        
        var nextPredictedDate: Date {
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = predictedHour
            components.minute = predictedMinute
            
            var predictedDate = calendar.date(from: components) ?? Date()
            
            // If the predicted time has passed today, schedule for tomorrow
            if predictedDate < Date() {
                predictedDate = calendar.date(byAdding: .day, value: 1, to: predictedDate) ?? predictedDate
            }
            
            return predictedDate
        }
    }
    
    struct UpdateHistoryEntry: Codable {
        let feedId: UUID
        let updateTime: Date
    }
    
    // MARK: - Predictions
    
    func getPrediction(for feedId: UUID) -> FeedPrediction? {
        guard let data = UserDefaults.standard.data(forKey: predictionsKey),
              let predictions = try? JSONDecoder().decode([UUID: FeedPrediction].self, from: data) else {
            return nil
        }
        return predictions[feedId]
    }
    
    func savePrediction(_ prediction: FeedPrediction) {
        var predictions = getAllPredictions()
        predictions[prediction.feedId] = prediction
        savePredictions(predictions)
    }
    
    func getAllPredictions() -> [UUID: FeedPrediction] {
        guard let data = UserDefaults.standard.data(forKey: predictionsKey),
              let predictions = try? JSONDecoder().decode([UUID: FeedPrediction].self, from: data) else {
            return [:]
        }
        return predictions
    }
    
    private func savePredictions(_ predictions: [UUID: FeedPrediction]) {
        if let data = try? JSONEncoder().encode(predictions) {
            UserDefaults.standard.set(data, forKey: predictionsKey)
        }
    }
    
    // MARK: - Update History
    
    func recordUpdate(for feedId: UUID, at time: Date = Date()) {
        var history = getAllHistory()
        history.append(UpdateHistoryEntry(feedId: feedId, updateTime: time))
        
        // Keep only last 30 days of history
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        history = history.filter { $0.updateTime > cutoff }
        
        saveHistory(history)
        
        // Recalculate prediction
        recalculatePrediction(for: feedId, history: history)
    }
    
    func getHistory(for feedId: UUID) -> [Date] {
        return getAllHistory().filter { $0.feedId == feedId }.map { $0.updateTime }
    }
    
    private func getAllHistory() -> [UpdateHistoryEntry] {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let history = try? JSONDecoder().decode([UpdateHistoryEntry].self, from: data) else {
            return []
        }
        return history
    }
    
    private func saveHistory(_ history: [UpdateHistoryEntry]) {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }
    
    // MARK: - Pattern Analysis
    
    private func recalculatePrediction(for feedId: UUID, history: [UpdateHistoryEntry]) {
        let feedHistory = history.filter { $0.feedId == feedId }.map { $0.updateTime }.sorted()
        
        guard feedHistory.count >= 7 else {
            // Not enough data for prediction
            return
        }
        
        // Calculate intervals between updates
        var intervals: [TimeInterval] = []
        for i in 1..<feedHistory.count {
            intervals.append(feedHistory[i].timeIntervalSince(feedHistory[i-1]))
        }
        
        let avgInterval = intervals.reduce(0, +) / Double(intervals.count)
        let hourInSeconds: TimeInterval = 3600
        let dayInSeconds: TimeInterval = 86400
        
        // Determine pattern type
        let patternType: FeedPrediction.PatternType
        let predictedHour: Int
        let predictedMinute: Int
        
        if avgInterval < 2 * hourInSeconds {
            patternType = .hourly
        } else if avgInterval < 14 * hourInSeconds {
            patternType = .twiceDaily
        } else if avgInterval < 36 * hourInSeconds {
            patternType = .daily
        } else if avgInterval < 10 * dayInSeconds {
            patternType = .weekly
        } else {
            patternType = .irregular
        }
        
        // Get the most common hour of day for updates
        let calendar = Calendar.current
        var hourCounts: [Int: Int] = [:]
        for time in feedHistory {
            let hour = calendar.component(.hour, from: time)
            hourCounts[hour, default: 0] += 1
        }
        
        let mostCommonHour = hourCounts.max(by: { $0.value < $1.value })?.key ?? 8
        predictedHour = mostCommonHour
        predictedMinute = 0 // Round to the hour
        
        // Calculate confidence based on consistency
        let variance = calculateVariance(intervals)
        let confidence = max(0.1, min(1.0, 1.0 - (variance / avgInterval)))
        
        let prediction = FeedPrediction(
            feedId: feedId,
            predictedHour: predictedHour,
            predictedMinute: predictedMinute,
            confidence: confidence,
            patternType: patternType,
            updatedAt: Date()
        )
        
        savePrediction(prediction)
    }
    
    private func calculateVariance(_ values: [TimeInterval]) -> TimeInterval {
        guard !values.isEmpty else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDiffs = values.map { pow($0 - mean, 2) }
        return squaredDiffs.reduce(0, +) / Double(values.count)
    }
    
    // MARK: - Smart Scheduling
    
    func getNextFetchDate(for feedId: UUID) -> Date? {
        return getPrediction(for: feedId)?.nextPredictedDate
    }
    
    func shouldPrefetch(feedId: UUID) -> Bool {
        guard let prediction = getPrediction(for: feedId) else { return false }
        
        let now = Date()
        let fiveMinutesBefore = prediction.nextPredictedDate.addingTimeInterval(-5 * 60)
        
        return now >= fiveMinutesBefore && now < prediction.nextPredictedDate
    }
}
