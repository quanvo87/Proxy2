import FirebaseDatabase
import GroupWork
import XCTest
@testable import Proxy

private class GeneratorMock: ProxyPropertyGenerating {
    var iconNames = [String]()
    var randomIconName = "test"
    var randomProxyName = "test"
}

class FirebaseTests: XCTestCase {
    static let senderText = "You: \(text)"
    static let text = "🤤"
    static let uid = "uid"
    static let uid2 = "uid2"

    override func setUp() {
        guard Constant.isRunningTests else {
            fatalError()
        }
        super.setUp()
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }
        Shared.testDatabaseReference.removeValue { error, _ in
            XCTAssertNil(error, String(describing: error))
            expectation.fulfill()
        }
    }
}

extension FirebaseTests {
    func testBlockUser() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTests.sendMessage { _, convo, _, _ in
            let blockedUser = BlockedUser(convo: convo)
            Shared.database.block(blockedUser) { error in
                XCTAssertNil(error, String(describing: error))
                let work = GroupWork()
                work.checkBlockedUserSet(blockedUser)
                work.check(.receiverIsBlocked(true), ownerId: blockedUser.blocker, convoKey: blockedUser.convoKey)
                work.check(.receiverIsBlocking(true), ownerId: blockedUser.blockee, convoKey: blockedUser.convoKey)
                work.allDone {
                    expectation.fulfill()
                }
            }
        }
    }

    func testDatasnapshotAsBlockedUsersArray() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        let blockedUser1 = BlockedUser(
            blockee: "blockee1",
            blockeeProxyName: "proxyName1",
            blocker: FirebaseTests.uid,
            convoKey: "convoKey1"
        )
        let blockedUser2 = BlockedUser(
            blockee: "blockee2",
            blockeeProxyName: "proxyName2",
            blocker: FirebaseTests.uid,
            convoKey: "convoKey2"
        )
        Shared.database.block(blockedUser1) { error in
            XCTAssertNil(error, String(describing: error))
            Shared.database.block(blockedUser2) { error in
                XCTAssertNil(error, String(describing: error))
                Shared.firebaseHelper.get(Child.users, FirebaseTests.uid, Child.blockedUsers) { result in
                    switch result {
                    case .failure(let error):
                        XCTFail(String(describing: error))
                        expectation.fulfill()
                    case .success(let data):
                        let blockedUsers = data.asBlockedUsersArray
                        XCTAssertEqual(blockedUsers.count, 2)
                        XCTAssert(blockedUsers.contains(blockedUser1))
                        XCTAssert(blockedUsers.contains(blockedUser2))
                        expectation.fulfill()
                    }
                }
            }
        }
    }

    func testDatasnapshotAsConvosArray() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTests.sendMessage { _, convo, _, _ in
            Shared.firebaseHelper.get(Child.convos, convo.senderId) { result in
                switch result {
                case .failure(let error):
                    XCTFail(String(describing: error))
                    expectation.fulfill()
                case .success(let data):
                    let convos = data.asConvosArray(proxyKey: nil)
                    XCTAssertEqual(convos.count, 1)
                    XCTAssert(convos.contains(convo))
                    expectation.fulfill()
                }
            }
        }
    }

    func testDatasnapshotAsMessagesArray() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTests.sendMessage { message, _, _, _ in
            Shared.firebaseHelper.get(Child.messages, message.parentConvoKey) { result in
                switch result {
                case .failure(let error):
                    XCTFail(String(describing: error))
                    expectation.fulfill()
                case .success(let data):
                    let messages = data.asMessagesArray
                    XCTAssertEqual(messages.count, 1)
                    XCTAssert(messages.contains(message))
                    expectation.fulfill()
                }
            }
        }
    }

    func testDatasnapshotAsProxiesArray() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTests.makeProxy { proxy1 in
            FirebaseTests.makeProxy { proxy2 in
                Shared.firebaseHelper.get(Child.proxies, FirebaseTests.uid) { result in
                    switch result {
                    case .failure(let error):
                        XCTFail(String(describing: error))
                        expectation.fulfill()
                    case .success(let data):
                        let proxies = data.asProxiesArray
                        XCTAssertEqual(proxies.count, 2)
                        XCTAssert(proxies.contains(proxy1))
                        XCTAssert(proxies.contains(proxy2))
                        expectation.fulfill()
                    }
                }
            }
        }
    }

    func testDeleteProxy() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTests.sendMessage { message, convo, _, receiver in
            Shared.database.delete(receiver) { error in
                XCTAssertNil(error, String(describing: error))
                let work = GroupWork()
                work.checkDeleted(.contact(convo.receiverId), for: convo.senderId)
                work.checkDeleted(.contact(convo.senderId), for: convo.receiverId)
                work.checkDeleted(Child.convos, receiver.ownerId, convo.key)
                work.checkDeleted(Child.proxies, receiver.ownerId, receiver.key)
                work.checkDeleted(Child.proxyKeys, receiver.key)
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
        Shared.database.set(userProperty, for: FirebaseTests.uid) { error in
            XCTAssertNil(error, String(describing: error))
            Shared.database.delete(userProperty, for: FirebaseTests.uid) { error in
                XCTAssertNil(error, String(describing: error))
                let work = GroupWork()
                work.checkDeleted(.registrationToken(registrationToken), for: FirebaseTests.uid)
                work.allDone {
                    expectation.fulfill()
                }
            }
        }
    }

    func testGetUserPropertySound() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        Shared.database.set(.soundOn(true), for: FirebaseTests.uid) { error in
            XCTAssertNil(error, String(describing: error))
            Shared.database.get(.soundOn(Bool()), for: FirebaseTests.uid) { result in
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

        Shared.database.makeProxy(currentProxyCount: 0, ownerId: FirebaseTests.uid) { result in
            switch result {
            case .failure(let error):
                XCTFail(String(describing: error))
                expectation.fulfill()
            case .success(let proxy):
                let work = GroupWork()
                work.checkProxySet(proxy)
                work.checkProxyKeySet(proxy)
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
        let firebase = Firebase(options)

        firebase.makeProxy(currentProxyCount: 0, ownerId: FirebaseTests.uid) { result in
            switch result {
            case .failure(let error):
                XCTFail(String(describing: error))
                expectation.fulfill()
            case .success:
                firebase.makeProxy(currentProxyCount: 1, ownerId: FirebaseTests.uid) { result in
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

        FirebaseTests.sendMessage { message, _, _, receiver in
            let date = Date()
            Shared.database.read(message, at: date) { error in
                XCTAssertNil(error, String(describing: error))
                let work = GroupWork()
                work.checkDeleted(Child.users, message.receiverId, Child.unreadMessages, message.messageId)
                work.check(.dateRead(date), for: message)
                work.check(.hasUnreadMessage(false), ownerId: message.receiverId, convoKey: message.parentConvoKey)
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

        FirebaseTests.sendMessage { message, convo, _, receiver in
            Shared.database.sendMessage(convo: convo, text: FirebaseTests.text) { result in
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

        FirebaseTests.sendMessage { message, convo, sender, receiver in
            let work = GroupWork()

            // Check convo updates
            work.check(.proxiesInteractedWith(1), equals: 1, uid: receiver.ownerId)
            work.check(.proxiesInteractedWith(1), equals: 1, uid: sender.ownerId)
            work.checkConvoSet(convo, asSender: true)
            work.checkConvoSet(convo, asSender: false)

            // Check message updates
            work.checkMessageSet(message)

            // Check receiver updates
            work.check(.contact(sender.ownerId), for: receiver.ownerId)
            work.check(.messagesReceived(1), equals: 1, uid: convo.receiverId)
            work.checkUnreadMessageSet(message)
            work.check(.hasUnreadMessage(true), for: convo, asSender: false)
            work.check(.hasUnreadMessage(true), for: receiver)
            work.check(.timestamp(convo.timestamp), for: convo, asSender: false)
            work.check(.timestamp(convo.timestamp), for: receiver)
            work.check(.lastMessage(FirebaseTests.text), for: convo, asSender: false)
            work.check(.lastMessage(FirebaseTests.text), for: receiver)

            // Check sender updates
            work.check(.contact(receiver.ownerId), for: sender.ownerId)
            work.check(.messagesSent(1), equals: 1, uid: sender.ownerId)
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

        FirebaseTests.sendMessage { _, senderConvo, _, receiverProxy in
            Shared.database.delete(receiverProxy) { error in
                XCTAssertNil(error, String(describing: error))
                Firebase.getConvo(ownerId: senderConvo.senderId, convoKey: senderConvo.key) { result in
                    switch result {
                    case .failure(let error):
                        XCTFail(String(describing: error))
                        expectation.fulfill()
                    case .success(let convo):
                        Shared.database.sendMessage(convo: convo, text: FirebaseTests.text) { result in
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

    func testSendMessageAfterReceiverIsBlocking() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTests.sendMessage { _, convo, sender, receiver in
            let blockedUser = BlockedUser(
                blockee: convo.senderId,
                blockeeProxyName: convo.senderProxyName,
                blocker: convo.receiverId,
                convoKey: convo.key
            )
            Shared.database.block(blockedUser) { error in
                XCTAssertNil(error, String(describing: error))
                Shared.database.sendMessage(
                    sender: sender,
                    receiverProxyKey: receiver.key,
                    text: FirebaseTests.text) { result in
                        switch result {
                        case .failure(let error):
                            if case ProxyError.receiverIsBlocking = error {
                                expectation.fulfill()
                            } else {
                                XCTFail(String(describing: error))
                                expectation.fulfill()
                            }
                        case .success:
                            XCTFail()
                            expectation.fulfill()
                        }
                }
            }
        }
    }

    func testSendMessageWhileAlreadyChattingWithUser() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTests.sendMessage { _, convo, _, _ in
            Shared.database.sendMessage(convo: convo, text: FirebaseTests.text) { result in
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

    func testSendMessageWhileAlreadyChattingWithUserThroughDifferentProxy() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTests.sendMessage { _, _, _, receiver in
            FirebaseTests.makeProxy { sender2 in
                Shared.database.sendMessage(
                    sender: sender2,
                    receiverProxyKey: receiver.key,
                    text: FirebaseTests.text) { result in
                        switch result {
                        case .failure(let error):
                            if case ProxyError.alreadyChattingWithUser = error {
                                expectation.fulfill()
                            } else {
                                XCTFail(String(describing: error))
                                expectation.fulfill()
                            }
                        case .success:
                            XCTFail()
                            expectation.fulfill()
                        }
                }
            }
        }
    }

    func testSendMessageWithSenderConvo() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTests.sendMessage { _, convo, _, _ in
            Shared.database.sendMessage(convo: convo, text: FirebaseTests.text) { result in
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

        FirebaseTests.sendMessage { _, convo, proxy, _ in
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

        FirebaseTests.sendMessage { _, convo, proxy, _ in
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

        FirebaseTests.sendMessage { _, convo, _, _ in
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

        Shared.database.set(.registrationToken(registrationToken1), for: FirebaseTests.uid) { error in
            XCTAssertNil(error, String(describing: error))
            Shared.database.set(.registrationToken(registrationToken2), for: FirebaseTests.uid) { error in
                XCTAssertNil(error, String(describing: error))
                Shared.firebaseHelper.get(Child.users, FirebaseTests.uid, Child.registrationTokens) { result in
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

        Shared.database.set(.soundOn(true), for: FirebaseTests.uid) { error in
            XCTAssertNil(error, String(describing: error))
            Shared.database.get(.soundOn(Bool()), for: FirebaseTests.uid) { result in
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

    func testUnblockUser() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTests.sendMessage { _, convo, _, _ in
            let blockedUser = BlockedUser(convo: convo)
            Shared.database.block(blockedUser) { error in
                XCTAssertNil(error, String(describing: error))
                Shared.database.unblock(blockedUser) { error in
                    XCTAssertNil(error, String(describing: error))
                    let work = GroupWork()
                    work.check(.receiverIsBlocked(false), ownerId: blockedUser.blocker, convoKey: blockedUser.convoKey)
                    work.check(.receiverIsBlocking(false), ownerId: blockedUser.blockee, convoKey: blockedUser.convoKey)
                    work.checkDeleted(Child.users, blockedUser.blocker, Child.blockedUsers, blockedUser.blockee)
                    work.allDone {
                        expectation.fulfill()
                    }
                }
            }
        }
    }
}

private extension FirebaseTests {
    static func makeProxy(ownerId: String = FirebaseTests.uid, completion: @escaping (Proxy) -> Void) {
        Shared.database.makeProxy(currentProxyCount: 0, ownerId: ownerId) { result in
            switch result {
            case .failure:
                XCTFail()
            case .success(let proxy):
                completion(proxy)
            }
        }
    }

    // swiftlint:disable line_length
    static func sendMessage(completion: @escaping (_ message: Message, _ convo: Convo, _ sender: Proxy, _ receiver: Proxy) -> Void) {
        makeProxy { sender in
            makeProxy (ownerId: uid2) { receiver in
                Shared.database.sendMessage(sender: sender, receiverProxyKey: receiver.key, text: text) { result in
                    switch result {
                    case .failure(let error):
                        XCTFail(String(describing: error))
                    case .success(let tuple):
                        Firebase.getConvo(ownerId: tuple.convo.senderId, convoKey: tuple.convo.key) { result in
                            switch result {
                            case .failure(let error):
                                XCTFail(String(describing: error))
                            case .success(let convo):
                                completion(tuple.message, convo, sender, receiver)
                            }
                        }
                    }
                }
            }
        }
    }
    // swiftlint:enable line_length
}

extension GroupWork {
    static func checkEquals(_ data: DataSnapshot?, _ any: Any, function: String, line: Int) {
        let errorMessage = GroupWork.makeErrorMessage(function: function, line: line)
        switch any {
        case let value as Bool:
            XCTAssertEqual(data?.value as? Bool, value, errorMessage)
        case let value as Double:
            XCTAssertEqual((data?.value as? Double)?.rounded(), value.rounded(), errorMessage)
        case let value as Int:
            XCTAssertEqual(data?.value as? Int, value, errorMessage)
        case let value as String:
            XCTAssertEqual(data?.value as? String, value, errorMessage)
        default:
            XCTFail(errorMessage)
        }
    }

    static func makeErrorMessage(function: String, line: Int) -> String {
        return "Function: \(function), Line: \(line)."
    }

    func check(_ property: SettableConvoProperty,
               for convo: Convo,
               asSender: Bool,
               function: String = #function,
               line: Int = #line) {
        let (uid, _) = GroupWork.getOwnerIdAndProxyKey(convo: convo, asSender: asSender)
        check(property, ownerId: uid, convoKey: convo.key, function: function, line: line)
    }

    func check(_ property: SettableConvoProperty,
               ownerId: String,
               convoKey: String,
               function: String = #function,
               line: Int = #line) {
        start()
        Shared.firebaseHelper.get(Child.convos, ownerId, convoKey, property.properties.name) { result in
            switch result {
            case .failure(let error):
                XCTFail(String(describing: error))
            case .success(let data):
                GroupWork.checkEquals(data, property.properties.value, function: function, line: line)
            }
            self.finish(withResult: true)
        }
    }

    func check(_ property: SettableMessageProperty,
               for message: Message,
               function: String = #function,
               line: Int = #line) {
        start()
        Shared.firebaseHelper.get(
            Child.messages,
            message.parentConvoKey,
            message.messageId,
            property.properties.name) { result in
                switch result {
                case .failure(let error):
                    XCTFail(String(describing: error))
                case .success(let data):
                    switch property {
                    case .dateRead(let date):
                        GroupWork.checkEquals(data, date.timeIntervalSince1970, function: function, line: line)
                    }
                }
                self.finish(withResult: true)
        }
    }

    func check(_ property: SettableProxyProperty, for proxy: Proxy, function: String = #function, line: Int = #line) {
        check(property, ownerId: proxy.ownerId, proxyKey: proxy.key, function: function, line: line)
    }

    func check(_ property: SettableProxyProperty,
               forProxyIn convo: Convo,
               asSender: Bool,
               function: String = #function,
               line: Int = #line) {
        let (uid, proxyKey) = GroupWork.getOwnerIdAndProxyKey(convo: convo, asSender: asSender)
        check(property, ownerId: uid, proxyKey: proxyKey, function: function, line: line)
    }

    func check(_ property: SettableProxyProperty,
               ownerId: String,
               proxyKey: String,
               function: String = #function,
               line: Int = #line) {
        start()
        Shared.firebaseHelper.get(Child.proxies, ownerId, proxyKey, property.properties.name) { result in
            switch result {
            case .failure(let error):
                XCTFail(String(describing: error))
            case .success(let data):
                GroupWork.checkEquals(data, property.properties.value, function: function, line: line)
            }
            self.finish(withResult: true)
        }
    }

    func check(_ property: IncrementableUserProperty,
               equals value: Int,
               uid: String,
               function: String = #function,
               line: Int = #line) {
        start()
        Shared.firebaseHelper.get(Child.users, uid, Child.stats, property.properties.name) { result in
            switch result {
            case .failure(let error):
                XCTFail(String(describing: error))
            case .success(let data):
                GroupWork.checkEquals(data, value, function: function, line: line)
            }
            self.finish(withResult: true)
        }
    }

    func check(_ userProperty: SettableUserProperty, for uid: String, function: String = #function, line: Int = #line) {
        start()
        var value: Any
        switch userProperty {
        case .contact, .registrationToken:
            value = true
        default:
            value = userProperty.properties.value
        }
        Shared.database.get(userProperty, for: uid) { result in
            switch result {
            case .failure(let error):
                XCTFail(String(describing: error))
            case .success(let data):
                GroupWork.checkEquals(data, value, function: function, line: line)
            }
            self.finish(withResult: true)
        }
    }

    func checkDeleted(_ first: String, _ rest: String..., function: String = #function, line: Int = #line) {
        start()
        Shared.firebaseHelper.get(first, rest) { result in
            switch result {
            case .failure(let error):
                XCTFail(String(describing: error))
            case .success(let data):
                XCTAssertFalse(data.exists(), GroupWork.makeErrorMessage(function: function, line: line))
            }
            self.finish(withResult: true)
        }
    }

    func checkDeleted(_ userProperty: SettableUserProperty,
                      for uid: String,
                      function: String = #function,
                      line: Int = #line) {
        start()
        Shared.database.get(userProperty, for: uid) { result in
            switch result {
            case .failure(let error):
                XCTFail(String(describing: error))
            case .success(let data):
                XCTAssertFalse(data.exists(), GroupWork.makeErrorMessage(function: function, line: line))
            }
            self.finish(withResult: true)
        }
    }

    func checkBlockedUserSet(_ blockedUser: BlockedUser) {
        start()
        Shared.firebaseHelper.get(Child.users, blockedUser.blocker, Child.blockedUsers, blockedUser.blockee) { result in
            switch result {
            case .failure(let error):
                XCTFail(String(describing: error))
            case .success(let data):
                XCTAssertEqual(try? BlockedUser(data), blockedUser)
            }
            self.finish(withResult: true)
        }
    }

    func checkConvoSet(_ convo: Convo, asSender: Bool) {
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

    func checkMessageSet(_ message: Message) {
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

    func checkProxySet(_ proxy: Proxy) {
        start()
        Shared.firebaseHelper.get(Child.proxies, FirebaseTests.uid, proxy.key) { result in
            switch result {
            case .failure(let error):
                XCTFail(String(describing: error))
            case .success(let data):
                XCTAssertEqual(try? Proxy(data), proxy)
            }
            self.finish(withResult: true)
        }
    }

    func checkProxyKeySet(_ proxy: Proxy) {
        start()
        Shared.firebaseHelper.get(Child.proxyKeys, proxy.key) { result in
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

    func checkUnreadMessageSet(_ message: Message) {
        start()
        Shared.firebaseHelper.get(
            Child.users,
            message.receiverId,
            Child.unreadMessages,
            message.messageId) { result in
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
