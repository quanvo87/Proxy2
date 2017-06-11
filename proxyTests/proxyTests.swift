//
//  proxyTests.swift
//  proxyTests
//
//  Created by Quan Vo on 6/6/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import XCTest
@testable import proxy

class proxyTests: XCTestCase {
    func test() {
        let x = self.expectation(description: #function)

        let val = Int(arc4random_uniform(UInt32.max))

        DB.set(val, pathNodes: "a", "b") { (success) in
            XCTAssert(success)

            DB.get("a", "b", completion: { (snapshot) in
                guard
                    let snapshot = snapshot,
                    let value = snapshot.value as? Int else {
                        XCTFail()
                        return
                }
                XCTAssertEqual(value, val)
                x.fulfill()
            })
        }

        waitForExpectations(timeout: 5)
    }

    func test1() {
        let x = self.expectation(description: #function)

        DBIcon.getIconNames { (iconNames, error) in
            XCTAssertNil(error)
            print(iconNames ?? "")
            x.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    //    func test2() {
    //        let x = self.expectation(description: #function)
    //
    //
    //
    //        waitForExpectations(timeout: 10)
    //    }
    //
    //    func test3() {
    //        let x = self.expectation(description: #function)
    //
    //
    //
    //        waitForExpectations(timeout: 10)
    //    }
}
