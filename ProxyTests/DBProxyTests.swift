import FirebaseDatabase
import GroupWork
import XCTest
@testable import Proxy

class DBProxyTests: DBTest {
    func testDeleteProxy() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeProxy { (sender) in
            DBTest.makeProxy(forUser: DBTest.testUser) { (receiver) in
                DBMessage.sendMessage(senderProxy: receiver, receiverProxy: sender, text: DBTest.text) { (result) in
                    switch result {
                    case .failure:
                        XCTFail()
                    case .success(let tuple):
                        DBProxy.deleteProxy(sender) { (success) in
                            XCTAssert(success)
                            let work = GroupWork()
                            work.checkUnreadMessagesDeleted(for: sender)
                            work.checkConvoDeleted(tuple.convo, asSender: false)
                            work.checkDeleted(at: Child.proxies, sender.ownerId, sender.key)
                            work.checkDeleted(at: Child.proxyKeys, sender.key)
                            work.checkDeleted(at: Child.proxyOwners, sender.key)
                            work.allDone {
                                expectation.fulfill()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func testGetImageForIcon() {
        XCTAssertEqual(ProxyService.iconNames.count, 101)

        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        let work = GroupWork()

        for icon in ProxyService.iconNames {
            work.start()
            UIImage.make(name: icon) { (image) in
                XCTAssertNotNil(image)
                work.finish(withResult: true)
            }
        }

        work.allDone {
            expectation.fulfill()
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
            
            let work = GroupWork()
            work.checkProxyCreated(proxy)
            work.checkProxyKeyCreated(forProxy: proxy)
            work.checkProxyOwnerCreated(forProxy: proxy)
            work.allDone {
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
            case .failure:
                XCTFail()
            case .success:
                DBProxy.makeProxy(withName: "test", forUser: DBTest.uid) { (result) in
                    switch result {
                    case .failure:
                        XCTFail()
                    case .success(let proxy):
                        XCTAssert(proxy.name != "test")
                        expectation.fulfill()
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
                
                let work = GroupWork()
                work.check(.icon(newIcon), forProxy: proxy)
                work.check(.receiverIcon(newIcon), forConvo: convo, asSender: false)
                work.allDone {
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
            
            DBProxy.setNickname(to: newNickname, forProxy: sender) { (error) in
                XCTAssertNil(error)
                
                let work = GroupWork()
                work.check(.nickname(newNickname), forProxy: sender)
                work.check(.senderNickname(newNickname), forConvo: convo, asSender: true)
                work.allDone {
                    expectation.fulfill()
                }
            }
        }
    }
}

extension GroupWork {
    func checkProxyCreated(_ proxy: Proxy) {
        start()
        DB.get(Child.proxies, DBTest.uid, proxy.key) { (data) in
            XCTAssertEqual(Proxy(data?.value as AnyObject), proxy)
            self.finish(withResult: true)
        }
    }
    
    func checkProxyKeyCreated(forProxy proxy: Proxy) {
        start()
        DB.get(Child.proxyKeys, proxy.key) { (data) in
            XCTAssertEqual(data?.value as? [String: String] ?? [:], [Child.key: proxy.key])
            self.finish(withResult: true)
        }
    }
    
    func checkProxyOwnerCreated(forProxy proxy: Proxy) {
        start()
        DB.get(Child.proxyOwners, proxy.key) { (data) in
            XCTAssertEqual(ProxyOwner(data?.value as AnyObject), ProxyOwner(key: proxy.key, ownerId: DBTest.uid))
            self.finish(withResult: true)
        }
    }

    func checkUnreadMessagesDeleted(for proxy: Proxy) {
        start()
        DBProxy.getUnreadMessagesForProxy(owner: proxy.ownerId, key: proxy.key) { (messages) in
            XCTAssertEqual(messages?.count, 0)
            self.finish(withResult: true)
        }
    }
}
