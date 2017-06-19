//
//  DBProxyTests.swift
//  proxy
//
//  Created by Quan Vo on 6/14/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import XCTest
@testable import proxy
import FirebaseDatabase

class DBProxyTests: DBTest {}

extension DBProxyTests {
    func testLoadProxyInfo() {
        x = expectation(description: #function)

        DBProxy.loadProxyInfo { (success) in
            XCTAssert(success)
            XCTAssert(Shared.shared.proxyInfoIsLoaded)
            self.x.fulfill()
        }

        waitForExpectations(timeout: 10)
    }

    func testCreateProxy() {
        x = expectation(description: #function)

        DBProxy.createProxy { (result) in
            switch result {
            case .failure(_):
                XCTFail()
            case .success(let proxy):
                DBProxy.deleteProxy(proxy) { (success) in
                    XCTAssert(success)
                    self.x.fulfill()
                }
            }
        }

        waitForExpectations(timeout: 10)
    }

    func testCancelMakingProxy() {
        Shared.shared.isCreatingProxy = true
        DBProxy.cancelCreatingProxy()
        XCTAssertFalse(Shared.shared.isCreatingProxy)
    }
}

extension DBProxyTests {
    func testGetProxy() {
        x = expectation(description: #function)

        DBProxy.createProxy { (result) in
            switch result {
            case .failure(_):
                XCTFail()
            case .success(let newProxy):
                DBProxy.getProxy(key: newProxy.key) { (result) in
                    DBProxy.deleteProxy(newProxy) { (success) in
                        XCTAssert(success)
                        switch result {
                        case .failure(_):
                            XCTFail()
                        case .success(let retrievedProxy):
                            XCTAssert(retrievedProxy == newProxy)
                            self.x.fulfill()
                        }
                    }
                }
            }
        }

        waitForExpectations(timeout: 10)
    }

    func testGetProxyWithOwnerId() {
        x = expectation(description: #function)

        DBProxy.createProxy { (result) in
            switch result {
            case .failure(_):
                XCTFail()
            case .success(let newProxy):
                DBProxy.getProxy(key: newProxy.key, ownerId: newProxy.ownerId) { (result) in
                    DBProxy.deleteProxy(newProxy) { (success) in
                        XCTAssert(success)
                        switch result {
                        case .failure(_):
                            XCTFail()
                        case .success(let retrievedProxy):
                            XCTAssert(retrievedProxy == newProxy)
                            self.x.fulfill()
                        }
                    }
                }
            }
        }

        waitForExpectations(timeout: 10)
    }
}

extension DBProxyTests {
    func testSetIcon() {
        x = expectation(description: #function)

        DBProxy.createProxy { (result) in
            switch result {
            case .failure(_):
                XCTFail()
            case .success(let proxy):
                DBProxy.setIcon("new icon", forProxy: proxy) { (setIconSuccess) in
                    DBProxy.getProxy(key: proxy.key, ownerId: proxy.ownerId) { (getProxyWithNewIconResult) in
                        DBProxy.deleteProxy(proxy) { (deleteProxySuccess) in
                            XCTAssert(setIconSuccess)
                            XCTAssert(deleteProxySuccess)
                            switch getProxyWithNewIconResult {
                            case .failure(_):
                                XCTFail()
                            case .success(let proxyWithNewIcon):
                                XCTAssertEqual(proxyWithNewIcon.icon, "new icon")
                                self.x.fulfill()
                            }
                        }
                    }
                }
            }
        }

        waitForExpectations(timeout: 10)
    }

    func testSetNickname() {
        x = expectation(description: #function)

        DBProxy.createProxy { (result) in
            switch result {
            case .failure(_):
                XCTFail()
            case .success(let proxy):
                DBProxy.setNickname("new nickname", forProxy: proxy) { (setNicknameSuccess) in
                    DBProxy.getProxy(key: proxy.key, ownerId: proxy.ownerId) { (getProxyWithNewNicknameResult) in
                        DBProxy.deleteProxy(proxy) { (deleteProxySuccess) in
                            XCTAssert(setNicknameSuccess)
                            XCTAssert(deleteProxySuccess)
                            switch getProxyWithNewNicknameResult {
                            case .failure(_):
                                XCTFail()
                            case .success(let proxyWithNewNickname):
                                XCTAssertEqual(proxyWithNewNickname.nickname, "new nickname")
                                self.x.fulfill()
                            }
                        }
                    }
                }
            }
        }

        waitForExpectations(timeout: 10)
    }

    func testDeleteProxy() {
        x = expectation(description: #function)

        DBProxy.createProxy { (result) in
            switch result {
            case .failure(_):
                XCTFail()
            case .success(let proxy):
                let unreadIncremented = DispatchGroup()
                for _ in 1...2 {
                    unreadIncremented.enter()
                }

                DB.set(1, children: Path.Unread, Shared.shared.uid, Path.Unread) { (success) in
                    XCTAssert(success)
                    unreadIncremented.leave()
                }

                DB.set(1, children: Path.Proxies, Shared.shared.uid, proxy.key, Path.Unread) { (success) in
                    XCTAssert(success)
                    unreadIncremented.leave()
                }

                unreadIncremented.notify(queue: .main) {
                    DBProxy.deleteProxy(proxy) { (success) in
                        XCTAssert(success)

                        let endpointsDeleted = DispatchGroup()
                        for _ in 1...4 {
                            endpointsDeleted.enter()
                        }

                        DB.get(Path.Proxies, Shared.shared.uid, proxy.key) { (snapshot) in
                            XCTAssertEqual(snapshot?.value as? FirebaseDatabase.NSNull, FirebaseDatabase.NSNull())
                            endpointsDeleted.leave()
                        }

                        DB.get(Path.Proxies, Path.Key, proxy.key) { (snapshot) in
                            XCTAssertEqual(snapshot?.value as? FirebaseDatabase.NSNull, FirebaseDatabase.NSNull())
                            endpointsDeleted.leave()
                        }

                        DB.get(Path.Proxies, Path.Name, proxy.key) { (snapshot) in
                            XCTAssertEqual(snapshot?.value as? FirebaseDatabase.NSNull, FirebaseDatabase.NSNull())
                            endpointsDeleted.leave()
                        }
                        
                        DB.get(Path.Unread, Shared.shared.uid, Path.Unread, completion: { (snapshot) in
                            XCTAssertEqual(snapshot?.value as? Int ?? Int.max, 0)
                            endpointsDeleted.leave()
                        })
                        
                        endpointsDeleted.notify(queue: .main) {
                            self.x.fulfill()
                        }
                    }
                }
            }
        }

        waitForExpectations(timeout: 10)
    }
}
