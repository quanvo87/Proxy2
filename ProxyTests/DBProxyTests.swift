import FirebaseDatabase
import XCTest
@testable import Proxy

class DBProxyTests: DBTest {
    func testDeleteProxy() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeProxy { (sender) in
            DBTest.makeProxy(forUser: DBTest.testUser) { (receiver) in
                DBMessage.sendMessage(from: receiver, to: sender, withText: DBTest.text) { (result) in
                    guard let (_, convo) = result else {
                        XCTFail()
                        return
                    }

                    DBProxy.deleteProxy(sender) { (success) in
                        XCTAssert(success)
                        
                        let key = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
                        key.check(.receiverDeletedProxy(true), forConvo: convo, asSender: true)
                        key.checkUnreadMessagesDeleted(for: sender)
                        key.checkConvoDeleted(convo, asSender: false)
                        key.checkDeleted(at: Child.proxies, sender.ownerId, sender.key)
                        key.checkDeleted(at: Child.proxyKeys, sender.key)
                        key.checkDeleted(at: Child.proxyOwners, sender.key)
                        key.notify {
                            key.finishWorkGroup()
                            expectation.fulfill()
                        }
                    }
                }
            }
        }
    }

    func testFixConvoCounts() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (_, sender, _) in

            let key = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
            key.set(.convoCount(0), forProxy: sender)
            key.notify {
                key.finishWorkGroup()

                DBProxy.fixConvoCounts(uid: DBTest.uid) { (success) in
                    XCTAssert(success)

                    DBProxy.getConvoCount(forProxy: sender) { (convoCount) in
                        XCTAssertEqual(convoCount, 1)

                        expectation.fulfill()
                    }
                }
            }
        }
    }
    
    func testGetImageForIcon() {
        XCTAssertEqual(ProxyService.iconNames.count, 101)

        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        let key = AsyncWorkGroupKey.makeAsyncWorkGroupKey()

        for icon in ProxyService.iconNames {
            key.startWork()
            UIImage.makeImage(named: icon) { (image) in
                XCTAssertNotNil(image)
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
        
        DBProxy.getProxy(withKey: "invalid key", belongingTo: DBTest.uid) { (proxy) in
            XCTAssertNil(proxy)
            expectation.fulfill()
        }
    }

    func testGetUnreadMessagesForProxy() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.sendMessage { (message, _, _, _) in

            DBProxy.getUnreadMessagesForProxy(owner: message.receiverId, key: message.receiverProxyKey) { (messages) in
                XCTAssertEqual(messages?[safe: 0], message)

                expectation.fulfill()
            }
        }
    }

    func testMakeProxy() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }
        
        DBTest.makeProxy { (proxy) in
            XCTAssertNotEqual(proxy.icon, "")
            
            let key = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
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

        DBProxy.makeProxy(forUser: DBTest.uid, maxAllowedProxies: 0) { (result) in
            switch result {
            case .failure(let error):
                XCTAssertEqual(error, ProxyError.proxyLimitReached)
                expectation.fulfill()
            case .success:
                XCTFail()
            }
        }
    }
    
    func testMakeProxyWithExistingName() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }
        
        DBProxy.makeProxy(withName: "test", forUser: DBTest.uid) { (result) in
            switch result {
            case .failure: XCTFail()
            case .success:
                DBProxy.makeProxy(withName: "test", forUser: DBTest.uid) { (result) in
                    switch result {
                    case .failure:
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
        DB.get(Child.proxies, DBTest.uid, proxy.key) { (data) in
            XCTAssertEqual(Proxy(data?.value as AnyObject), proxy)
            self.finishWork()
        }
    }
    
    func checkProxyKeyCreated(forProxy proxy: Proxy) {
        startWork()
        DB.get(Child.proxyKeys, proxy.key) { (data) in
            XCTAssertEqual(data?.value as? [String: String] ?? [:], [Child.key: proxy.key])
            self.finishWork()
        }
    }
    
    func checkProxyOwnerCreated(forProxy proxy: Proxy) {
        startWork()
        DB.get(Child.proxyOwners, proxy.key) { (data) in
            XCTAssertEqual(ProxyOwner(data?.value as AnyObject), ProxyOwner(key: proxy.key, ownerId: DBTest.uid))
            self.finishWork()
        }
    }

    func checkUnreadMessagesDeleted(for proxy: Proxy) {
        startWork()
        DBProxy.getUnreadMessagesForProxy(owner: proxy.ownerId, key: proxy.key) { (messages) in
            XCTAssertEqual(messages?.count, 0)
            self.finishWork()
        }
    }
}
