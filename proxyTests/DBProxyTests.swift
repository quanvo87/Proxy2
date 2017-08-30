import FirebaseDatabase
import XCTest
@testable import proxy

class DBProxyTests: DBTest {
    func testCancelMakingProxy() {
        Shared.shared.isCreatingProxy = true
        DBProxy.cancelCreatingProxy()
        XCTAssertFalse(Shared.shared.isCreatingProxy)
    }
    
    func testDeleteProxy() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }
        
        DBTest.makeConvo { (convo, proxy, _) in
            var proxy = proxy
            proxy.unreadCount = 2
            
            DBProxy.deleteProxy(proxy) { (success) in
                XCTAssert(success)
                let key = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
                key.check(.receiverDeletedProxy(true), forConvo: convo, asSender: false)
                key.check(.proxyCount, 0, forUser: proxy.ownerId)
                key.check(.unreadCount, -proxy.unreadCount, forUser: proxy.ownerId)
                key.checkConvoDeleted(convo, asSender: true)
                key.checkDeleted(at: Child.Proxies, proxy.ownerId, proxy.key)
                key.checkDeleted(at: Child.ProxyKeys, proxy.key)
                key.checkDeleted(at: Child.ProxyOwners, proxy.key)
                key.notify {
                    key.finishWorkGroup()
                    expectation.fulfill()
                }
            }
        }
    }

    func testGetImageForIcon() {
        XCTAssertEqual(Shared.shared.proxyIconNames.count, 101)

        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        let key = AsyncWorkGroupKey.makeAsyncWorkGroupKey()

        for icon in Shared.shared.proxyIconNames {
            key.startWork()
            DBProxy.getImageForIcon(icon, tag: 0) { (result) in
                XCTAssertNotNil(result)
                key.finishWork()
            }
        }

        key.notify {
            key.finishWorkGroup()
            expectation.fulfill()
        }
    }
    
    func testGetProxiesForUser() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }
        
        DBTest.makeProxy { (proxy) in
            DBProxy.getProxies(forUser: proxy.ownerId) { (proxies) in
                XCTAssertEqual(proxies?.count, 1)
                XCTAssertEqual(proxies?[0], proxy)
                expectation.fulfill()
            }
        }
    }
    
    func testGetProxy() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }
        
        DBTest.makeProxy { (proxy) in
            DBProxy.getProxy(withKey: proxy.key) { (retrievedProxy) in
                XCTAssertEqual(retrievedProxy, proxy)
                expectation.fulfill()
            }
        }
    }
    
    func testGetProxyNotFound() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }
        
        DBProxy.getProxy(withKey: "invalid key") { (proxy) in
            XCTAssertNil(proxy)
            expectation.fulfill()
        }
    }
    
    func testGetProxyWithOwnerId() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }
        
        DBTest.makeProxy { (proxy) in
            DBProxy.getProxy(withKey: proxy.key, belongingTo: proxy.ownerId) { (retrievedProxy) in
                XCTAssertEqual(retrievedProxy, proxy)
                expectation.fulfill()
            }
        }
    }
    
    func testGetProxyWithOwnerIdNotFound() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }
        
        DBProxy.getProxy(withKey: "invalid key", belongingTo: Shared.shared.uid) { (proxy) in
            XCTAssertNil(proxy)
            expectation.fulfill()
        }
    }

    func testMakeProxy() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }
        
        DBTest.makeProxy { (proxy) in
            XCTAssertFalse(Shared.shared.isCreatingProxy)
            XCTAssertNotEqual(proxy.icon, "")
            
            let key = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
            key.check(.proxyCount, 1, forUser: proxy.ownerId)
            key.checkProxyCreated(proxy)
            key.checkProxyKeyCreated(forProxy: proxy)
            key.checkProxyOwnerCreated(forProxy: proxy)
            key.notify {
                key.finishWorkGroup()
                expectation.fulfill()
            }
        }
    }
    
    func testMakeProxyAtProxyLimit() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }
        
        DB.set(50, at: Child.UserInfo, Shared.shared.uid, Child.ProxyCount) { (success) in
            XCTAssert(success)
            
            DBProxy.makeProxy { (result) in
                switch result {
                case .failure(let error):
                    XCTAssertEqual(error, ProxyError(.proxyLimitReached))
                    expectation.fulfill()
                case .success:
                    XCTFail()
                }
            }
        }
    }
    
    func testMakeProxyWithExistingName() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }
        
        DBProxy.makeProxy(withName: "test") { (result) in
            switch result {
            case .failure: XCTFail()
            case .success:
                DBProxy.makeProxy(withName: "test") { (result) in
                    switch result {
                    case .failure:
                        XCTAssertFalse(Shared.shared.isCreatingProxy)
                        expectation.fulfill()
                    case .success:
                        XCTFail()
                    }
                }
            }
        }
    }
    
    func testSetIcon() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }
        
        DBTest.makeConvo { (convo, proxy, _) in
            let newIcon = "new icon"
            
            DBProxy.setIcon(to: newIcon, forProxy: proxy) { (success) in
                XCTAssert(success)
                
                let key = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
                key.check(.icon(newIcon), forProxy: proxy)
                key.check(.receiverIcon(newIcon), forConvo: convo, asSender: false)
                key.notify {
                    key.finishWorkGroup()
                    expectation.fulfill()
                }
            }
        }
    }
    
    func testSetNickname() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }
        
        DBTest.makeConvo { (convo, sender, _) in
            let newNickname = "new nickname"
            
            DBProxy.setNickname(to: newNickname, forProxy: sender) { (success) in
                XCTAssert(success)
                
                let key = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
                key.check(.nickname(newNickname), forProxy: sender)
                key.check(.senderNickname(newNickname), forConvo: convo, asSender: true)
                key.notify {
                    key.finishWorkGroup()
                    expectation.fulfill()
                }
            }
        }
    }
}

extension AsyncWorkGroupKey {
    func checkProxyCreated(_ proxy: Proxy) {
        startWork()
        DB.get(Child.Proxies, Shared.shared.uid, proxy.key) { (data) in
            XCTAssertEqual(Proxy(data?.value as AnyObject), proxy)
            self.finishWork()
        }
    }
    
    func checkProxyKeyCreated(forProxy proxy: Proxy) {
        startWork()
        DB.get(Child.ProxyKeys, proxy.key) { (data) in
            XCTAssertEqual(data?.value as? [String: String] ?? [:], [Child.Key: proxy.key])
            self.finishWork()
        }
    }
    
    func checkProxyOwnerCreated(forProxy proxy: Proxy) {
        startWork()
        DB.get(Child.ProxyOwners, proxy.key) { (data) in
            XCTAssertEqual(ProxyOwner(data?.value as AnyObject), ProxyOwner(key: proxy.key, ownerId: Shared.shared.uid))
            self.finishWork()
        }
    }
}
