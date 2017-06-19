//
//  DB.swift
//  proxy
//
//  Created by Quan Vo on 6/14/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import XCTest
@testable import proxy
import FirebaseAuth
import FirebaseDatabase

class DBTest: XCTestCase {
    private let auth = Auth.auth(app: Shared.shared.firebase!)
    private var handle: AuthStateDidChangeListenerHandle?

    private let email = "emydadu-3857@yopmail.com"
    private let password = "+7rVajX5sYNRL[kZ"

    var x = XCTestExpectation()

    override func setUp() {
        x = expectation(description: #function)

        handle = auth.addStateDidChangeListener { [weak self] (auth, user) in
            if let uid = user?.uid {
                Shared.shared.uid = uid

                DB.delete("test") { (success) in
                    XCTAssert(success)
                    self?.x.fulfill()
                }
            } else {
                guard let strong = self else {
                    return
                }
                auth.signIn(withEmail: strong.email, password: strong.password) { (user, error) in
                    XCTAssertNil(error)
                }
            }
        }

        waitForExpectations(timeout: 10)
    }

    override func tearDown() {
        x = expectation(description: #function)
        DB.delete("test") { (success) in
            XCTAssert(success)
            self.x.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

    deinit {
        if let handle = handle {
            auth.removeStateDidChangeListener(handle)
        }
    }
}
