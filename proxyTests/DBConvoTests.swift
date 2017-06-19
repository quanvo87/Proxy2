//
//  DBConvo.swift
//  proxy
//
//  Created by Quan Vo on 6/15/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import XCTest
@testable import proxy
import FirebaseDatabase

class DBConvoTests: DBTest {
    func testGetConvosFromSnapshot() throws {
        let x = expectation(description: #function)

        var convo1 = Convo()
        convo1.senderLeftConvo = false
        convo1.senderIsBlocking = false

        var convo2 = Convo()
        convo2.senderLeftConvo = true
        convo2.senderIsBlocking = true

        DB.set([(DB.path("test", "a"), convo1.toJSON()),
                (DB.path("test", "b"), convo2.toJSON())]) { (success) in
                    XCTAssert(success)

                    DB.get("test", completion: { (snapshot) in
                        let convos = snapshot?.toConvos()
                        XCTAssertEqual(convos?.count, 1)
                        x.fulfill()
                    })
        }
        
        waitForExpectations(timeout: 10)
    }
}
