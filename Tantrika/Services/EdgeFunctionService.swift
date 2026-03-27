import Foundation
import Supabase

final class EdgeFunctionService: EdgeFunctionServiceProtocol, @unchecked Sendable {

    static let shared = EdgeFunctionService()

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

    func signedVideoURL(lessonId: UUID) async throws -> URL {
        struct Request: Encodable  { let lessonId: String }
        struct Response: Decodable { let url: String }

        let response: Response = try await client.functions
            .invoke(
                "sign-video-url",
                options: .init(body: Request(lessonId: lessonId.uuidString))
            )

        guard let url = URL(string: response.url) else {
            throw ServiceError.unknown("Invalid signed URL returned from server")
        }
        return url
    }
}
