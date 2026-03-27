import Foundation

final class MockEdgeFunctionService: EdgeFunctionServiceProtocol, @unchecked Sendable {

    var shouldFail = false
    var mockURL = URL(string: "https://example.com/mock-hls-stream.m3u8")!

    func signedVideoURL(lessonId: UUID) async throws -> URL {
        if shouldFail { throw ServiceError.videoAccessDenied }
        return mockURL
    }
}
