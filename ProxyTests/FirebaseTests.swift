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
    private var firebase: Firebase!

    func testDeleteProxy() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTest.sendMessage { message, convo, _, receiver in
            Shared.database.deleteProxy(receiver) { error in
                XCTAssertNil(error, String(describing: error))
                let work = GroupWork()
                work.checkDeleted(.contact(convo.receiverId), for: convo.senderId)
                work.checkDeleted(.contact(convo.senderId), for: convo.receiverId)
                work.checkDeleted(Child.proxies, receiver.ownerId, receiver.key)
                work.checkDeleted(Child.proxyNames, receiver.key)
                work.checkDeleted(Child.convos, receiver.ownerId, convo.key)
                work.checkDeleted(Child.users, receiver.ownerId, Child.unreadMessages, message.messageId)
                work.check(.receiverDeletedProxy(true), for: convo, asSender: true)
                work.allDone {
                    expectation.fulfill()
                }
            }
        }
    }

    func testDeleteUserPropertyRegistrationToken() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        let registrationToken = "registrationToken"
        let userProperty = SettableUserProperty.registrationToken(registrationToken)

        Shared.database.set(userProperty, for: FirebaseTest.uid) { error in
            XCTAssertNil(error)
            Shared.database.delete(userProperty, for: FirebaseTest.uid) { error in
                XCTAssertNil(error)
                let work = GroupWork()
                work.checkDeleted(Child.users, FirebaseTest.uid, Child.registrationTokens, registrationToken)
                work.allDone {
                    expectation.fulfill()
                }
            }
        }
    }

    func testGetConvo() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTest.sendMessage { _, convo, _, _ in
            Shared.database.getConvo(convoKey: convo.key, ownerId: convo.senderId) { result in
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

        FirebaseTest.makeProxy { proxy in
            Shared.database.getProxy(proxyKey: proxy.key) { result in
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

        Shared.database.getProxy(proxyKey: "invalid key") { result in
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

        FirebaseTest.makeProxy { proxy in
            Shared.database.getProxy(proxyKey: proxy.key, ownerId: proxy.ownerId) { result in
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

        Shared.database.getProxy(proxyKey: "invalid key", ownerId: FirebaseTest.uid) { result in
            switch result {
            case .failure:
                expectation.fulfill()
            case .success:
                XCTFail()
                expectation.fulfill()
            }
        }
    }

    func testGetUserPropertySound() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        Shared.database.set(.soundOn(true), for: FirebaseTest.uid) { error in
            XCTAssertNil(error)
            Shared.database.get(.soundOn(Bool()), for: FirebaseTest.uid) { result in
                switch result {
                case .failure(let error):
                    XCTFail(String(describing: error))
                    expectation.fulfill()
                case .success(let data):
                    XCTAssertEqual(data.value as? Bool, true)
                    expectation.fulfill()
                }
            }
        }
    }

    func testMakeProxy() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        Shared.database.makeProxy(currentProxyCount: 0, ownerId: FirebaseTest.uid) { result in
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

        var options = [String: Any]()
        options[DatabaseOption.generator.name] = GeneratorMock()
        options[DatabaseOption.makeProxyRetries.name] = 0
        firebase = Firebase(options)

        firebase.makeProxy(currentProxyCount: 0, ownerId: FirebaseTest.uid) { [weak self] result in
            switch result {
            case .failure(let error):
                XCTFail(String(describing: error))
                expectation.fulfill()
            case .success:
                self?.firebase.makeProxy(currentProxyCount: 1, ownerId: FirebaseTest.uid) { result in
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

        FirebaseTest.sendMessage { message, _, _, receiver in
            let date = Date()
            Shared.database.read(message, at: date) { error in
                XCTAssertNil(error, String(describing: error))
                let work = GroupWork()
                work.checkDeleted(Child.users, message.receiverId, Child.unreadMessages, message.messageId)
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

        FirebaseTest.sendMessage { (message, convo, _, receiver) in
            Shared.database.sendMessage(convo: convo, text: FirebaseTest.text) { result in
                switch result {
                case .failure(let error):
                    XCTFail(String(describing: error))
                    expectation.fulfill()
                case .success(let result):
                    Shared.database.read(result.message, at: Date()) { error in
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
    }

    func testSendMessage() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTest.sendMessage { message, convo, sender, receiver in
            let work = GroupWork()

            // Check convo made
            work.check(.proxiesInteractedWith, equals: 1, uid: receiver.ownerId)
            work.check(.proxiesInteractedWith, equals: 1, uid: sender.ownerId)
            work.checkConvoCreated(convo, asSender: true)
            work.checkConvoCreated(convo, asSender: false)

            // Check message updates
            work.checkMessageCreated(message)

            // Check receiver updates
            work.check(.contact(sender.ownerId), for: receiver.ownerId)
            work.check(.messagesReceived, equals: 1, uid: convo.receiverId)
            work.checkUnreadMessageCreated(message)
            work.check(.hasUnreadMessage(true), for: convo, asSender: false)
            work.check(.hasUnreadMessage(true), for: receiver)
            work.check(.timestamp(convo.timestamp), for: convo, asSender: false)
            work.check(.timestamp(convo.timestamp), for: receiver)
            work.check(.lastMessage(FirebaseTest.text), for: convo, asSender: false)
            work.check(.lastMessage(FirebaseTest.text), for: receiver)

            // Check sender updates
            work.check(.contact(receiver.ownerId), for: sender.ownerId)
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

        FirebaseTest.sendMessage { _, senderConvo, _, receiverProxy in
            Shared.database.deleteProxy(receiverProxy) { error in
                XCTAssertNil(error, String(describing: error))
                Shared.database.getConvo(convoKey: senderConvo.key, ownerId: senderConvo.senderId) { result in
                    switch result {
                    case .failure(let error):
                        XCTFail(String(describing: error))
                        expectation.fulfill()
                    case .success(let convo):
                        Shared.database.sendMessage(convo: convo, text: FirebaseTest.text) { result in
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

        FirebaseTest.sendMessage { _, convo, _, _ in
            Shared.database.sendMessage(convo: convo, text: FirebaseTest.text) { result in
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

        FirebaseTest.sendMessage { _, convo, proxy, _ in
            let newIcon = "new icon"
            Shared.database.setIcon(to: newIcon, for: proxy) { error in
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

        FirebaseTest.sendMessage { _, convo, proxy, _ in
            let newNickname = "new nickname"
            Shared.database.setNickname(to: newNickname, for: proxy) { error in
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

        FirebaseTest.sendMessage { _, convo, _, _ in
            let testNickname = "test nickname"
            Shared.database.setReceiverNickname(to: testNickname, for: convo) { error in
                XCTAssertNil(error, String(describing: error))
                let work = GroupWork()
                work.check(.receiverNickname(testNickname), for: convo, asSender: true)
                work.allDone {
                    expectation.fulfill()
                }
            }
        }
    }

    func testSetUserPropertyRegistrationToken() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        let registrationToken1 = "registrationToken1"
        let registrationToken2 = "registrationToken2"

        Shared.database.set(.registrationToken(registrationToken1), for: FirebaseTest.uid) { error in
            XCTAssertNil(error)
            Shared.database.set(.registrationToken(registrationToken2), for: FirebaseTest.uid) { error in
                XCTAssertNil(error)
                Shared.firebaseHelper.get(Child.users, FirebaseTest.uid, Child.registrationTokens) { result in
                    switch result {
                    case .failure(let error):
                        XCTFail(String(describing: error))
                        expectation.fulfill()
                    case .success(let data):
                        XCTAssertEqual(
                            data.value as? [String: Int] ?? [:],
                            [registrationToken1: 1, registrationToken2: 1]
                        )
                        expectation.fulfill()
                    }
                }
            }
        }
    }

    func testSetUserPropertySoundOn() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        Shared.database.set(.soundOn(true), for: FirebaseTest.uid) { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
    }
}

extension GroupWork {
    func checkConvoCreated(_ convo: Convo, asSender: Bool) {
        let (uid, _) = GroupWork.getOwnerIdAndProxyKey(convo: convo, asSender: asSender)
        start()
        Shared.firebaseHelper.get(Child.convos, uid, convo.key) { result in
            switch result {
            case .failure(let error):
                XCTFail(String(describing: error))
            case .success(let data):
                XCTAssertNotNil(try? Convo(data))
            }
            self.finish(withResult: true)
        }
    }

    func checkMessageCreated(_ message: Message) {
        start()
        Shared.firebaseHelper.get(Child.messages, message.parentConvoKey, message.messageId) { result in
            switch result {
            case .failure(let error):
                XCTFail(String(describing: error))
            case .success(let data):
                XCTAssertEqual(try? Message(data), message)
            }
            self.finish(withResult: true)
        }
    }

    func checkProxyCreated(_ proxy: Proxy) {
        start()
        Shared.firebaseHelper.get(Child.proxies, FirebaseTest.uid, proxy.key) { result in
            switch result {
            case .failure(let error):
                XCTFail(String(describing: error))
            case .success(let data):
                XCTAssertEqual(try? Proxy(data), proxy)
            }
            self.finish(withResult: true)
        }
    }

    func checkProxyNameCreated(forProxy proxy: Proxy) {
        start()
        Shared.firebaseHelper.get(Child.proxyNames, proxy.key) { result in
            let testProxy = Proxy(icon: proxy.icon, name: proxy.name, ownerId: proxy.ownerId)
            switch result {
            case .failure(let error):
                XCTFail(String(describing: error))
            case .success(let data):
                XCTAssertEqual(try? Proxy(data), testProxy)
            }
            self.finish(withResult: true)
        }
    }

    func checkUnreadMessageCreated(_ message: Message) {
        start()
        Shared.firebaseHelper.get(
            Child.users,
            message.receiverId,
            Child.unreadMessages,
            message.messageId
        ) { result in
            switch result {
            case .failure(let error):
                XCTFail(String(describing: error))
            case .success(let data):
                XCTAssertEqual(try? Message(data), message)
            }
            self.finish(withResult: true)
        }
    }
}
