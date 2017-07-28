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

            let workKey = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
            workKey.checkProxyKey(proxy: proxy)
            workKey.checkProxyOwner(proxy: proxy)
            workKey.checkProxy(proxy)
            workKey.checkProxyCountForOwnerOfProxy(proxy)
            workKey.notify {
                workKey.finishWorkGroup()
                self.x.fulfill()
            }
        }
    }
}

private extension AsyncWorkGroupKey {
    func checkProxyKey(proxy: Proxy) {
        startWork()
        DB.get(Path.ProxyKeys, proxy.key) { (data) in
            XCTAssertEqual(data?.value as? [String: String] ?? [:], [Path.Key: proxy.key])
            self.finishWork(withResult: true)
        }
    }

    func checkProxyOwner(proxy: Proxy) {
        startWork()
        DB.get(Path.ProxyOwners, proxy.key) { (data) in
            XCTAssertEqual(ProxyOwner(data?.value as AnyObject), ProxyOwner(key: proxy.key, ownerId: Shared.shared.uid))
            self.finishWork(withResult: true)
        }
    }

    func checkProxy(_ proxy: Proxy) {
        startWork()
        DB.get(Path.Proxies, Shared.shared.uid, proxy.key) { (data) in
            XCTAssertEqual(Proxy(data?.value as AnyObject), proxy)
            self.finishWork(withResult: true)
        }
    }

    func checkProxyCountForOwnerOfProxy(_ proxy: Proxy) {
        startWork()
        DB.get(Path.UserInfo, proxy.ownerId, Path.ProxyCount) { (data) in
            XCTAssertEqual(data?.value as? Int ?? 0, 1)
            self.finishWork(withResult: true)
        }
    }
}

extension DBProxyTests {
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
            let icon = "new icon"

            DBProxy.setIcon(icon, forProxy: proxy) { (success) in
                XCTAssert(success)

                let workKey = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
                workKey.checkProxyIcon(proxy: proxy, icon: icon)
                workKey.checkUserConvoIcon(convo: convo, icon: icon)
                workKey.checkProxyConvoIcon(convo: convo, icon: icon)
                workKey.notify {
                    workKey.finishWorkGroup()
                    self.x.fulfill()
                }
            }
        }
    }
}

private extension AsyncWorkGroupKey {
    func checkProxyIcon(proxy: Proxy, icon: String) {
        startWork()
        DB.get(Path.Proxies, proxy.ownerId, proxy.key, Path.Icon) { (data) in
            XCTAssertEqual(data?.value as? String, icon)
            self.finishWork(withResult: true)
        }
    }

    func checkUserConvoIcon(convo: Convo, icon: String) {
        startWork()
        DB.get(Path.Convos, convo.receiverId, convo.key, Path.Icon) { (data) in
            XCTAssertEqual(data?.value as? String, icon)
            self.finishWork(withResult: true)
        }
    }

    func checkProxyConvoIcon(convo: Convo, icon: String) {
        startWork()
        DB.get(Path.Convos, convo.receiverProxyKey, convo.key, Path.Icon) { (data) in
            XCTAssertEqual(data?.value as? String, icon)
            self.finishWork(withResult: true)
        }
    }
}

extension DBProxyTests {
    func testSetNickname() {
        x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (convo, proxy, _) in
            let nickname = "nickname"

            DBProxy.setNickname(nickname, forProxy: proxy) { (success) in
                XCTAssert(success)

                let workKey = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
                workKey.checkProxyNickname(proxy: proxy, nickname: nickname)
                workKey.checkUserConvoNickname(convo: convo, nickname: nickname)
                workKey.checkProxyConvoNickname(convo: convo, nickname: nickname)
                workKey.notify {
                    workKey.finishWorkGroup()
                    self.x.fulfill()
                }
            }
        }
    }
}

private extension AsyncWorkGroupKey {
    func checkProxyNickname(proxy: Proxy, nickname: String) {
        startWork()
        DB.get(Path.Proxies, proxy.ownerId, proxy.key, Path.Nickname) { (data) in
            XCTAssertEqual(data?.value as? String, nickname)
            self.finishWork(withResult: true)
        }
    }

    func checkUserConvoNickname(convo: Convo, nickname: String) {
        startWork()
        DB.get(Path.Convos, convo.senderId, convo.key, Path.SenderNickname) { (data) in
            XCTAssertEqual(data?.value as? String, nickname)
            self.finishWork(withResult: true)
        }
    }

    func checkProxyConvoNickname(convo: Convo, nickname: String) {
        startWork()
        DB.get(Path.Convos, convo.senderProxyKey, convo.key, Path.SenderNickname) { (data) in
            XCTAssertEqual(data?.value as? String, nickname)
            self.finishWork(withResult: true)
        }
    }
}

extension DBProxyTests {
    func testDeleteProxy() {
        x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (convo, proxy, _) in
            var proxy = proxy
            proxy.unread = 1

            DBProxy.deleteProxy(proxy) { (success) in
                XCTAssert(success)

                let workKey = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
                workKey.checkProxyKeyDeleted(proxy: proxy)
                workKey.checkProxyOwnerDeleted(proxy: proxy)
                workKey.checkProxyDeleted(proxy: proxy)
                workKey.checkConvosForProxyDeleted(proxy: proxy)
                workKey.checkUserConvoDeleted(convo: convo)
                workKey.checkReceiverDeletedProxyForUserConvo(convo: convo)
                workKey.checkReceiverDeletedProxyForProxyConvo(convo: convo)
                workKey.checkUnreadForProxyOwnerDecremented(proxy: proxy)
                workKey.checkProxyCountForProxyOwnerDecremented(proxy: proxy)
                workKey.notify {
                    workKey.finishWorkGroup()
                    self.x.fulfill()
                }
            }
        }
    }
}

private extension AsyncWorkGroupKey {
    func checkProxyKeyDeleted(proxy: Proxy) {
        startWork()
        DB.get(Path.ProxyKeys, proxy.key) { (data) in
            XCTAssertEqual(data?.value as? FirebaseDatabase.NSNull, FirebaseDatabase.NSNull())
            self.finishWork(withResult: true)
        }
    }

    func checkProxyOwnerDeleted(proxy: Proxy) {
        startWork()
        DB.get(Path.ProxyOwners, proxy.key) { (data) in
            XCTAssertEqual(data?.value as? FirebaseDatabase.NSNull, FirebaseDatabase.NSNull())
            self.finishWork(withResult: true)
        }
    }

    func checkProxyDeleted(proxy: Proxy) {
        startWork()
        DB.get(Path.Proxies, proxy.ownerId, proxy.key) { (data) in
            XCTAssertEqual(data?.value as? FirebaseDatabase.NSNull, FirebaseDatabase.NSNull())
            self.finishWork(withResult: true)
        }
    }

    func checkConvosForProxyDeleted(proxy: Proxy) {
        startWork()
        DB.get(Path.Convos, proxy.key) { (data) in
            XCTAssertEqual(data?.value as? FirebaseDatabase.NSNull, FirebaseDatabase.NSNull())
            self.finishWork(withResult: true)
        }
    }

    func checkUserConvoDeleted(convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.senderId, convo.key) { (data) in
            XCTAssertEqual(data?.value as? FirebaseDatabase.NSNull, FirebaseDatabase.NSNull())
            self.finishWork(withResult: true)
        }
    }

    func checkReceiverDeletedProxyForUserConvo(convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.receiverId, convo.key, Path.ReceiverDeletedProxy) { (data) in
            XCTAssertEqual(data?.value as? Bool, true)
            self.finishWork(withResult: true)
        }
    }

    func checkReceiverDeletedProxyForProxyConvo(convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.receiverProxyKey, convo.key, Path.ReceiverDeletedProxy) { (data) in
            XCTAssertEqual(data?.value as? Bool, true)
            self.finishWork(withResult: true)
        }
    }

    func checkUnreadForProxyOwnerDecremented(proxy: Proxy) {
        startWork()
        DB.get(Path.UserInfo, proxy.ownerId, Path.Unread) { (data) in
            XCTAssertEqual(data?.value as? Int, -1)
            self.finishWork(withResult: true)
        }
    }

    func checkProxyCountForProxyOwnerDecremented(proxy: Proxy) {
        startWork()
        DB.get(Path.UserInfo, proxy.ownerId, Path.ProxyCount) { (data) in
            XCTAssertEqual(data?.value as? Int, 0)
            self.finishWork(withResult: true)
        }
    }
}
