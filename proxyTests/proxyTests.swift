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
        let expectation = self.expectation(description: #function)

        let val = Int(arc4random_uniform(UInt32.max))

        DB.set(val, pathNodes: "a", "b") { (error) in
            XCTAssertNil(error)

            DB.get("a", "b", completion: { (snapshot) in
                XCTAssertEqual(snapshot.value as? Int, val)
                expectation.fulfill()
            })
        }

        waitForExpectations(timeout: 10)
    }
}
