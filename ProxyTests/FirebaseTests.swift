import FirebaseDatabase
import GroupWork
import XCTest
@testable import Proxy

class GeneratorMock: ProxyPropertyGenerating {
    var iconNames = [String]()
    var randomIconName = "test"
    var randomProxyName = "test"
}

class FirebaseTests: FirebaseTest {
    var firebase: FirebaseDatabase!

    func testDeleteProxy() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTest.makeProxy { (sender) in
            FirebaseTest.makeProxy(ownerId: FirebaseTest.testUser) { (receiver) in
                FirebaseHelper.sendMessage(sender: sender, receiver: receiver, text: FirebaseTest.text) { (result) in
                    switch result {
                    case .failure(let error):
                        XCTFail(String(describing: error))
                        expectation.fulfill()
                    case .success(let tuple):
                        FirebaseTest.firebase.delete(receiver) { (error) in
                            XCTAssertNil(error)
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

        FirebaseTest.makeProxy { (proxy) in
            FirebaseTest.firebase.getProxy(key: proxy.key) { (result) in
                switch result {
                case .failure(let error):
                    XCTFail(String(describing: error))
                    expectation.fulfill()
                case .success(let retrievedProxy):
                    XCTAssertEqual(retrievedProxy, proxy)
                    expectation.fulfill()
                }
            }
        }
    }

    func testGetProxyNotFound() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTest.firebase.getProxy(key: "invalid key") { (result) in
            switch result {
            case .failure:
                expectation.fulfill()
            case .success:
                XCTFail()
                expectation.fulfill()
            }
        }
    }

    func testGetProxyWithOwnerId() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTest.makeProxy { (proxy) in
            FirebaseTest.firebase.getProxy(key: proxy.key, ownerId: proxy.ownerId) { (result) in
                switch result {
                case .failure(let error):
                    XCTFail(String(describing: error))
                    expectation.fulfill()
                case .success(let retrievedProxy):
                    XCTAssertEqual(retrievedProxy, proxy)
                    expectation.fulfill()
                }
            }
        }
    }

    func testGetProxyWithOwnerIdNotFound() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTest.firebase.getProxy(key: "invalid key", ownerId: FirebaseTest.uid) { (result) in
            switch result {
            case .failure:
                expectation.fulfill()
            case .success:
                XCTFail()
                expectation.fulfill()
            }
        }
    }

    func testMakeProxy() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTest.firebase.makeProxy(ownerId: FirebaseTest.uid) { (result) in
            switch result {
            case .failure(let error):
                XCTFail(String(describing: error))
                expectation.fulfill()
            case .success(let proxy):
                let work = GroupWork()
                work.checkProxyCreated(proxy)
                work.checkProxyNameCreated(forProxy: proxy)
                // todo: check proxy deleted at test key
                work.allDone {
                    expectation.fulfill()
                }
            }
        }
    }

    func testMakeProxyFailAtMaxRetries() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        var settings = [String: Any]()
        settings["generator"] = GeneratorMock()
        settings["makeProxyRetries"] = 0
        firebase = FirebaseDatabase(settings)

        firebase.makeProxy(ownerId: FirebaseTest.uid) { (result) in
            switch result {
            case .failure(let error):
                XCTFail(String(describing: error))
                expectation.fulfill()
            case .success:
                self.firebase.makeProxy(ownerId: FirebaseTest.uid) { (result) in
                    switch result {
                    case .failure:
                        expectation.fulfill()
                    case .success:
                        XCTFail()
                        expectation.fulfill()
                    }
                }
            }
        }
    }

    func testSetIcon() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTest.sendMessage { (_, convo, proxy, _) in
            let newIcon = "new icon"
            FirebaseTest.firebase.setIcon(to: newIcon, for: proxy) { (error) in
                XCTAssertNil(error, String(describing: error))
                let work = GroupWork()
                work.check(.icon(newIcon), for: proxy)
                work.check(.receiverIcon(newIcon), for: convo, asSender: false)
                work.check(.senderIcon(newIcon), for: convo, asSender: true)
                work.allDone {
                    expectation.fulfill()
                }
            }
        }
    }

    func testSetNickname() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTest.sendMessage { (_, convo, proxy, _) in
            let newNickname = "new nickname"
            FirebaseTest.firebase.setNickname(to: newNickname, for: proxy) { (error) in
                XCTAssertNil(error, String(describing: error))
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
        FirebaseHelper.get(Child.proxies, FirebaseTest.uid, proxy.key) { (data) in
            XCTAssertEqual(Proxy(data!), proxy)
            self.finish(withResult: true)
        }
    }

    func checkProxyNameCreated(forProxy proxy: Proxy) {
        start()
        FirebaseHelper.get(Child.proxyNames, proxy.key) { (data) in
            let testProxy = Proxy(icon: proxy.icon, name: proxy.name, ownerId: proxy.ownerId)
            XCTAssertEqual(Proxy(data!), testProxy)
            self.finish(withResult: true)
        }
    }
}
