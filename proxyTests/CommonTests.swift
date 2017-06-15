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
    func testCellsIncrementTags() {
        let cells = [UITableViewCell(), UITableViewCell()]
        cells.incrementedTags
        for cell in cells {
            XCTAssertEqual(cell.tag, 1)
        }
    }

    func testDoubleAsTimeAgo() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"

        let date = Date()

        XCTAssertEqual(date.timeIntervalSince1970.asTimeAgo,
                       dateFormatter.string(from: date))
    }

    func testSnapshotGetConvos() throws {
        let x = expectation(description: #function)

        var convo1 = Convo()
        convo1.senderLeftConvo = false
        convo1.senderIsBlocking = false

        var convo2 = Convo()
        convo2.senderLeftConvo = true
        convo2.senderIsBlocking = true

        DB.set([try DB.path("test", "a"): convo1.toJSON(),
                try DB.path("test", "b"): convo2.toJSON()]) { (success) in
                    XCTAssert(success)

                    DB.get("test", completion: { (snapshot) in
                        let convos = snapshot?.toConvos()
                        XCTAssertEqual(convos?.count, 1)

                        DB.delete("test", completion: { (success) in
                            XCTAssert(success)
                            x.fulfill()
                        })
                    })
        }

        waitForExpectations(timeout: 5)
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
