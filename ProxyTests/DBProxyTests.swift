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
                DB.sendMessage(senderProxy: sender, receiverProxy: receiver, text: DBTest.text) { (result) in
                    switch result {
                    case .failure:
                        XCTFail()
                    case .success(let tuple):
                        DB.deleteProxy(receiver) { (success) in
                            XCTAssert(success)
                            let work = GroupWork()
                            work.checkDeleted(at: Child.proxies, receiver.ownerId, receiver.key)
                            work.checkDeleted(at: Child.proxyKeys, receiver.key)
                            work.checkDeleted(at: Child.proxyOwners, receiver.key)
                            work.checkDeleted(at: Child.convos, receiver.ownerId, tuple.convo.key)
                            work.checkDeleted(at: Child.convos, receiver.ownerId, tuple.convo.key)
                            work.checkUnreadMessageCount(uid: sender.ownerId, count: 0)
                            work.allDone {
                                expectation.fulfill()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func testGetProxy() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }
        
        DBTest.makeProxy { (proxy) in
            DB.getProxy(withKey: proxy.key) { (retrievedProxy) in
                XCTAssertEqual(retrievedProxy, proxy)
                expectation.fulfill()
            }
        }
    }
    
    func testGetProxyNotFound() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }
        
        DB.getProxy(withKey: "invalid key") { (proxy) in
            XCTAssertNil(proxy)
            expectation.fulfill()
        }
    }
    
    func testGetProxyWithOwnerId() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }
        
        DBTest.makeProxy { (proxy) in
            DB.getProxy(withKey: proxy.key, belongingTo: proxy.ownerId) { (retrievedProxy) in
                XCTAssertEqual(retrievedProxy, proxy)
                expectation.fulfill()
            }
        }
    }
    
    func testGetProxyWithOwnerIdNotFound() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }
        
        DB.getProxy(withKey: "invalid key", belongingTo: DBTest.uid) { (proxy) in
            XCTAssertNil(proxy)
            expectation.fulfill()
        }
    }

    func testGetUnreadMessagesForProxy() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.sendMessage { (message, _, _, _) in
            DB.getUnreadMessagesForProxy(ownerId: message.receiverId, proxyKey: message.receiverProxyKey) { (messages) in
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

        DB.makeProxy(forUser: DBTest.uid, maxProxyCount: 0) { (result) in
            switch result {
            case .failure(let error):
                XCTAssertEqual(error, ProxyError.proxyLimitReached)
                expectation.fulfill()
            case .success:
                XCTFail()
            }
        }
    }
    
    func testMakeProxyFailAtMaxAttempts() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }
        
        DB.makeProxy(withName: "test", forUser: DBTest.uid) { (result) in
            switch result {
            case .failure:
                XCTFail()
            case .success:
                DB.makeProxy(withName: "test", forUser: DBTest.uid) { (result) in
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
            DB.setIcon(to: newIcon, forProxy: proxy) { (success) in
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
            DB.setNickname(to: newNickname, forProxy: sender) { (error) in
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
            XCTAssertEqual(Proxy(data!), proxy)
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
            XCTAssertEqual(ProxyOwner(data!), ProxyOwner(key: proxy.key, ownerId: DBTest.uid))
            self.finish(withResult: true)
        }
    }
}
