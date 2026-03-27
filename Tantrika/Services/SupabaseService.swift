import Foundation
import Supabase

// MARK: — Live implementation backed by Supabase

final class SupabaseService: SupabaseServiceProtocol, @unchecked Sendable {

    static let shared = SupabaseService()

    private let client: SupabaseClient

    private init() {
        guard
            let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
            let url = URL(string: urlString),
            let anonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String
        else {
            fatalError("SUPABASE_URL and SUPABASE_ANON_KEY must be set in Info.plist")
        }
        client = SupabaseClient(supabaseURL: url, supabaseKey: anonKey)
    }

    // MARK: Auth

    var isAuthenticated: Bool { false } // synchronous stub; use checkAuthenticated() for real state

    func checkAuthenticated() async -> Bool {
        (try? await client.auth.session) != nil
    }

    func signInWithApple(idToken: String, nonce: String) async throws {
        try await client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func restoreSession() async throws -> Bool {
        do {
            _ = try await client.auth.session
            return true
        } catch {
            return false
        }
    }

    // MARK: Content

    func fetchCourses() async throws -> [Course] {
        try await client
            .from("courses")
            .select()
            .order("sort_order")
            .execute()
            .value
    }

    func fetchLessons(courseId: UUID) async throws -> [Lesson] {
        try await client
            .from("lessons")
            .select()
            .eq("course_id", value: courseId)
            .order("sort_order")
            .execute()
            .value
    }

    // MARK: Profile

    func fetchProfile() async throws -> UserProfile {
        guard let userId = try? await client.auth.session.user.id else {
            throw ServiceError.notAuthenticated
        }
        return try await client
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value
    }

    // MARK: Progress

    func fetchProgress(lessonId: UUID) async throws -> UserProgress? {
        guard let userId = try? await client.auth.session.user.id else {
            throw ServiceError.notAuthenticated
        }
        let results: [UserProgress] = try await client
            .from("user_progress")
            .select()
            .eq("user_id", value: userId)
            .eq("lesson_id", value: lessonId)
            .limit(1)
            .execute()
            .value
        return results.first
    }

    func upsertProgress(lessonId: UUID, watchedSeconds: Int, isCompleted: Bool) async throws {
        guard let userId = try? await client.auth.session.user.id else {
            throw ServiceError.notAuthenticated
        }
        struct ProgressUpsert: Encodable {
            let userId: UUID
            let lessonId: UUID
            let watchedSeconds: Int
            let isCompleted: Bool
            enum CodingKeys: String, CodingKey {
                case userId        = "user_id"
                case lessonId      = "lesson_id"
                case watchedSeconds = "watched_seconds"
                case isCompleted   = "is_completed"
            }
        }
        try await client
            .from("user_progress")
            .upsert(ProgressUpsert(
                userId: userId,
                lessonId: lessonId,
                watchedSeconds: watchedSeconds,
                isCompleted: isCompleted
            ), onConflict: "user_id,lesson_id")
            .execute()
    }
}

enum ServiceError: LocalizedError {
    case notAuthenticated
    case videoAccessDenied
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:   return "Please sign in to continue."
        case .videoAccessDenied: return "This lesson requires a membership."
        case .unknown(let msg):  return msg
        }
    }
}
