import Foundation

/// Dependency-free HTML → plain text for email bodies.
///
/// Uses only Foundation string and `NSRegularExpression` APIs, so it runs off the main
/// thread and inside an app extension (no WebKit, no `NSAttributedString` HTML import).
public enum HTMLText {
    /// Converts an HTML email body to readable plain text.
    ///
    /// - `<style>`, `<script>`, `<head>` contents and comments are dropped.
    /// - `<br>`, block boundaries (`p`, `div`, `tr`, `li`, `h1`-`h6`, `table`, ...) become
    ///   newlines; table cells (`</td>`, `</th>`) become a space; inline tags vanish, so text
    ///   split across inline tags (`<b>12</b><b>34</b>`) joins back up.
    /// - Named (common) and numeric entities are decoded; non-breaking spaces become spaces;
    ///   zero-width characters and soft hyphens are removed.
    /// - Runs of spaces collapse, lines are trimmed, and empty lines are removed.
    public static func plainText(fromHTML html: String) -> String {
        var text = html
        text = Patterns.comment.replace(in: text, with: "")
        text = Patterns.invisibleElement.replace(in: text, with: "")
        // Source whitespace (including newlines) is insignificant in HTML.
        text = Patterns.sourceWhitespace.replace(in: text, with: " ")
        text = Patterns.lineBreak.replace(in: text, with: "\n")
        text = Patterns.blockBoundary.replace(in: text, with: "\n")
        text = Patterns.cellEnd.replace(in: text, with: " ")
        text = Patterns.anyTag.replace(in: text, with: "")
        text = decodeEntities(text)
        return normalizeWhitespace(text)
    }

    // MARK: - Entities

    static func decodeEntities(_ text: String) -> String {
        let ns = text as NSString
        let matches = Patterns.entity.regex.matches(in: text, range: NSRange(location: 0, length: ns.length))
        guard !matches.isEmpty else { return text }
        var result = ""
        result.reserveCapacity(text.utf16.count)
        var cursor = 0
        for match in matches {
            result += ns.substring(with: NSRange(location: cursor, length: match.range.location - cursor))
            let body = ns.substring(with: match.range(at: 1))
            result += decodeEntity(body) ?? ns.substring(with: match.range)
            cursor = match.range.location + match.range.length
        }
        result += ns.substring(from: cursor)
        return result
    }

    private static func decodeEntity(_ body: String) -> String? {
        if body.hasPrefix("#") {
            let digits = body.dropFirst()
            let value: UInt32?
            if digits.first == "x" || digits.first == "X" {
                value = UInt32(digits.dropFirst(), radix: 16)
            } else {
                value = UInt32(digits, radix: 10)
            }
            guard let value, value != 0, let scalar = Unicode.Scalar(value) else { return nil }
            return String(Character(scalar))
        }
        return namedEntities[body] ?? namedEntities[body.lowercased()]
    }

    private static let namedEntities: [String: String] = [
        "amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'",
        "nbsp": "\u{00A0}", "ensp": "\u{2002}", "emsp": "\u{2003}", "thinsp": "\u{2009}",
        "zwnj": "\u{200C}", "zwj": "\u{200D}", "shy": "\u{00AD}",
        "copy": "©", "reg": "®", "trade": "™",
        "ndash": "–", "mdash": "—", "hellip": "…", "bull": "•", "middot": "·",
        "lsquo": "‘", "rsquo": "’", "sbquo": "‚", "ldquo": "“", "rdquo": "”", "bdquo": "„",
        "laquo": "«", "raquo": "»", "lsaquo": "‹", "rsaquo": "›",
        "euro": "€", "pound": "£", "yen": "¥", "cent": "¢",
        "times": "×", "divide": "÷", "deg": "°", "plusmn": "±",
        "para": "¶", "sect": "§", "dagger": "†", "rarr": "→", "larr": "←",
    ]

    // MARK: - Whitespace

    /// Characters that carry no text and can split a code (e.g. preheader fillers).
    private static let invisibleScalars: Set<UInt32> = [0x200B, 0x200C, 0x200D, 0x2060, 0xFEFF, 0x00AD]

    private static func normalizeWhitespace(_ text: String) -> String {
        var scalars = String.UnicodeScalarView()
        for scalar in text.unicodeScalars {
            if invisibleScalars.contains(scalar.value) { continue }
            if scalar == "\r" { continue }
            if scalar != "\n", scalar.properties.isWhitespace {
                scalars.append(" ")
            } else {
                scalars.append(scalar)
            }
        }
        // Nested tables and blocks produce many empty lines; none of them carry meaning.
        return String(scalars)
            .split(separator: "\n")
            .map { $0.split(separator: " ").joined(separator: " ") }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    // MARK: - Patterns

    private struct Pattern: Sendable {
        let regex: NSRegularExpression

        init(_ pattern: String) {
            regex = try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        }

        func replace(in text: String, with template: String) -> String {
            regex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: template)
        }
    }

    private enum Patterns {
        static let comment = Pattern(#"<!--[\s\S]*?-->"#)
        static let invisibleElement = Pattern(#"<(script|style|head|title)\b[^>]*>[\s\S]*?</\1\s*>"#)
        static let sourceWhitespace = Pattern(#"[ \t\r\n\f]+"#)
        static let lineBreak = Pattern(#"<br\b[^>]*>"#)
        static let blockBoundary = Pattern(
            #"</?(?:p|div|tr|li|ul|ol|dl|dt|dd|h[1-6]|table|thead|tbody|tfoot|blockquote|pre|section|article|header|footer|hr|center)\b[^>]*>"#
        )
        static let cellEnd = Pattern(#"</t[dh]\s*>"#)
        static let anyTag = Pattern(#"</?[a-z!][^>]*>"#)
        static let entity = Pattern(#"&(#[0-9]{1,7}|#[xX][0-9a-fA-F]{1,6}|[a-zA-Z][a-zA-Z0-9]{1,31});"#)
    }
}
