import XCTest
import SkiPassExtraction

final class HTMLTextTests: XCTestCase {
    private func text(_ html: String) -> String {
        HTMLText.plainText(fromHTML: html)
    }

    func testDropsStyleScriptHeadAndComments() {
        let html = """
        <html><head><title>Hidden title</title><style>.a { color: red; }</style></head>
        <body><!-- tracking comment --><script type="text/javascript">var x = 1;</script>
        <STYLE>p { margin: 0 }</STYLE><p>Visible</p></body></html>
        """
        XCTAssertEqual(text(html), "Visible")
    }

    func testBlockTagsBecomeNewlines() {
        XCTAssertEqual(text("one<br>two<br/>three<BR />four"), "one\ntwo\nthree\nfour")
        XCTAssertEqual(text("<p>first</p><p>second</p><div>third</div>"), "first\nsecond\nthird")
        XCTAssertEqual(text("<table><tr><td>Code</td><td>123456</td></tr><tr><td>Valid</td><td>10 min</td></tr></table>"),
                       "Code 123456\nValid 10 min")
    }

    func testSourceWhitespaceCollapses() {
        XCTAssertEqual(text("  Your\n   verification\tcode  "), "Your verification code")
        XCTAssertEqual(text("<p>a</p>\n\n\n<p></p><p></p><p>b</p>"), "a\nb")
    }

    func testInlineTagsJoinSplitText() {
        XCTAssertEqual(text("Code: <b>28</b><span style=\"x\">19</span><i>47</i>"), "Code: 281947")
    }

    func testNamedEntities() {
        XCTAssertEqual(text("Tom &amp; Jerry &lt;tag&gt; &quot;q&quot; &apos;a&apos;"), "Tom & Jerry <tag> \"q\" 'a'")
        XCTAssertEqual(text("&copy; 2026 &mdash; &euro;5 &hellip;"), "© 2026 — €5 …")
        XCTAssertEqual(text("A&nbsp;B"), "A B")
        XCTAssertEqual(text("&AMP;"), "&")
    }

    func testNumericEntities() {
        XCTAssertEqual(text("&#65;&#x42;&#X43; didn&#8217;t &#x1F600;"), "ABC didn’t 😀")
    }

    func testUnknownAndBrokenEntitiesStay() {
        XCTAssertEqual(text("&unknownentity; &#0; & alone &amp"), "&unknownentity; &#0; & alone &amp")
    }

    func testEscapedMarkupIsNotTreatedAsTags() {
        XCTAssertEqual(text("&lt;b&gt;bold&lt;/b&gt;"), "<b>bold</b>")
        XCTAssertEqual(text("if a < b and c > d"), "if a < b and c > d")
    }

    func testInvisibleCharactersRemoved() {
        XCTAssertEqual(text("12&zwnj;34&#8203;56&shy;"), "123456")
        XCTAssertEqual(text("Preview&nbsp;&zwnj;&nbsp;&zwnj;&nbsp;text"), "Preview text")
    }

    func testFixtureBodies() throws {
        let verify = text(try FixtureLoader.string("emails/verify-table.html"))
        XCTAssertTrue(verify.contains("\n739204\n"), verify)
        XCTAssertFalse(verify.contains("font-size"), verify)
        XCTAssertFalse(verify.contains("Preheader"), verify)
        XCTAssertTrue(verify.contains("didn’t request this"), verify)

        let split = text(try FixtureLoader.string("emails/split-tags.html"))
        XCTAssertTrue(split.contains("Your single-use code is: 281947"), split)

        let spaced = text(try FixtureLoader.string("emails/split-spaced.html"))
        XCTAssertTrue(spaced.contains("\n593 018\n"), spaced)
    }
}
