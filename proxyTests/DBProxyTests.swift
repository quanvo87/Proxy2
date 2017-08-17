import FirebaseDatabase
import XCTest
@testable import proxy

class DBProxyTests: DBTest {
    func testCancelMakingProxy() {
        Shared.shared.isCreatingProxy = true
        DBProxy.cancelCreatingProxy()
        XCTAssertFalse(Shared.shared.isCreatingProxy)
    }

    func testCreateProxy() {
        x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeProxy { (proxy) in
            XCTAssertFalse(Shared.shared.isCreatingProxy)

            let workKey = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
            workKey.checkProxyCount(equals: 1, forOwnerOfProxy: proxy)
            workKey.checkProxyCreated(proxy)
            workKey.checkProxyKeyCreated(forProxy: proxy)
            workKey.checkProxyOwnerCreated(forProxy: proxy)
            workKey.notify {
                workKey.finishWorkGroup()
                self.x.fulfill()
            }
        }
    }

    func testCreateProxyAtProxyLimit() {
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

    func testDeleteProxy() {
        x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (convo, proxy, _) in
            var proxy = proxy
            proxy.unread = 1

            DBProxy.deleteProxy(proxy) { (success) in
                XCTAssert(success)

                let workKey = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
                workKey.checkConvosDeleted(forProxy: proxy)
                workKey.checkProxyCount(equals: 0, forOwnerOfProxy: proxy)
                workKey.checkProxyDeleted(proxy)
                workKey.checkProxyKeyDeleted(forProxy: proxy)
                workKey.checkProxyOwnerDeleted(forProxy: proxy)
                workKey.checkReceiverDeletedProxy(forProxyConvo: convo)
                workKey.checkReceiverDeletedProxy(forUserConvo: convo)
                workKey.checkUnread(equals: -1, forOwnerOfProxy: proxy)
                workKey.checkUserConvoDeleted(convo)
                workKey.notify {
                    workKey.finishWorkGroup()
                    self.x.fulfill()
                }
            }
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

    func testSetIcon() {
        x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (convo, proxy, _) in
            let icon = "new icon"

            DBProxy.setIcon(to: icon, forProxy: proxy) { (success) in
                XCTAssert(success)

                let workKey = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
                workKey.checkIcon(equals: icon, forProxy: proxy)
                workKey.checkIcon(equals: icon, forProxyConvo: convo)
                workKey.checkIcon(equals: icon, forUserConvo: convo)
                workKey.notify {
                    workKey.finishWorkGroup()
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

            DBProxy.setNickname(to: nickname, forProxy: proxy) { (success) in
                XCTAssert(success)

                let workKey = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
                workKey.checkNickname(equals: nickname, forProxy: proxy)
                workKey.checkNickname(equals: nickname, forProxyConvo: convo)
                workKey.checkNickname(equals: nickname, forUserConvo: convo)
                workKey.notify {
                    workKey.finishWorkGroup()
                    self.x.fulfill()
                }
            }
        }
    }
}

extension AsyncWorkGroupKey {
    func checkConvosDeleted(forProxy proxy: Proxy) {
        startWork()
        DB.get(Path.Convos, proxy.key) { (data) in
            XCTAssertEqual(data?.value as? FirebaseDatabase.NSNull, FirebaseDatabase.NSNull())
            self.finishWork(withResult: true)
        }
    }

    func checkIcon(equals icon: String, forProxy proxy: Proxy) {
        startWork()
        DB.get(Path.Proxies, proxy.ownerId, proxy.key, Path.Icon) { (data) in
            XCTAssertEqual(data?.value as? String, icon)
            self.finishWork(withResult: true)
        }
    }

    func checkIcon(equals icon: String, forProxyConvo convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.receiverProxyKey, convo.key, Path.Icon) { (data) in
            XCTAssertEqual(data?.value as? String, icon)
            self.finishWork(withResult: true)
        }
    }

    func checkIcon(equals icon: String, forUserConvo convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.receiverId, convo.key, Path.Icon) { (data) in
            XCTAssertEqual(data?.value as? String, icon)
            self.finishWork(withResult: true)
        }
    }

    func checkNickname(equals nickname: String, forProxy proxy: Proxy) {
        startWork()
        DB.get(Path.Proxies, proxy.ownerId, proxy.key, Path.Nickname) { (data) in
            XCTAssertEqual(data?.value as? String, nickname)
            self.finishWork(withResult: true)
        }
    }

    func checkNickname(equals nickname: String, forProxyConvo convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.senderProxyKey, convo.key, Path.SenderNickname) { (data) in
            XCTAssertEqual(data?.value as? String, nickname)
            self.finishWork(withResult: true)
        }
    }

    func checkNickname(equals nickname: String, forUserConvo convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.senderId, convo.key, Path.SenderNickname) { (data) in
            XCTAssertEqual(data?.value as? String, nickname)
            self.finishWork(withResult: true)
        }
    }

    func checkProxyCount(equals proxyCount: Int, forOwnerOfProxy proxy: Proxy) {
        startWork()
        DB.get(Path.UserInfo, proxy.ownerId, Path.ProxyCount) { (data) in
            XCTAssertEqual(data?.value as? Int, proxyCount)
            self.finishWork(withResult: true)
        }
    }

    func checkProxyCreated(_ proxy: Proxy) {
        startWork()
        DB.get(Path.Proxies, Shared.shared.uid, proxy.key) { (data) in
            XCTAssertEqual(Proxy(data?.value as AnyObject), proxy)
            self.finishWork(withResult: true)
        }
    }

    func checkProxyDeleted(_ proxy: Proxy) {
        startWork()
        DB.get(Path.Proxies, proxy.ownerId, proxy.key) { (data) in
            XCTAssertEqual(data?.value as? FirebaseDatabase.NSNull, FirebaseDatabase.NSNull())
            self.finishWork(withResult: true)
        }
    }

    func checkProxyKeyCreated(forProxy proxy: Proxy) {
        startWork()
        DB.get(Path.ProxyKeys, proxy.key) { (data) in
            XCTAssertEqual(data?.value as? [String: String] ?? [:], [Path.Key: proxy.key])
            self.finishWork(withResult: true)
        }
    }

    func checkProxyKeyDeleted(forProxy proxy: Proxy) {
        startWork()
        DB.get(Path.ProxyKeys, proxy.key) { (data) in
            XCTAssertEqual(data?.value as? FirebaseDatabase.NSNull, FirebaseDatabase.NSNull())
            self.finishWork(withResult: true)
        }
    }

    func checkProxyOwnerCreated(forProxy proxy: Proxy) {
        startWork()
        DB.get(Path.ProxyOwners, proxy.key) { (data) in
            XCTAssertEqual(ProxyOwner(data?.value as AnyObject), ProxyOwner(key: proxy.key, ownerId: Shared.shared.uid))
            self.finishWork(withResult: true)
        }
    }

    func checkProxyOwnerDeleted(forProxy proxy: Proxy) {
        startWork()
        DB.get(Path.ProxyOwners, proxy.key) { (data) in
            XCTAssertEqual(data?.value as? FirebaseDatabase.NSNull, FirebaseDatabase.NSNull())
            self.finishWork(withResult: true)
        }
    }

    func checkReceiverDeletedProxy(forProxyConvo convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.receiverProxyKey, convo.key, Path.ReceiverDeletedProxy) { (data) in
            XCTAssert(data?.value as? Bool ?? false)
            self.finishWork(withResult: true)
        }
    }

    func checkReceiverDeletedProxy(forUserConvo convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.receiverId, convo.key, Path.ReceiverDeletedProxy) { (data) in
            XCTAssert(data?.value as? Bool ?? false)
            self.finishWork(withResult: true)
        }
    }

    func checkUnread(equals unread: Int, forOwnerOfProxy proxy: Proxy) {
        startWork()
        DB.get(Path.UserInfo, proxy.ownerId, Path.Unread) { (data) in
            XCTAssertEqual(data?.value as? Int, unread)
            self.finishWork(withResult: true)
        }
    }
}
