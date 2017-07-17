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

class DBProxyTests: DBTest {
    func testLoadProxyInfo() {
        x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBProxy.loadProxyInfo { (success) in
            XCTAssert(success)
            XCTAssertFalse(Shared.shared.adjectives.isEmpty)
            XCTAssertFalse(Shared.shared.nouns.isEmpty)
            XCTAssertFalse(Shared.shared.iconNames.isEmpty)
            self.x.fulfill()
        }
    }

    func testCreateProxy() {
        x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeProxy { (proxy) in
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

    func testCreatProxyAtProxyLimit() {
        x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DB.set(50, at: Path.UserInfo, Shared.shared.uid, Path.ProxyCount) { (success) in
            XCTAssert(success)

            DBProxy.makeProxy { (result) in
                switch result {
                case .failure(let error):
                    XCTAssertEqual(error, ProxyError(.proxyLimitReached))
                    self.x.fulfill()
                case .success: XCTFail()
                }
            }
        }
    }

    func testCreateProxyWithExistingName() {
        x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBProxy.makeProxy(withName: "test") { (result) in
            switch result {
            case .failure: XCTFail()
            case .success:
                DBProxy.makeProxy(withName: "test") { (result) in
                    switch result {
                    case .failure:
                        XCTAssertFalse(Shared.shared.isCreatingProxy)
                        self.x.fulfill()
                    case .success: XCTFail()
                    }
                }
            }
        }
    }

    func testCancelMakingProxy() {
        Shared.shared.isCreatingProxy = true
        DBProxy.cancelCreatingProxy()
        XCTAssertFalse(Shared.shared.isCreatingProxy)
    }

    func testGetProxy() {
        x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeProxy { (proxy) in
            DBProxy.getProxy(withKey: proxy.key) { (retrievedProxy) in
                XCTAssertEqual(retrievedProxy, proxy)
                self.x.fulfill()
            }
        }
    }

    func testGetProxyNotFound() {
        x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBProxy.getProxy(withKey: "invalid key") { (proxy) in
            XCTAssertNil(proxy)
            self.x.fulfill()
        }
    }

    func testGetProxyWithOwnerId() {
        x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeProxy { (proxy) in
            DBProxy.getProxy(withKey: proxy.key, belongingTo: proxy.ownerId) { (retrievedProxy) in
                XCTAssertEqual(retrievedProxy, proxy)
                self.x.fulfill()
            }
        }
    }

    func testGetProxyWithOwnerIdNotFound() {
        x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBProxy.getProxy(withKey: "invalid key", belongingTo: Shared.shared.uid) { (proxy) in
            XCTAssertNil(proxy)
            self.x.fulfill()
        }
    }

    func testGetProxiesForUser() {
        x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeProxy { (proxy) in
            DBProxy.getProxies(forUser: proxy.ownerId) { (proxies) in
                XCTAssertEqual(proxies?.count, 1)
                XCTAssertEqual(proxies?[0], proxy)
                self.x.fulfill()
            }
        }
    }

    func testSetIcon() {
        x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (convo, proxy, _) in
            let newIcon = "new icon"

            DBProxy.setIcon(newIcon, forProxy: proxy) { (success) in
                XCTAssert(success)

                let setIconChecked = DispatchGroup()
                for _ in 1...3 {
                    setIconChecked.enter()
                }

                DB.get(Path.Proxies, proxy.ownerId, proxy.key, Path.Icon) { (data) in
                    XCTAssertEqual(data?.value as? String, newIcon)
                    setIconChecked.leave()
                }

                DB.get(Path.Convos, convo.receiverId, convo.key, Path.Icon) { (data) in
                    XCTAssertEqual(data?.value as? String, newIcon)
                    setIconChecked.leave()
                }

                DB.get(Path.Convos, convo.receiverProxyKey, convo.key, Path.Icon) { (data) in
                    XCTAssertEqual(data?.value as? String, newIcon)
                    setIconChecked.leave()
                }

                setIconChecked.notify(queue: .main) {
                    self.x.fulfill()
                }
            }
        }
    }

    func testSetNickname() {
        x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (convo, proxy, _) in
            let nickname = "nickname"

            DBProxy.setNickname(nickname, forProxy: proxy) { (success) in
                XCTAssert(success)

                let setNicknameChecked = DispatchGroup()
                for _ in 1...3 {
                    setNicknameChecked.enter()
                }

                DB.get(Path.Proxies, proxy.ownerId, proxy.key, Path.Nickname) { (data) in
                    XCTAssertEqual(data?.value as? String, nickname)
                    setNicknameChecked.leave()
                }

                DB.get(Path.Convos, convo.senderId, convo.key, Path.SenderNickname) { (data) in
                    XCTAssertEqual(data?.value as? String, nickname)
                    setNicknameChecked.leave()
                }

                DB.get(Path.Convos, convo.senderProxyKey, convo.key, Path.SenderNickname) { (data) in
                    XCTAssertEqual(data?.value as? String, nickname)
                    setNicknameChecked.leave()
                }

                setNicknameChecked.notify(queue: .main) {
                    self.x.fulfill()
                }
            }
        }
    }

    func testDeleteProxy() {
        x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (convo, proxy, _) in
            var proxy = proxy
            proxy.unread = 1

            DBProxy.deleteProxy(proxy) { (success) in
                XCTAssert(success)

                let deleteProxyChecked = DispatchGroup()
                for _ in 1...9 {
                    deleteProxyChecked.enter()
                }

                DB.get(Path.ProxyKeys, proxy.key) { (data) in
                    XCTAssertEqual(data?.value as? FirebaseDatabase.NSNull, FirebaseDatabase.NSNull())
                    deleteProxyChecked.leave()
                }

                DB.get(Path.ProxyOwners, proxy.key) { (data) in
                    XCTAssertEqual(data?.value as? FirebaseDatabase.NSNull, FirebaseDatabase.NSNull())
                    deleteProxyChecked.leave()
                }

                DB.get(Path.Proxies, proxy.ownerId, proxy.key) { (data) in
                    XCTAssertEqual(data?.value as? FirebaseDatabase.NSNull, FirebaseDatabase.NSNull())
                    deleteProxyChecked.leave()
                }

                DB.get(Path.Convos, proxy.key) { (data) in
                    XCTAssertEqual(data?.value as? FirebaseDatabase.NSNull, FirebaseDatabase.NSNull())
                    deleteProxyChecked.leave()
                }

                DB.get(Path.Convos, convo.senderId, convo.key) { (data) in
                    XCTAssertEqual(data?.value as? FirebaseDatabase.NSNull, FirebaseDatabase.NSNull())
                    deleteProxyChecked.leave()
                }

                DB.get(Path.Convos, convo.receiverId, convo.key, Path.ReceiverDeletedProxy) { (data) in
                    XCTAssertEqual(data?.value as? Bool, true)
                    deleteProxyChecked.leave()
                }

                DB.get(Path.Convos, convo.receiverProxyKey, convo.key, Path.ReceiverDeletedProxy) { (data) in
                    XCTAssertEqual(data?.value as? Bool, true)
                    deleteProxyChecked.leave()
                }

                DB.get(Path.UserInfo, proxy.ownerId, Path.Unread) { (data) in
                    XCTAssertEqual(data?.value as? Int, -1)
                    deleteProxyChecked.leave()
                }

                DB.get(Path.UserInfo, proxy.ownerId, Path.ProxyCount) { (data) in
                    XCTAssertEqual(data?.value as? Int, 0)
                    deleteProxyChecked.leave()
                }

                deleteProxyChecked.notify(queue: .main) {
                    self.x.fulfill()
                }
            }
        }
    }
}
