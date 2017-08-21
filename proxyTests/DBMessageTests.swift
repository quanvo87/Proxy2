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

        DBTest.makeProxy { (senderProxy) in
            DBTest.makeProxy(forUser: DBTest.testUser) { (receiverProxy) in
                DBMessage.sendMessage(from: senderProxy, to: receiverProxy, withText: DBMessageTests.text) { (result) in
                    guard let (senderConvo, message) = result else {
                        XCTFail()
                        return
                    }

                    let key = AsyncWorkGroupKey.makeAsyncWorkGroupKey()

                    // Check sender updates
                    key.checkMessagesSent(equals: 1, forUser: senderProxy.ownerId)
                    key.checkLastMessage(equals: DBMessageTests.senderText, forSenderProxyConvoOfConvo: senderConvo)
                    key.checkLastMessage(equals: DBMessageTests.senderText, forSenderProxyOfConvo: senderConvo)
                    key.checkLastMessage(equals: DBMessageTests.senderText, forSenderUserConvoOfConvo: senderConvo)
                    key.checkTimestamp(equals: senderConvo.timestamp, forSenderProxyConvoOfConvo: senderConvo)
                    key.checkTimestamp(equals: senderConvo.timestamp, forSenderProxyOfConvo: senderConvo)
                    key.checkTimestamp(equals: senderConvo.timestamp, forSenderUserConvoOfConvo: senderConvo)

                    // Check receiver updates
                    key.checkMessagesReceived(equals: 1, forUser: senderConvo.receiverId)
                    key.checkLastMessage(equals: DBMessageTests.text, forReceiverProxyOfConvo: senderConvo)
                    key.checkTimestamp(equals: senderConvo.timestamp, forReceiverProxyOfConvo: senderConvo)
                    key.checkUnread(equals: 1, forUser: senderConvo.receiverId)
                    key.checkUnread(equals: 1, forProxy: receiverProxy)
                    key.checkLastMessage(equals: DBMessageTests.text, forReceiverProxyConvoOfConvo: senderConvo)
                    key.checkLastMessage(equals: DBMessageTests.text, forReceiverUserConvoOfConvo: senderConvo)
                    key.checkTimestamp(equals: senderConvo.timestamp, forReceiverProxyConvoOfConvo: senderConvo)
                    key.checkTimestamp(equals: senderConvo.timestamp, forReceiverUserConvoOfConvo: senderConvo)
                    key.checkUnread(equals: 1, forReceiverProxyConvoOfConvo: senderConvo)
                    key.checkUnread(equals: 1, forReceiverUserConvoOfConvo: senderConvo)

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
                    guard let (senderConvo, message) = result else {
                        XCTFail()
                        return
                    }

                    let key = AsyncWorkGroupKey.makeAsyncWorkGroupKey()

                    key.checkConvoCount(equals: 1, forSenderProxyOfConvo: senderConvo)
                    

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
    func checkLastMessage(equals message: String, forReceiverProxyConvoOfConvo convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.receiverProxyKey, convo.key, Path.Message) { (data) in
            XCTAssertEqual(data?.value as? String, message)
            self.finishWork()
        }
    }

    func checkLastMessage(equals message: String, forReceiverProxyOfConvo convo: Convo) {
        startWork()
        DB.get(Path.Proxies, convo.receiverId, convo.receiverProxyKey, Path.Message) { (data) in
            XCTAssertEqual(data?.value as? String, message)
            self.finishWork()
        }
    }

    func checkLastMessage(equals message: String, forReceiverUserConvoOfConvo convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.receiverId, convo.key, Path.Message) { (data) in
            XCTAssertEqual(data?.value as? String, message)
            self.finishWork()
        }
    }

    func checkLastMessage(equals message: String, forSenderProxyConvoOfConvo convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.senderProxyKey, convo.key, Path.Message) { (data) in
            XCTAssertEqual(data?.value as? String, message)
            self.finishWork()
        }
    }

    func checkLastMessage(equals message: String, forSenderProxyOfConvo convo: Convo) {
        startWork()
        DB.get(Path.Proxies, convo.senderId, convo.senderProxyKey, Path.Message) { (data) in
            XCTAssertEqual(data?.value as? String, message)
            self.finishWork()
        }
    }

    func checkLastMessage(equals message: String, forSenderUserConvoOfConvo convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.senderId, convo.key, Path.Message) { (data) in
            XCTAssertEqual(data?.value as? String, message)
            self.finishWork()
        }
    }

    func checkMessageCreated(_ message: Message) {
        startWork()
        DB.get(Path.Messages, message.parentConvo, message.key) { (data) in
            XCTAssertEqual(Message(data?.value as AnyObject), message)
            self.finishWork()
        }
    }

    func checkMessagesReceived(equals messagesReceived: Int, forUser uid: String) {
        startWork()
        DB.get(Path.UserInfo, uid, Path.MessagesReceived) { (data) in
            XCTAssertEqual(data?.value as? Int, messagesReceived)
            self.finishWork()
        }
    }

    func checkMessagesSent(equals messagesSent: Int, forUser uid: String) {
        startWork()
        DB.get(Path.UserInfo, uid, Path.MessagesSent) { (data) in
            XCTAssertEqual(data?.value as? Int, messagesSent)
            self.finishWork()
        }
    }

    func checkTimestamp(equals timestamp: Double, forReceiverProxyConvoOfConvo convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.receiverProxyKey, convo.key, Path.Timestamp) { (data) in
            XCTAssertEqual((data?.value as? Double)?.rounded(), timestamp.rounded())
            self.finishWork()
        }
    }

    func checkTimestamp(equals timestamp: Double, forReceiverProxyOfConvo convo: Convo) {
        startWork()
        DB.get(Path.Proxies, convo.receiverId, convo.receiverProxyKey, Path.Timestamp) { (data) in
            XCTAssertEqual((data?.value as? Double)?.rounded(), timestamp.rounded())
            self.finishWork()
        }
    }

    func checkTimestamp(equals timestamp: Double, forReceiverUserConvoOfConvo convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.receiverId, convo.key, Path.Timestamp) { (data) in
            XCTAssertEqual((data?.value as? Double)?.rounded(), timestamp.rounded())
            self.finishWork()
        }
    }

    func checkTimestamp(equals timestamp: Double, forSenderProxyConvoOfConvo convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.senderProxyKey, convo.key, Path.Timestamp) { (data) in
            XCTAssertEqual((data?.value as? Double)?.rounded(), timestamp.rounded())
            self.finishWork()
        }
    }

    func checkTimestamp(equals timestamp: Double, forSenderProxyOfConvo convo: Convo) {
        startWork()
        DB.get(Path.Proxies, convo.senderId, convo.senderProxyKey, Path.Timestamp) { (data) in
            XCTAssertEqual((data?.value as? Double)?.rounded(), timestamp.rounded())
            self.finishWork()
        }
    }

    func checkTimestamp(equals timestamp: Double, forSenderUserConvoOfConvo convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.senderId, convo.key, Path.Timestamp) { (data) in
            XCTAssertEqual((data?.value as? Double)?.rounded(), timestamp.rounded())
            self.finishWork()
        }
    }

    func checkUnread(equals unread: Int, forReceiverProxyConvoOfConvo convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.receiverProxyKey, convo.key, Path.Unread) { (data) in
            XCTAssertEqual(data?.value as? Int, unread)
            self.finishWork()
        }
    }

    func checkUnread(equals unread: Int, forReceiverUserConvoOfConvo convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.receiverId, convo.key, Path.Unread) { (data) in
            XCTAssertEqual(data?.value as? Int, unread)
            self.finishWork()
        }
    }
}
