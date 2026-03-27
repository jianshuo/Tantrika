import Foundation

struct UserProfile: Codable, Sendable {
    let id: UUID
    let isSubscribed: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case isSubscribed = "is_subscribed"
        case createdAt    = "created_at"
    }
}
