//
//  DB.swift
//  proxy
//
//  Created by Quan Vo on 6/14/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import XCTest
@testable import proxy

class DBTest: XCTestCase {
    override func tearDown() {
        let x = self.expectation(description: #function)
        DB.delete("test") { (success) in
            XCTAssert(success)
            x.fulfill()
        }
        waitForExpectations(timeout: 5)
    }
}
