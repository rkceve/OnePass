import Foundation
import SkiPassModels

/// Configuration for `ServerClient` (values come from Info.plist keys `SkiPassServerURL` /
/// `SkiPassAppToken` and the App Group key `rc.appUserID`, CONTRACTS §2 and §4).
public struct ServerClientConfiguration: Sendable {
    /// Worker base URL, e.g. `https://skipass-server.example.workers.dev`.
    public var baseURL: URL
    /// Sent as `X-SkiPass-App-Token`.
    public var appToken: String
    /// Returns the RevenueCat app user ID, sent as `X-SkiPass-User`; nil or empty = not available yet.
    public var appUserID: @Sendable () -> String?
    /// Per-request timeout in seconds.
    public var timeout: TimeInterval

    public init(baseURL: URL, appToken: String,
                appUserID: @escaping @Sendable () -> String?,
                timeout: TimeInterval = 10) {
        self.baseURL = baseURL
        self.appToken = appToken
        self.appUserID = appUserID
        self.timeout = timeout
    }
}

public enum ServerClientError: Error, Equatable, Sendable {
    /// 402 `{"error":"quota_exhausted","remaining":0}` from `POST /v1/fills`.
    case quotaExhausted
    /// 401 `{"error":"unauthorized"}`.
    case unauthorized
    /// No RevenueCat app user ID available to send.
    case missingAppUserID
    /// Any other non-success status.
    case httpStatus(Int)
    /// The response was not HTTP or its body did not match CONTRACTS §5.
    case invalidResponse
}

/// Client for the SkiPass server HTTP API (CONTRACTS §5).
public struct ServerClient: CandidateJudging, UsageReporting {
    public let configuration: ServerClientConfiguration
    private let session: URLSession

    public init(configuration: ServerClientConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    // MARK: CandidateJudging

    /// `POST /v1/judge`. Does not count usage. 402 maps to `.quotaExhausted`.
    public func judge(service: String?, messages: [FetchedMessage]) async throws -> JudgeOutcome {
        // The server rejects an empty list; with nothing to judge there is no match.
        guard !messages.isEmpty else { return .noMatch(scores: [:]) }
        let body = JudgeRequest(service: service,
                                messages: messages.map { .init(id: $0.id, text: $0.judgeText) })
        let (data, status) = try await send(path: "v1/judge", method: "POST", body: body)
        switch status {
        case 200:
            let decoded = try decode(JudgeResponse.self, from: data)
            if let chosen = decoded.chosenId {
                return .chosen(messageID: chosen, scores: decoded.scores)
            }
            return .noMatch(scores: decoded.scores)
        case 402:
            return .quotaExhausted
        default:
            throw Self.error(for: status)
        }
    }

    // MARK: UsageReporting

    /// `POST /v1/fills`. Counts one fill and returns the remaining fills.
    @discardableResult
    public func reportFill(messageID: String) async throws -> Int {
        let (data, status) = try await send(path: "v1/fills", method: "POST",
                                            body: FillRequest(messageId: messageID))
        switch status {
        case 200: return try decode(FillResponse.self, from: data).remaining
        case 402: throw ServerClientError.quotaExhausted
        default: throw Self.error(for: status)
        }
    }

    /// `GET /v1/usage`.
    public func currentUsage() async throws -> UsageSnapshot {
        let (data, status) = try await send(path: "v1/usage", method: "GET", body: Optional<FillRequest>.none)
        guard status == 200 else { throw Self.error(for: status) }
        let u = try decode(UsageResponse.self, from: data)
        return UsageSnapshot(plan: u.plan, used: u.used, limit: u.limit, resetsAt: u.resetsAt)
    }

    // MARK: Transport

    private func send<Body: Encodable>(path: String, method: String, body: Body?) async throws -> (Data, Int) {
        guard let user = configuration.appUserID(), !user.isEmpty else {
            throw ServerClientError.missingAppUserID
        }
        var request = URLRequest(url: configuration.baseURL.appending(path: path),
                                 timeoutInterval: configuration.timeout)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(configuration.appToken, forHTTPHeaderField: "X-SkiPass-App-Token")
        request.setValue(user, forHTTPHeaderField: "X-SkiPass-User")
        if let body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ServerClientError.invalidResponse }
        return (data, http.statusCode)
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw ServerClientError.invalidResponse
        }
    }

    private static func error(for status: Int) -> ServerClientError {
        status == 401 ? .unauthorized : .httpStatus(status)
    }
}

// MARK: Wire types (CONTRACTS §5)

struct JudgeRequest: Encodable {
    struct Message: Encodable {
        let id: String
        let text: String
    }

    let service: String?
    let messages: [Message]

    private enum CodingKeys: String, CodingKey { case service, messages }

    // `service` is always present, as a string or JSON null.
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        if let service {
            try c.encode(service, forKey: .service)
        } else {
            try c.encodeNil(forKey: .service)
        }
        try c.encode(messages, forKey: .messages)
    }
}

struct JudgeResponse: Decodable {
    let chosenId: String?
    let scores: [String: Double]
    let remaining: Int
    let source: String
}

struct FillRequest: Encodable {
    let messageId: String
}

struct FillResponse: Decodable {
    let remaining: Int
}

struct UsageResponse: Decodable {
    let plan: String
    let used: Int
    let limit: Int
    let resetsAt: Date
}
