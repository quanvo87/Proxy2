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
                DB.sendMessage(sender: sender, receiver: receiver, text: DBTest.text) { (result) in
                    switch result {
                    case .failure:
                        XCTFail()
                        expectation.fulfill()
                    case .success(let tuple):
                        DB.deleteProxy(receiver) { (success) in
                            XCTAssert(success)
                            let work = GroupWork()
                            work.checkDeleted(Child.proxies, receiver.ownerId, receiver.key)
                            work.checkDeleted(Child.proxyNames, receiver.key)
                            work.checkDeleted(Child.convos, receiver.ownerId, tuple.convo.key)
                            work.checkDeleted(Child.userInfo, receiver.ownerId, Child.unreadMessages, tuple.message.messageId)
                            work.check(.receiverDeletedProxy(true), for: tuple.convo, asSender: true)
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
            DB.getProxy(key: proxy.key) { (retrievedProxy) in
                XCTAssertEqual(retrievedProxy, proxy)
                expectation.fulfill()
            }
        }
    }
    
    func testGetProxyNotFound() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }
        
        DB.getProxy(key: "invalid key") { (proxy) in
            XCTAssertNil(proxy)
            expectation.fulfill()
        }
    }
    
    func testGetProxyWithOwnerId() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }
        
        DBTest.makeProxy { (proxy) in
            DB.getProxy(uid: proxy.ownerId, key: proxy.key) { (retrievedProxy) in
                XCTAssertEqual(retrievedProxy, proxy)
                expectation.fulfill()
            }
        }
    }
    
    func testGetProxyWithOwnerIdNotFound() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }
        
        DB.getProxy(uid: DBTest.uid, key: "invalid key") { (proxy) in
            XCTAssertNil(proxy)
            expectation.fulfill()
        }
    }

    func testMakeProxy() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }
        
        DBTest.makeProxy { (proxy) in
            XCTAssertNotEqual(proxy.icon, "")
            let work = GroupWork()
            work.checkProxyCreated(proxy)
            work.checkProxyNameCreated(forProxy: proxy)
            work.allDone {
                expectation.fulfill()
            }
        }
    }

    func testMakeProxyAtProxyLimit() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DB.makeProxy(uid: DBTest.uid, currentProxyCount: 0, maxProxyCount: 0) { (result) in
            switch result {
            case .failure(let error):
                XCTAssertEqual(error, ProxyError.proxyLimitReached)
                expectation.fulfill()
            case .success:
                XCTFail()
                expectation.fulfill()
            }
        }
    }
    
    func testMakeProxyFailAtMaxAttempts() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }
        
        DB.makeProxy(uid: DBTest.uid, name: "test", currentProxyCount: 0) { (result) in
            switch result {
            case .failure:
                XCTFail()
            case .success:
                DB.makeProxy(uid: DBTest.uid, name: "test", currentProxyCount: 1) { (result) in
                    switch result {
                    case .failure:
                        XCTFail()
                        expectation.fulfill()
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

        DBTest.sendMessage { (_, convo, proxy, _) in
            let newIcon = "new icon"
            DB.setIcon(to: newIcon, for: proxy) { (success) in
                XCTAssert(success)
                let work = GroupWork()
                work.check(.icon(newIcon), for: proxy)
                work.check(.receiverIcon(newIcon), for: convo, asSender: false)
                work.allDone {
                    expectation.fulfill()
                }
            }
        }
    }
    
    func testSetNickname() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.sendMessage { (_, convo, proxy, _) in
            let newNickname = "new nickname"
            DB.setNickname(to: newNickname, for: proxy) { (error) in
                XCTAssertNil(error)
                let work = GroupWork()
                work.check(.nickname(newNickname), for: proxy)
                work.check(.senderNickname(newNickname), for: convo, asSender: true)
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

    func checkProxyNameCreated(forProxy proxy: Proxy) {
        start()
        DB.get(Child.proxyNames, proxy.key) { (data) in
            let testProxy = Proxy(icon: proxy.icon, name: proxy.name, ownerId: proxy.ownerId)
            XCTAssertEqual(Proxy(data!), testProxy)
            self.finish(withResult: true)
        }
    }
}
