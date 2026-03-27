import Foundation

// MARK: — In-memory mock for SwiftUI previews and unit tests

final class MockSupabaseService: SupabaseServiceProtocol, @unchecked Sendable {

    var mockIsAuthenticated: Bool = true
    var mockProfile = UserProfile(
        id: UUID(),
        isSubscribed: false,
        createdAt: Date()
    )
    var mockCourses: [Course] = Course.mockData
    var mockLessons: [UUID: [Lesson]] = [:]
    var mockProgress: [UUID: UserProgress] = [:]
    var signInShouldFail = false

    var isAuthenticated: Bool { mockIsAuthenticated }
    func checkAuthenticated() async -> Bool { mockIsAuthenticated }

    func signInWithApple(idToken: String, nonce: String) async throws {
        if signInShouldFail { throw ServiceError.unknown("Mock sign-in failure") }
        mockIsAuthenticated = true
    }

    func signOut() async throws {
        mockIsAuthenticated = false
    }

    func restoreSession() async throws -> Bool {
        return mockIsAuthenticated
    }

    func fetchCourses() async throws -> [Course] {
        return mockCourses
    }

    func fetchLessons(courseId: UUID) async throws -> [Lesson] {
        return mockLessons[courseId] ?? Lesson.mockData(courseId: courseId)
    }

    func fetchProfile() async throws -> UserProfile {
        return mockProfile
    }

    func fetchProgress(lessonId: UUID) async throws -> UserProgress? {
        return mockProgress[lessonId]
    }

    func upsertProgress(lessonId: UUID, watchedSeconds: Int, isCompleted: Bool) async throws {
        mockProgress[lessonId] = UserProgress(
            lessonId: lessonId,
            watchedSeconds: watchedSeconds,
            isCompleted: isCompleted,
            updatedAt: Date()
        )
    }
}

// MARK: — Mock data factories

extension Course {
    static let mockData: [Course] = [
        Course(
            id: UUID(uuidString: "11111111-0000-0000-0000-000000000001")!,
            title: "Foundations of Tantric Awareness",
            description: "An immersive introduction to the principles and practices that form the bedrock of Tantric philosophy. Begin here.",
            thumbnailUrl: nil,
            lessonCount: 6,
            totalDurationSeconds: 4200,
            sortOrder: 1
        ),
        Course(
            id: UUID(uuidString: "11111111-0000-0000-0000-000000000002")!,
            title: "Breath and Body as Temple",
            description: "A deepening practice exploring the body as a vessel for awakening. Suitable after completing Foundations.",
            thumbnailUrl: nil,
            lessonCount: 8,
            totalDurationSeconds: 6400,
            sortOrder: 2
        )
    ]
}

extension Lesson {
    static func mockData(courseId: UUID) -> [Lesson] {
        [
            Lesson(
                id: UUID(uuidString: "22222222-0000-0000-0000-000000000001")!,
                courseId: courseId,
                title: "The Ground of Being",
                description: "We begin by arriving. This practice establishes presence before movement.",
                durationSeconds: 480,
                sortOrder: 1,
                isFreePreview: true,
                cfVideoId: "mock-video-id-1",
                thumbnailUrl: nil
            ),
            Lesson(
                id: UUID(uuidString: "22222222-0000-0000-0000-000000000002")!,
                courseId: courseId,
                title: "Awakening the Subtle Body",
                description: "An exploration of prana and the energetic channels that inform physical experience.",
                durationSeconds: 720,
                sortOrder: 2,
                isFreePreview: false,
                cfVideoId: "mock-video-id-2",
                thumbnailUrl: nil
            ),
            Lesson(
                id: UUID(uuidString: "22222222-0000-0000-0000-000000000003")!,
                courseId: courseId,
                title: "The Sacred Pause",
                description: "Learning to rest in stillness between movements. A practice of integration.",
                durationSeconds: 600,
                sortOrder: 3,
                isFreePreview: false,
                cfVideoId: "mock-video-id-3",
                thumbnailUrl: nil
            )
        ]
    }
}
