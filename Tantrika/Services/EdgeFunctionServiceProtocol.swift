import Foundation

protocol EdgeFunctionServiceProtocol: Sendable {
    /// Returns a signed Cloudflare Stream HLS URL for the given lesson.
    /// Throws if the user is not authorised to access the lesson.
    func signedVideoURL(lessonId: UUID) async throws -> URL
}
