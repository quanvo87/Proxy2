import XCTest
@testable import Proxy

class ProxyTests: XCTestCase {
    func testAsStringWithComas() {
        var num: UInt = 1000
        XCTAssertEqual(num.asAbbreviatedString, "1K")
        num = 999
        XCTAssertEqual(num.asAbbreviatedString, "999")
        num = 1234
        XCTAssertEqual(num.asAbbreviatedString, "1.2K")
        num = 1909
        XCTAssertEqual(num.asAbbreviatedString, "1.9K")
        num = 1000000
        XCTAssertEqual(num.asAbbreviatedString, "1M")
        num = 900929
        XCTAssertEqual(num.asAbbreviatedString, "900.9K")
        num = 1000023
        XCTAssertEqual(num.asAbbreviatedString, "1M")
        num = 1600031
        XCTAssertEqual(num.asAbbreviatedString, "1.6M")
        num = 1111111111
        XCTAssertEqual(num.asAbbreviatedString, "1.1B")
        num = 1111111111111
        XCTAssertEqual(num.asAbbreviatedString, "1.1t")
        num = 1111111111111111
        XCTAssertEqual(num.asAbbreviatedString, "1.1q")
        num = 1111111111111111111
        XCTAssertEqual(num.asAbbreviatedString, "1.1Q")
    }
}
