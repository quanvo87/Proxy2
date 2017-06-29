//
//  DBTests.swift
//  proxy
//
//  Created by Quan Vo on 6/14/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import XCTest
@testable import proxy
import FirebaseDatabase

class DBTests: DBTest {
    func testPath() {
        XCTAssertNotNil(DB.Path("a"))
        XCTAssertNotNil(DB.Path("a", "b"))
        XCTAssertNotNil(DB.Path("/a/"))
        XCTAssertNotNil(DB.Path("//a//"))
        XCTAssertNotNil(DB.Path("/a/a/"))
    }

    func testBadPath() {
        XCTAssertNil(DB.Path(""))
        XCTAssertNil(DB.Path("a", ""))
        XCTAssertNil(DB.Path("", "a"))
        XCTAssertNil(DB.Path("/"))
        XCTAssertNil(DB.Path("//"))
        XCTAssertNil(DB.Path("///"))
        XCTAssertNil(DB.Path("/a//a/"))
    }

    func testRef() {
        XCTAssertNotNil(DB.ref(DB.Path("a")))
        XCTAssertNotNil(DB.ref(DB.Path("a", "b")))
    }

    func testBadRef() {
        var ref: DatabaseReference?

        ref = DB.ref(DB.Path(""))
        XCTAssertNil(ref)
    }

    func testGetSetDelete() {
        let x = expectation(description: #function)

        DB.set("a", at: "test") { (success) in
            XCTAssert(success)

            DB.get("test") { (snapshot) in
                XCTAssertNotNil(snapshot)
                XCTAssertEqual(snapshot?.value as? String ?? "", "a")

                DB.delete("test") { (success) in
                    XCTAssert(success)

                    DB.get("test") { (snapshot) in
                        XCTAssertEqual(snapshot?.value as? FirebaseDatabase.NSNull, FirebaseDatabase.NSNull())
                        x.fulfill()
                    }
                }
            }
        }

        waitForExpectations(timeout: 10)
    }

    func testIncrement() {
        let x = expectation(description: #function)

        DB.increment(1, at: "test") { (success) in
            XCTAssert(success)

            DB.get("test") { (snapshot) in
                XCTAssertEqual(snapshot?.value as? Int ?? 0, 1)
                x.fulfill()
            }
        }

        waitForExpectations(timeout: 10)
    }

    func testConcurrentIncrement() {
        let x = expectation(description: #function)

        let incrementsDone = DispatchGroup()

        for _ in 1...2 {
            incrementsDone.enter()
            DB.increment(1, at: "test") { (success) in
                XCTAssert(success)
                incrementsDone.leave()
            }
        }

        incrementsDone.notify(queue: .main) {
            DB.get("test") { (snapshot) in
                XCTAssertEqual(snapshot?.value as? Int ?? 0, 2)
                x.fulfill()
            }
        }
        
        waitForExpectations(timeout: 10)
    }
}
