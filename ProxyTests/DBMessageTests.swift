import XCTest
import GroupWork
@testable import Proxy

class DBMessageTests: DBTest {
    private static let senderText = "You: \(text)"

    func testDeleteUnreadMessage() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.sendMessage { (message, _, _, _) in
            DB.deleteUnreadMessage(message) { (success) in
                XCTAssert(success)
                let work = GroupWork()
                work.checkDeleted(Child.userInfo, message.receiverId, Child.unreadMessages, message.messageId)
                work.checkDeleted(Child.convos, message.receiverId, message.parentConvoKey)
                work.allDone {
                    expectation.fulfill()
                }
            }
        }
    }

    func testRead() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.sendMessage { (message, _, _, receiver) in
            let date = Date()
            DB.read(message, date: date) { (success) in
                XCTAssert(success)
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

        DBTest.sendMessage { (message, _, _, _) in
            DBTest.sendMessage { (_, _, _, receiver) in
                DB.read(message) { (success) in
                    XCTAssert(success)
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

        DBTest.sendMessage { (message, convo, sender, receiver) in
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
            work.check(.lastMessage(DBTest.text), for: convo, asSender: false)
            work.check(.lastMessage(DBTest.text), for: receiver)

            // Check sender updates
            work.check(.messagesSent, equals: 1, uid: sender.ownerId)
            work.check(.timestamp(convo.timestamp), for: convo, asSender: true)
            work.check(.timestamp(convo.timestamp), for: sender)
            work.check(.lastMessage(DBMessageTests.senderText), for: convo, asSender: true)
            work.check(.lastMessage(DBMessageTests.senderText), for: sender)

            work.allDone {
                expectation.fulfill()
            }
        }
    }

    func testSendMessageWithSenderConvo() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.sendMessage { (_, convo, _, _) in
            DB.sendMessage(convo: convo, text: DBTest.text) { (result) in
                XCTAssertNotNil(result)
                expectation.fulfill()
            }
        }
    }

    func testSendMessageAfterReceiverDeletedProxy() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.sendMessage { (_, senderConvo, _, receiverProxy) in
            DB.deleteProxy(receiverProxy) { (success) in
                XCTAssert(success)
                DB.getConvo(uid: senderConvo.senderId, key: senderConvo.key) { (convo) in
                    guard let updatedConvo = convo else {
                        XCTFail()
                        return
                    }
                    DB.sendMessage(convo: updatedConvo, text: DBTest.text) { (result) in
                        switch result {
                        case .failure(let error):
                            switch error {
                            case .receiverDeletedProxy:
                                break
                            default:
                                XCTFail()
                                expectation.fulfill()
                            }
                            let work = GroupWork()
                            work.checkDeleted(Child.convos, receiverProxy.ownerId, updatedConvo.key)
                            work.checkDeleted(Child.convos, receiverProxy.key, updatedConvo.key)
                            work.checkDeleted(Child.proxies, receiverProxy.ownerId, updatedConvo.key)
                            work.allDone {
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
    }
}

extension GroupWork {
    func checkConvoCreated(_ convo: Convo, asSender: Bool) {
        let (uid, _) = GroupWork.getOwnerIdAndProxyKey(convo: convo, asSender: asSender)
        start()
        DB.get(Child.convos, uid, convo.key) { (data) in
            XCTAssertNotNil(Convo(data!))
            self.finish(withResult: true)
        }
    }

    func checkMessageCreated(_ message: Message) {
        start()
        DB.get(Child.messages, message.parentConvoKey, message.messageId) { (data) in
            XCTAssertEqual(Message(data!), message)
            self.finish(withResult: true)
        }
    }

    func checkUnreadMessageCreated(_ message: Message) {
        start()
        DB.get(Child.userInfo, message.receiverId, Child.unreadMessages, message.messageId) { (data) in
            XCTAssertEqual(Message(data!), message)
            self.finish(withResult: true)
        }
    }
}
