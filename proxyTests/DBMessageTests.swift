import XCTest
@testable import proxy

class DBMessageTests: DBTest {
    private static let text = "🤤"
    private static let senderText = "You: \(text)"

//    private static func sendMessage(completion: @escaping (_ senderProxy: Proxy, _ receiverProxy: Proxy, _ senderConvo: Convo, _ message: Message) -> Void) {
//        DBTest.makeProxy { (senderProxy) in
//            DBTest.makeProxy(forUser: DBTest.testUser) { (receiverProxy) in
//                DBMessage.sendMessage(from: senderProxy, to: receiverProxy, withText: text) { (result) in
//                    guard let result = result else {
//                        XCTFail()
//                        return
//                    }
//
//                    completion(senderProxy, receiverProxy, result.convo, result.message)
//                }
//            }
//        }
//    }

    func testSendMessage() {
        x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeProxy { (sender) in
            DBTest.makeProxy(forUser: DBTest.testUser) { (receiver) in
                DBMessage.sendMessage(from: sender, to: receiver, withText: DBMessageTests.text) { (result) in
                    guard let (convo, message) = result else {
                        XCTFail()
                        return
                    }

                    let key = AsyncWorkGroupKey.makeAsyncWorkGroupKey()

                    // Check sender updates
                    key.check(.message(DBMessageTests.senderText), forConvo: convo, asSender: true)
                    key.check(.timestamp(convo.timestamp), forConvo: convo, asSender: true)

                    key.check(.message(DBMessageTests.senderText), forProxy: sender)
                    key.check(.timestamp(convo.timestamp), forProxy: sender)

                    key.check(.messagesSent, equals: 1, forUser: sender.ownerId)

                    // Check receiver updates
                    key.check(.message(DBMessageTests.text), forConvo: convo, asSender: false)
                    key.check(.timestamp(convo.timestamp), forConvo: convo, asSender: false)
                    key.check(.unread(1), forConvo: convo, asSender: false)

                    key.check(.timestamp(convo.timestamp), forProxy: receiver)
                    key.check(.message(DBMessageTests.text), forProxy: receiver)
                    key.check(.unread(1), forProxy: receiver)

                    key.check(.messagesReceived, equals: 1, forUser: convo.receiverId)
                    key.check(.unread, equals: 1, forUser: convo.receiverId)

                    // Check message updates
                    key.checkMessageCreated(message)

                    key.notify {
                        key.finishWorkGroup()
                        self.x.fulfill()
                    }
                }
            }
        }
    }

    func test() {
        x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (senderConvo, senderProxy, receiverProxy) in
            DBConvo.leaveConvo(senderConvo) { (success) in
                XCTAssert(success)

                DBMessage.sendMessage(from: senderProxy, to: receiverProxy, withText: DBMessageTests.text) { (result) in
                    guard let (_, _) = result else {
                        XCTFail()
                        return
                    }

                    let key = AsyncWorkGroupKey.makeAsyncWorkGroupKey()

                    key.check(.convos(1), forProxy: senderProxy)

                    key.notify {
                        key.finishWorkGroup()
                        self.x.fulfill()
                    }
                }
            }
        }
    }
}

extension AsyncWorkGroupKey {
    func checkMessageCreated(_ message: Message) {
        startWork()
        DB.get(Path.Messages, message.parentConvo, message.key) { (data) in
            XCTAssertEqual(Message(data?.value as AnyObject), message)
            self.finishWork()
        }
    }
}
