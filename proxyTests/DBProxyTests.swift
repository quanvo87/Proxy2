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
            XCTAssertFalse(Shared.shared.adjectives.isEmpty)
            XCTAssertFalse(Shared.shared.nouns.isEmpty)
            XCTAssertFalse(Shared.shared.iconNames.isEmpty)
            self.x.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

    func testCreateProxy() {
        x = expectation(description: #function)

        DBProxy.createProxy(forUser: Shared.shared.uid) { (result) in
            switch result {
            case .failure:
                XCTFail()
            case .success(let proxy):
                XCTAssertFalse(Shared.shared.isCreatingProxy)

                let proxyDataChecked = DispatchGroup()

                for _ in 1...4 {
                    proxyDataChecked.enter()
                }

                DB.get(Path.ProxyKeys, proxy.key) { (data) in
                    XCTAssertEqual(data?.value as? [String: String] ?? [:], [Path.Key: proxy.key])
                    proxyDataChecked.leave()
                }

                DB.get(Path.ProxyOwners, proxy.key) { (data) in
                    XCTAssertEqual(ProxyOwner(data?.value as AnyObject), ProxyOwner(key: proxy.key, ownerId: Shared.shared.uid))
                    proxyDataChecked.leave()
                }

                DB.get(Path.Proxies, Shared.shared.uid, proxy.key) { (data) in
                    XCTAssertEqual(Proxy(data?.value as AnyObject), proxy)
                    proxyDataChecked.leave()
                }

                DB.get(Path.UserInfo, Shared.shared.uid, Path.ProxyCount) { (data) in
                    XCTAssertEqual(data?.value as? Int ?? 0, 1)
                    proxyDataChecked.leave()
                }

                proxyDataChecked.notify(queue: .main) {
                    self.x.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 10)
    }

    func testCreateProxyWithExistingName() {
        x = expectation(description: #function)

        DBProxy.createProxy(withName: "test") { (result) in
            switch result {
            case .failure:
                XCTFail()
            case .success:
                DBProxy.createProxy(withName: "test") { (result) in
                    switch result {
                    case .failure:
                        XCTAssertFalse(Shared.shared.isCreatingProxy)
                        self.x.fulfill()
                    case .success:
                        XCTFail()
                    }
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
            case .failure:
                XCTFail()
            case .success(let newProxy):
                DBProxy.getProxy(withKey: newProxy.key) { (retrievedProxy) in
                    XCTAssertEqual(retrievedProxy, newProxy)
                    self.x.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 10)
    }

    func testGetProxyNotFound() {
        x = expectation(description: #function)

        DBProxy.getProxy(withKey: "not a proxy") { (proxy) in
            XCTAssertNil(proxy)
            self.x.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

    func testGetProxyWithOwnerId() {
        x = expectation(description: #function)

        DBProxy.createProxy { (result) in
            switch result {
            case .failure:
                XCTFail()
            case .success(let newProxy):
                DBProxy.getProxy(withKey: newProxy.key, belongingTo: newProxy.ownerId) { (retrievedProxy) in
                    XCTAssertEqual(retrievedProxy, newProxy)
                    self.x.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 10)
    }

    func testGetProxyWithOwnerIdNotFound() {
        x = expectation(description: #function)

        DBProxy.getProxy(withKey: "not a proxy", belongingTo: Shared.shared.uid) { (proxy) in
            XCTAssertNil(proxy)
            self.x.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

    func testGetProxiesForUser() {
        x = expectation(description: #function)

        DBProxy.createProxy { (result) in
            switch result {
            case .failure:
                XCTFail()
            case .success(let proxy):
                DBProxy.getProxies(forUser: Shared.shared.uid) { (proxies) in
                    XCTAssert(proxies?.contains(proxy) ?? false)
                    self.x.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 10)
    }
}

extension DBProxyTests {
    // TODO: - finish
//    func testSetIcon() {
//        x = expectation(description: #function)
//
//        DBProxy.createProxy { (result) in
//            switch result {
//            case .failure:
//                XCTFail()
//            case .success(let proxy):
//                var convo = DBTest.convo(senderId: proxy.ownerId, senderProxyKey: proxy.key)
//                convo.receiverId = testUser
//                convo.receiverProxyKey = testProxyKey
//
//                DB.set(convo.toJSON(), at: Path.Convos, convo.senderId, convo.key) { (success) in
//                    XCTAssert(success)
//
//                    let newIcon = "new icon"
//
//                    DBProxy.setIcon(newIcon, forProxy: proxy) { (success) in
//                        XCTAssert(success)
//
//                        let iconDataChecked = DispatchGroup()
//
//                        for _ in 1...3 {
//                            iconDataChecked.enter()
//                        }
//
//                        DBProxy.getProxy(key: proxy.key, ownerId: proxy.ownerId) { (proxyWithNewIcon) in
//                            XCTAssertEqual(proxyWithNewIcon?.icon, newIcon)
//                            iconDataChecked.leave()
//                        }
//
//                        DB.get(Path.Convos, convo.receiverId, convo.key, Path.Icon) { (data) in
//                            XCTAssertEqual(data?.value as? String ?? "", newIcon)
//                            iconDataChecked.leave()
//                        }
//
//                        DB.get(Path.Convos, convo.receiverProxyKey, convo.key, Path.Icon) { (data) in
//                            XCTAssertEqual(data?.value as? String ?? "", newIcon)
//                            iconDataChecked.leave()
//                        }
//
//                        iconDataChecked.notify(queue: .main) {
//                            self.x.fulfill()
//                        }
//                    }
//                }
//            }
//        }
//        waitForExpectations(timeout: 10)
//    }

    // TODO: - finish
    func testSetNickname() {
        x = expectation(description: #function)

        DBProxy.createProxy { (result) in
            switch result {
            case .failure:
                XCTFail()
            case .success(let proxy):
                DBProxy.setNickname("new nickname", forProxy: proxy) { (success) in
                    XCTAssert(success)

                    DBProxy.getProxy(withKey: proxy.key, belongingTo: proxy.ownerId) { (proxy) in
                        XCTAssertEqual(proxy?.nickname, "new nickname")
                        self.x.fulfill()
                    }
                }
            }
        }
        waitForExpectations(timeout: 10)
    }
}

extension DBProxyTests {
    // TODO: - finish
    func testDeleteProxy() {
        x = expectation(description: #function)

        DBProxy.createProxy { (result) in
            switch result {
            case .failure: XCTFail()
            case .success(let proxy):
                let proxySetup = DispatchGroup()

                for _ in 1...2 {
                    proxySetup.enter()
                }

                let convo = DBTest.convo(senderId: proxy.ownerId, senderProxyKey: proxy.key)
                DBTest.setConvoForProxy(convo) { (success) in
                    XCTAssert(success)
                    proxySetup.leave()
                }

                DB.set(1, at: Path.UserInfo, Shared.shared.uid, Path.Unread) { (success) in
                    XCTAssert(success)
                    proxySetup.leave()
                }

                var proxy = proxy
                proxy.unread = 1

                DBProxy.deleteProxy(proxy) { (success) in
                    XCTAssert(success)

                    let dataChecked = DispatchGroup()

                    self.assertNull(at: Path.Proxies, Shared.shared.uid, proxy.key, group: dataChecked)
                    self.assertNull(at: Path.Proxies, Path.Key, proxy.key, group: dataChecked)
                    self.assertNull(at: Path.Proxies, Path.Name, proxy.key, group: dataChecked)
                    self.assertValue(at: Path.UserInfo, Shared.shared.uid, Path.Unread, equals: 0, group: dataChecked)
                    self.assertValue(at: Path.UserInfo, Shared.shared.uid, Path.ProxyCount, equals: 0, group: dataChecked)

                    dataChecked.notify(queue: .main) {
                        self.x.fulfill()
                    }
                }
            }
        }
        waitForExpectations(timeout: 10)
    }
}
