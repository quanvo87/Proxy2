//
//  CommonTests.swift
//  proxy
//
//  Created by Quan Vo on 6/14/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import XCTest
@testable import proxy
import FirebaseDatabase

class CommonTests: XCTestCase {
    func testAndEqual() {
        var lhs: Bool

        lhs = true
        lhs &= true
        XCTAssert(lhs)

        lhs &= false
        XCTAssertFalse(lhs)

        lhs = false
        lhs &= false
        XCTAssertFalse(lhs)

        lhs &= true
        XCTAssertFalse(lhs)
    }

    func testDoubleAsTimeAgo() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"

        let date = Date()

        XCTAssertEqual(date.timeIntervalSince1970.asTimeAgo,
                       dateFormatter.string(from: date))
    }

    func testErrorDescription() {
        let error = ProxyError.blankCredentials
        XCTAssertEqual(error.description,
                       "Please enter a valid email and password.")
    }

    func testIntIncrement() {
        var i = 0
        i.increment()
        XCTAssertEqual(i, 1)

        i = Int.max
        i.increment()
        XCTAssertEqual(i, 0)
    }

    func testIntAsLabelWithParens() {
        XCTAssertEqual(0.asLabelWithParens, "")
        XCTAssertEqual(1.asLabelWithParens, " (1)")
    }

    func testIntAsLabel() {
        XCTAssertEqual(0.asLabel, "")
        XCTAssertEqual(1.asLabel, "1")
    }

    func testShortForm() {
        XCTAssertEqual(1.asStringWithCommas, "1")
        XCTAssertEqual(100.asStringWithCommas, "100")
        XCTAssertEqual(1000.asStringWithCommas, "1,000")
        XCTAssertEqual(10000.asStringWithCommas, "10,000")
        XCTAssertEqual(100000.asStringWithCommas, "100,000")
        XCTAssertEqual(1000000.asStringWithCommas, "1,000,000")
    }
}
