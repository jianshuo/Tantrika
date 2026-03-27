import Foundation

struct Course: Identifiable, Codable, Sendable {
    let id: UUID
    let title: String
    let description: String
    let thumbnailUrl: String?
    let lessonCount: Int
    let totalDurationSeconds: Int
    let sortOrder: Int

    var totalDurationFormatted: String {
        let hours = totalDurationSeconds / 3600
        let minutes = (totalDurationSeconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case thumbnailUrl    = "thumbnail_url"
        case lessonCount     = "lesson_count"
        case totalDurationSeconds = "total_duration_seconds"
        case sortOrder       = "sort_order"
    }
}
