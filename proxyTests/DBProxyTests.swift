import XCTest
@testable import proxy
import FirebaseDatabase

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
            workKey.checkProxyCount(forOwnerOfProxy: proxy, equals: 1)
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
                workKey.checkProxyCount(forOwnerOfProxy: proxy, equals: 0)
                workKey.checkProxyDeleted(proxy)
                workKey.checkProxyKeyDeleted(forProxy: proxy)
                workKey.checkProxyOwnerDeleted(forProxy: proxy)
                workKey.checkReceiverDeletedProxy(forProxyConvo: convo)
                workKey.checkReceiverDeletedProxy(forUserConvo: convo)
                workKey.checkUnread(forOwnerOfProxy: proxy, equals: -1)
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

            DBProxy.setIcon(icon, forProxy: proxy) { (success) in
                XCTAssert(success)

                let workKey = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
                workKey.checkIcon(forProxy: proxy, equals: icon)
                workKey.checkIcon(forProxyConvo: convo, equals: icon)
                workKey.checkIcon(forUserConvo: convo, equals: icon)
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

            DBProxy.setNickname(nickname, forProxy: proxy) { (success) in
                XCTAssert(success)

                let workKey = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
                workKey.checkNickname(forProxy: proxy, equals: nickname)
                workKey.checkNickname(forProxyConvo: convo, equals: nickname)
                workKey.checkNickname(forUserConvo: convo, equals: nickname)
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

    func checkIcon(forProxy proxy: Proxy, equals icon: String) {
        startWork()
        DB.get(Path.Proxies, proxy.ownerId, proxy.key, Path.Icon) { (data) in
            XCTAssertEqual(data?.value as? String, icon)
            self.finishWork(withResult: true)
        }
    }

    func checkIcon(forProxyConvo convo: Convo, equals icon: String) {
        startWork()
        DB.get(Path.Convos, convo.receiverProxyKey, convo.key, Path.Icon) { (data) in
            XCTAssertEqual(data?.value as? String, icon)
            self.finishWork(withResult: true)
        }
    }

    func checkIcon(forUserConvo convo: Convo, equals icon: String) {
        startWork()
        DB.get(Path.Convos, convo.receiverId, convo.key, Path.Icon) { (data) in
            XCTAssertEqual(data?.value as? String, icon)
            self.finishWork(withResult: true)
        }
    }

    func checkNickname(forProxy proxy: Proxy, equals nickname: String) {
        startWork()
        DB.get(Path.Proxies, proxy.ownerId, proxy.key, Path.Nickname) { (data) in
            XCTAssertEqual(data?.value as? String, nickname)
            self.finishWork(withResult: true)
        }
    }

    func checkNickname(forProxyConvo convo: Convo, equals nickname: String) {
        startWork()
        DB.get(Path.Convos, convo.senderProxyKey, convo.key, Path.SenderNickname) { (data) in
            XCTAssertEqual(data?.value as? String, nickname)
            self.finishWork(withResult: true)
        }
    }

    func checkNickname(forUserConvo convo: Convo, equals nickname: String) {
        startWork()
        DB.get(Path.Convos, convo.senderId, convo.key, Path.SenderNickname) { (data) in
            XCTAssertEqual(data?.value as? String, nickname)
            self.finishWork(withResult: true)
        }
    }

    func checkProxyCount(forOwnerOfProxy proxy: Proxy, equals proxyCount: Int) {
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
            XCTAssertEqual(data?.value as? Bool, true)
            self.finishWork(withResult: true)
        }
    }

    func checkReceiverDeletedProxy(forUserConvo convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.receiverId, convo.key, Path.ReceiverDeletedProxy) { (data) in
            XCTAssertEqual(data?.value as? Bool, true)
            self.finishWork(withResult: true)
        }
    }

    func checkUnread(forOwnerOfProxy proxy: Proxy, equals unread: Int) {
        startWork()
        DB.get(Path.UserInfo, proxy.ownerId, Path.Unread) { (data) in
            XCTAssertEqual(data?.value as? Int, unread)
            self.finishWork(withResult: true)
        }
    }
}
