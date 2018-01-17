import FirebaseDatabase
import XCTest
@testable import Proxy

class CommonTests: XCTestCase {
    func testDoubleAsTimeAgo() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        let date = Date()
        XCTAssertEqual(date.timeIntervalSince1970.asTimeAgo, dateFormatter.string(from: date))
    }

    func testIntAsLabel() {
        XCTAssertEqual(0.asLabel, "")
        XCTAssertEqual(1.asLabel, "1")
    }

    func testIntAsLabelWithParens() {
        XCTAssertEqual(0.asStringWithParens, "")
        XCTAssertEqual(1.asStringWithParens, " (1)")
    }

    func testStringGetFirstNChars() {
        XCTAssertEqual("cat".getFirstNChars(2), "ca")
    }

    func testUIntAsStringWithCommas() {
        XCTAssertEqual(UInt(1).asStringWithCommas, "1")
        XCTAssertEqual(UInt(100).asStringWithCommas, "100")
        XCTAssertEqual(UInt(1000).asStringWithCommas, "1,000")
        XCTAssertEqual(UInt(10000).asStringWithCommas, "10,000")
        XCTAssertEqual(UInt(100000).asStringWithCommas, "100,000")
        XCTAssertEqual(UInt(1000000).asStringWithCommas, "1,000,000")
    }
}
