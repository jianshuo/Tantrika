import Foundation

struct UserProgress: Codable, Sendable {
    let lessonId: UUID
    let watchedSeconds: Int
    let isCompleted: Bool
    let updatedAt: Date

    /// Completion threshold — mark lesson done at 90% watched
    static let completionThreshold: Double = 0.9

    func completionRatio(lessonDurationSeconds: Int) -> Double {
        guard lessonDurationSeconds > 0 else { return 0 }
        return min(Double(watchedSeconds) / Double(lessonDurationSeconds), 1.0)
    }

    enum CodingKeys: String, CodingKey {
        case lessonId      = "lesson_id"
        case watchedSeconds = "watched_seconds"
        case isCompleted   = "is_completed"
        case updatedAt     = "updated_at"
    }
}
