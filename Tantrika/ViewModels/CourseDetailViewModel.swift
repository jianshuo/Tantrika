import SwiftUI

@Observable
final class CourseDetailViewModel {

    var lessons: [Lesson] = []
    var progressMap: [UUID: UserProgress] = [:]
    var isLoading: Bool = false
    var errorMessage: String? = nil

    private let supabase: any SupabaseServiceProtocol
    let course: Course

    init(course: Course, supabase: any SupabaseServiceProtocol = SupabaseService.shared) {
        self.course = course
        self.supabase = supabase
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            lessons = try await supabase.fetchLessons(courseId: course.id)
            await loadProgress()
        } catch {
            errorMessage = "Couldn't load lessons. Check your connection and try again."
        }
    }

    private func loadProgress() async {
        await withTaskGroup(of: (UUID, UserProgress?).self) { group in
            for lesson in lessons {
                group.addTask {
                    let progress = try? await self.supabase.fetchProgress(lessonId: lesson.id)
                    return (lesson.id, progress)
                }
            }
            for await (id, progress) in group {
                if let progress { progressMap[id] = progress }
            }
        }
    }

    func completionRatio(for lesson: Lesson) -> Double {
        progressMap[lesson.id]?.completionRatio(lessonDurationSeconds: lesson.durationSeconds) ?? 0
    }

    func isCompleted(_ lesson: Lesson) -> Bool {
        progressMap[lesson.id]?.isCompleted == true
    }
}
