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

class DBTest: XCTestCase {
    private let auth = Auth.auth(app: Shared.shared.firebase!)
    private var handle: AuthStateDidChangeListenerHandle?

    private let email = "emydadu-3857@yopmail.com"
    private let password = "+7rVajX5sYNRL[kZ"

    var x = XCTestExpectation()

    let clearDatabaseDone = DispatchGroup()

    override func setUp() {
        x = expectation(description: #function)

        handle = auth.addStateDidChangeListener { [weak self] (auth, user) in
            guard let strong = self else {
                return
            }

            if let uid = user?.uid {
                Shared.shared.uid = uid

                strong.deleteTestData()
                strong.deleteProxies()

                strong.clearDatabaseDone.notify(queue: .main) {
                    strong.x.fulfill()
                }

            } else {
                auth.signIn(withEmail: strong.email, password: strong.password) { (user, error) in
                    XCTAssertNil(error)
                }
            }
        }

        waitForExpectations(timeout: 10)
    }

    deinit {
        if let handle = handle {
            auth.removeStateDidChangeListener(handle)
        }
    }
}

private extension DBTest {
    func deleteTestData() {
        clearDatabaseDone.enter()

        DB.delete("test") { (success) in
            XCTAssert(success)
            self.clearDatabaseDone.leave()
        }
    }

    func deleteProxies() {
        clearDatabaseDone.enter()

        DB.get(Path.Proxies, Shared.shared.uid) { (snapshot) in
            guard let proxies = snapshot?.toProxies() else {
                self.clearDatabaseDone.leave()
                return
            }

            let deleteProxiesDone = DispatchGroup()

            for proxy in proxies {
                deleteProxiesDone.enter()

                DBProxy.deleteProxy(proxy) { (success) in
                    XCTAssert(success)
                    deleteProxiesDone.leave()
                }
            }

            deleteProxiesDone.notify(queue: .main) {
                self.clearDatabaseDone.leave()
            }
        }
    }
}
