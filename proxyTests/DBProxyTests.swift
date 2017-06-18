//
//  DBProxyTests.swift
//  proxy
//
//  Created by Quan Vo on 6/14/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import XCTest
@testable import proxy
import FirebaseAuth

class DBProxyTests: DBTest {}

extension DBProxyTests {
    func testLoadProxyInfo() {
        let x = expectation(description: #function)

        DBProxy.loadProxyInfo { (success) in
            XCTAssert(success)
            XCTAssert(Shared.shared.proxyInfoIsLoaded)
            x.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testCreateProxy() {
        let x = expectation(description: #function)

        DBProxy.createProxy { (result) in
            switch result {
            case .failure(_):
                XCTFail()
            case .success(let proxy):
                DBProxy.deleteProxy(proxy, completion: { (success) in
                    XCTAssert(success)
                    x.fulfill()
                })
            }
        }

        waitForExpectations(timeout: 5)

    }

    func testCancelMakingProxy() {
        Shared.shared.isCreatingProxy = true
        DBProxy.cancelCreatingProxy()
        XCTAssertFalse(Shared.shared.isCreatingProxy)
    }


}
