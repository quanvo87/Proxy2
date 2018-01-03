import XCTest
import GroupWork
@testable import Proxy

class DBMessageTests: DBTest {
    private static let senderText = "You: \(text)"

    func testRead() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.sendMessage { (message, _, _, receiver) in
            let date = Date()
            DB.read(message, atDate: date) { (success) in
                XCTAssert(success)
                let work = GroupWork()
                work.check(.dateRead(date), forMessage: message)
                work.check(.hasUnreadMessage(false), forConvoWithKey: message.parentConvoKey, ownerId: message.receiverId, proxyKey: message.receiverProxyKey)
                work.check(.hasUnreadMessage(false), forProxy: receiver)
                work.checkUnreadMessageCount(uid: message.receiverId, count: 0)
                work.allDone {
                    expectation.fulfill()
                }
            }
        }
    }

    func testReadWithOtherUnreadMessages() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.sendMessage { (message1, _, _, _) in
            DBTest.sendMessage { (message2, _, _, receiver) in
                DB.read(message1) { (success) in
                    XCTAssert(success)
                    let work = GroupWork()
                    work.check(.hasUnreadMessage(true), forProxy: receiver)
                    work.allDone {
                        expectation.fulfill()
                    }
                }
            }
        }
    }

    func testSendFirstMessage() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.sendMessage { (message, convo, sender, receiver) in
            let work = GroupWork()

            // Check convo made
            work.check(.proxiesInteractedWith, 1, forUser: receiver.ownerId)
            work.check(.proxiesInteractedWith, 1, forUser: sender.ownerId)
            work.checkConvoCreated(convo, asSender: true)
            work.checkConvoCreated(convo, asSender: false)

            // Check message updates
            work.checkMessageCreated(message)

            // Check receiver updates
            work.check(.messagesReceived, 1, forUser: convo.receiverId)
            work.checkUnreadMessageCreated(message)
            work.check(.hasUnreadMessage(true), forConvo: convo, asSender: false)
            work.check(.hasUnreadMessage(true), forProxy: receiver)
            work.check(.timestamp(convo.timestamp), forConvo: convo, asSender: false)
            work.check(.timestamp(convo.timestamp), forProxy: receiver)
            work.check(.lastMessage(DBTest.text), forConvo: convo, asSender: false)
            work.check(.lastMessage(DBTest.text), forProxy: receiver)
            
            // Check sender updates
            work.check(.messagesSent, 1, forUser: sender.ownerId)
            work.check(.timestamp(convo.timestamp), forConvo: convo, asSender: true)
            work.check(.timestamp(convo.timestamp), forProxy: sender)
            work.check(.lastMessage(DBMessageTests.senderText), forConvo: convo, asSender: true)
            work.check(.lastMessage(DBMessageTests.senderText), forProxy: sender)

            work.allDone {
                expectation.fulfill()
            }
        }
    }

    func testSendMessageWithSenderConvo() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.sendMessage { (_, convo, _, _) in
            DB.sendMessage(senderConvo: convo, text: DBTest.text) { (result) in
                XCTAssertNotNil(result)
                expectation.fulfill()
            }
        }
    }

    func testSendMessageAfterReceiverDeletedProxy() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.sendMessage { (message, senderConvo, senderProxy, receiverProxy) in
            DB.deleteProxy(receiverProxy) { (success) in
                XCTAssert(success)
                DB.getConvo(withKey: senderConvo.key, belongingTo: senderConvo.senderId) { (convo) in
                    guard let updatedConvo = convo else {
                        XCTFail()
                        return
                    }
                    DB.sendMessage(senderConvo: updatedConvo, text: DBTest.text) { (result) in
                        switch result {
                        case .failure(let error):
                            switch error {
                            case .receiverDeletedProxy:
                                break
                            default:
                                XCTFail()
                            }
                            let work = GroupWork()
                            work.checkDeleted(at: Child.convos, receiverProxy.ownerId, updatedConvo.key)
                            work.checkDeleted(at: Child.convos, receiverProxy.key, updatedConvo.key)
                            work.checkDeleted(at: Child.proxies, receiverProxy.ownerId, updatedConvo.key)
                            work.allDone {
                                expectation.fulfill()
                            }
                        case .success:
                            XCTFail()
                        }
                    }
                }
            }
        }
    }
}

extension GroupWork {
    func checkConvoCreated(_ convo: Convo, asSender: Bool) {
        let (ownerId, proxyKey) = GroupWork.getOwnerIdAndProxyKey(fromConvo: convo, asSender: asSender)
        start()
        DB.get(Child.convos, ownerId, convo.key) { (data) in
            XCTAssertNotNil(Convo(data!))
            self.finish(withResult: true)
        }
        start()
        DB.get(Child.convos, proxyKey, convo.key) { (data) in
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
