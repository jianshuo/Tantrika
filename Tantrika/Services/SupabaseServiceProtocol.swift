import Foundation

protocol SupabaseServiceProtocol: Sendable {
    // MARK: Auth
    func signInWithApple(idToken: String, nonce: String) async throws
    func signOut() async throws
    func restoreSession() async throws -> Bool
    var isAuthenticated: Bool { get }
    func checkAuthenticated() async -> Bool

    // MARK: Content
    func fetchCourses() async throws -> [Course]
    func fetchLessons(courseId: UUID) async throws -> [Lesson]

    // MARK: Profile
    func fetchProfile() async throws -> UserProfile

    // MARK: Progress
    func fetchProgress(lessonId: UUID) async throws -> UserProgress?
    func upsertProgress(lessonId: UUID, watchedSeconds: Int, isCompleted: Bool) async throws
}
