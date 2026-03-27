import SwiftUI

@Observable
final class LibraryViewModel {

    var courses: [Course] = []
    var profile: UserProfile? = nil
    var isLoading: Bool = false
    var errorMessage: String? = nil

    private let supabase: any SupabaseServiceProtocol

    init(supabase: any SupabaseServiceProtocol = SupabaseService.shared) {
        self.supabase = supabase
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let coursesTask  = supabase.fetchCourses()
            async let profileTask  = supabase.fetchProfile()
            (courses, profile) = try await (coursesTask, profileTask)
        } catch {
            errorMessage = "Couldn't load content. Check your connection and try again."
        }
    }

    var isSubscribed: Bool {
        profile?.isSubscribed == true
    }
}
