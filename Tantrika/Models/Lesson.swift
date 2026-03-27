import Foundation

struct Lesson: Identifiable, Codable, Sendable {
    let id: UUID
    let courseId: UUID
    let title: String
    let description: String?
    let durationSeconds: Int
    let sortOrder: Int
    let isFreePreview: Bool
    let cfVideoId: String
    let thumbnailUrl: String?

    var durationFormatted: String {
        let minutes = durationSeconds / 60
        let seconds = durationSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case courseId       = "course_id"
        case title
        case description
        case durationSeconds = "duration_seconds"
        case sortOrder      = "sort_order"
        case isFreePreview  = "is_free_preview"
        case cfVideoId      = "cf_video_id"
        case thumbnailUrl   = "thumbnail_url"
    }
}
