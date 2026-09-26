import Foundation
import XCTest

enum FixtureLoader {
    static func url(_ relativePath: String, file: StaticString = #filePath, line: UInt = #line) throws -> URL {
        let root = try XCTUnwrap(Bundle.module.url(forResource: "Fixtures", withExtension: nil),
                                 "Fixtures folder missing from test bundle", file: file, line: line)
        return root.appendingPathComponent(relativePath)
    }

    static func data(_ relativePath: String, file: StaticString = #filePath, line: UInt = #line) throws -> Data {
        try Data(contentsOf: url(relativePath, file: file, line: line))
    }

    static func string(_ relativePath: String, file: StaticString = #filePath, line: UInt = #line) throws -> String {
        let text = String(decoding: try data(relativePath, file: file, line: line), as: UTF8.self)
        return text
    }
}

struct TwoFHeyCases: Decodable {
    struct Case: Decodable {
        let line: Int
        let message: String
        let sender: String?
        let expected: String?
        let service: String?
    }
    let cases: [Case]
}

struct EmailCases: Decodable {
    struct Case: Decodable {
        let name: String
        let file: String
        let from: String
        let subject: String
        let expected: String?
    }
    let cases: [Case]
}
