import Foundation

/// URLProtocol stub: records each request (with its body) and answers with a canned response.
final class StubURLProtocol: URLProtocol {
    struct Recorded {
        let request: URLRequest
        let body: Data?
    }

    struct Reply {
        let status: Int
        let json: String
    }

    private static let lock = NSLock()
    nonisolated(unsafe) private static var reply = Reply(status: 500, json: "{}")
    nonisolated(unsafe) private static var recorded: [Recorded] = []

    static func respond(status: Int, json: String) {
        lock.withLock {
            reply = Reply(status: status, json: json)
            recorded = []
        }
    }

    static var requests: [Recorded] { lock.withLock { recorded } }

    static func session() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: config)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let body = request.httpBody ?? request.httpBodyStream.map(Self.readAll)
        let current = Self.lock.withLock { () -> Reply in
            Self.recorded.append(Recorded(request: request, body: body))
            return Self.reply
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: current.status, httpVersion: "HTTP/1.1",
                                       headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(current.json.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private static func readAll(_ stream: InputStream) -> Data {
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while stream.hasBytesAvailable {
            let n = stream.read(&buffer, maxLength: buffer.count)
            if n <= 0 { break }
            data.append(buffer, count: n)
        }
        return data
    }
}
