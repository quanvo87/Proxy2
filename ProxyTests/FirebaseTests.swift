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
    private static let senderText = "You: \(text)"
    private var firebase: FirebaseDatabase!

    func testDeleteProxy() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTest.sendMessage { (message, convo, _, receiver) in
            FirebaseTest.database.delete(receiver) { (error) in
                XCTAssertNil(error, String(describing: error))
                let work = GroupWork()
                work.checkDeleted(Child.proxies, receiver.ownerId, receiver.key)
                work.checkDeleted(Child.proxyNames, receiver.key)
                work.checkDeleted(Child.convos, receiver.ownerId, convo.key)
                work.checkDeleted(Child.userInfo, receiver.ownerId, Child.unreadMessages, message.messageId)
                work.check(.receiverDeletedProxy(true), for: convo, asSender: true)
                work.allDone {
                    expectation.fulfill()
                }
            }
        }
    }

    func testDeleteUnreadMessage() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTest.sendMessage { (message, _, _, _) in
            FirebaseTest.database.deleteUnreadMessage(message) { (error) in
                XCTAssertNil(error, String(describing: error))
                let work = GroupWork()
                work.checkDeleted(Child.userInfo, message.receiverId, Child.unreadMessages, message.messageId)
                work.checkDeleted(Child.convos, message.receiverId, message.parentConvoKey)
                work.allDone {
                    expectation.fulfill()
                }
            }
        }
    }

    func testGetConvo() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTest.sendMessage { (_, convo, _, _) in
            FirebaseTest.database.getConvo(key: convo.key, ownerId: convo.senderId) { (result) in
                switch result {
                case .failure(let error):
                    XCTFail(String(describing: error))
                    expectation.fulfill()
                case .success(let retrievedConvo):
                    XCTAssertEqual(retrievedConvo, convo)
                    expectation.fulfill()
                }
            }
        }
    }

    func testGetProxy() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTest.makeProxy { (proxy) in
            FirebaseTest.database.getProxy(key: proxy.key) { (result) in
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

        FirebaseTest.database.getProxy(key: "invalid key") { (result) in
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
            FirebaseTest.database.getProxy(key: proxy.key, ownerId: proxy.ownerId) { (result) in
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

        FirebaseTest.database.getProxy(key: "invalid key", ownerId: FirebaseTest.uid) { (result) in
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

        FirebaseTest.database.makeProxy(ownerId: FirebaseTest.uid) { (result) in
            switch result {
            case .failure(let error):
                XCTFail(String(describing: error))
                expectation.fulfill()
            case .success(let proxy):
                let work = GroupWork()
                work.checkProxyCreated(proxy)
                work.checkProxyNameCreated(forProxy: proxy)
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

    func testRead() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTest.sendMessage { (message, _, _, receiver) in
            let date = Date()
            FirebaseTest.database.read(message, at: date) { (error) in
                XCTAssertNil(error, String(describing: error))
                let work = GroupWork()
                work.checkDeleted(Child.userInfo, message.receiverId, Child.unreadMessages, message.messageId)
                work.check(.dateRead(date), for: message)
                work.check(.hasUnreadMessage(false), uid: message.receiverId, convoKey: message.parentConvoKey)
                work.check(.hasUnreadMessage(false), for: receiver)
                work.allDone {
                    expectation.fulfill()
                }
            }
        }
    }

    func testReadWithOtherUnreadMessages() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTest.sendMessage { (message, _, _, _) in
            FirebaseTest.sendMessage { (_, _, _, receiver) in
                FirebaseTest.database.read(message, at: Date()) { (error) in
                    XCTAssertNil(error, String(describing: error))
                    let work = GroupWork()
                    work.check(.hasUnreadMessage(true), for: receiver)
                    work.allDone {
                        expectation.fulfill()
                    }
                }
            }
        }
    }

    func testSendMessage() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTest.sendMessage { (message, convo, sender, receiver) in
            let work = GroupWork()

            // Check convo made
            work.check(.proxiesInteractedWith, equals: 1, uid: receiver.ownerId)
            work.check(.proxiesInteractedWith, equals: 1, uid: sender.ownerId)
            work.checkConvoCreated(convo, asSender: true)
            work.checkConvoCreated(convo, asSender: false)

            // Check message updates
            work.checkMessageCreated(message)

            // Check receiver updates
            work.check(.messagesReceived, equals: 1, uid: convo.receiverId)
            work.checkUnreadMessageCreated(message)
            work.check(.hasUnreadMessage(true), for: convo, asSender: false)
            work.check(.hasUnreadMessage(true), for: receiver)
            work.check(.timestamp(convo.timestamp), for: convo, asSender: false)
            work.check(.timestamp(convo.timestamp), for: receiver)
            work.check(.lastMessage(FirebaseTest.text), for: convo, asSender: false)
            work.check(.lastMessage(FirebaseTest.text), for: receiver)

            // Check sender updates
            work.check(.messagesSent, equals: 1, uid: sender.ownerId)
            work.check(.timestamp(convo.timestamp), for: convo, asSender: true)
            work.check(.timestamp(convo.timestamp), for: sender)
            work.check(.lastMessage(FirebaseTests.senderText), for: convo, asSender: true)
            work.check(.lastMessage(FirebaseTests.senderText), for: sender)

            work.allDone {
                expectation.fulfill()
            }
        }
    }

    func testSendMessageAfterReceiverDeletedProxy() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTest.sendMessage { (_, senderConvo, _, receiverProxy) in
            FirebaseTest.database.delete(receiverProxy) { (error) in
                XCTAssertNil(error, String(describing: error))
                FirebaseTest.database.getConvo(key: senderConvo.key, ownerId: senderConvo.senderId) { (result) in
                    switch result {
                    case .failure(let error):
                        XCTFail(String(describing: error))
                        expectation.fulfill()
                    case .success(let convo):
                        FirebaseTest.database.sendMessage(convo: convo, text: FirebaseTest.text) { (result) in
                            switch result {
                            case .failure(let error as ProxyError):
                                switch error {
                                case .receiverDeletedProxy:
                                    let work = GroupWork()
                                    work.checkDeleted(Child.convos, convo.receiverId, convo.key)
                                    work.checkDeleted(Child.proxies, convo.receiverId, convo.receiverProxyKey)
                                    work.allDone {
                                        expectation.fulfill()
                                    }
                                default:
                                    XCTFail()
                                    expectation.fulfill()
                                }
                            default:
                                XCTFail()
                                expectation.fulfill()
                            }
                        }
                    }
                }
            }
        }
    }

    func testSendMessageWithSenderConvo() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTest.sendMessage { (_, convo, _, _) in
            FirebaseTest.database.sendMessage(convo: convo, text: FirebaseTest.text) { (result) in
                switch result {
                case .failure(let error):
                    XCTFail(String(describing: error))
                    expectation.fulfill()
                case .success:
                    expectation.fulfill()
                }
            }
        }
    }

    func testSetIconForProxy() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTest.sendMessage { (_, convo, proxy, _) in
            let newIcon = "new icon"
            FirebaseTest.database.setIcon(to: newIcon, for: proxy) { (error) in
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

    func testSetNicknameForProxy() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTest.sendMessage { (_, convo, proxy, _) in
            let newNickname = "new nickname"
            FirebaseTest.database.setNickname(to: newNickname, for: proxy) { (error) in
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

    func testSetReceiverNicknameForConvo() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTest.sendMessage { (_, convo, _, _) in
            let testNickname = "test nickname"
            FirebaseTest.database.setReceiverNickname(to: testNickname, for: convo) { (error) in
                XCTAssertNil(error, String(describing: error))
                let work = GroupWork()
                work.check(.receiverNickname(testNickname), for: convo, asSender: true)
                work.allDone {
                    expectation.fulfill()
                }
            }
        }
    }
}

extension GroupWork {
    func checkConvoCreated(_ convo: Convo, asSender: Bool) {
        let (uid, _) = GroupWork.getOwnerIdAndProxyKey(convo: convo, asSender: asSender)
        start()
        FirebaseHelper.get(Child.convos, uid, convo.key) { (data) in
            XCTAssertNotNil(Convo(data!))
            self.finish(withResult: true)
        }
    }

    func checkMessageCreated(_ message: Message) {
        start()
        FirebaseHelper.get(Child.messages, message.parentConvoKey, message.messageId) { (data) in
            XCTAssertEqual(Message(data!), message)
            self.finish(withResult: true)
        }
    }

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

    func checkUnreadMessageCreated(_ message: Message) {
        start()
        FirebaseHelper.get(Child.userInfo, message.receiverId, Child.unreadMessages, message.messageId) { (data) in
            XCTAssertEqual(Message(data!), message)
            self.finish(withResult: true)
        }
    }
}
