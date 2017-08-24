import XCTest
@testable import proxy

class DBMessageTests: DBTest {
    private static let text = "🤤"
    private static let senderText = "You: \(text)"
    
    func testSendMessage() {
        let expectation = self.expectation(description: #function)
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
                    key.check(.lastMessage(DBMessageTests.senderText), forConvo: convo, asSender: true)
                    key.check(.timestamp(convo.timestamp), forConvo: convo, asSender: true)
                    
                    key.check(.lastMessage(DBMessageTests.senderText), forProxy: sender)
                    key.check(.timestamp(convo.timestamp), forProxy: sender)

                    key.check(.messagesSent, equals: 1, forUser: sender.ownerId)
                    
                    // Check receiver updates
                    key.check(.lastMessage(DBMessageTests.text), forConvo: convo, asSender: false)
                    key.check(.timestamp(convo.timestamp), forConvo: convo, asSender: false)
                    key.check(.unreadCount(1), forConvo: convo, asSender: false)
                    
                    key.check(.timestamp(convo.timestamp), forProxy: receiver)
                    key.check(.lastMessage(DBMessageTests.text), forProxy: receiver)
                    key.check(.unreadCount(1), forProxy: receiver)
                    
                    key.check(.messagesReceived, equals: 1, forUser: convo.receiverId)
                    key.check(.unreadCount, equals: 1, forUser: convo.receiverId)
                    
                    // Check message updates
                    key.checkMessageCreated(message)
                    
                    key.notify {
                        key.finishWorkGroup()
                        expectation.fulfill()
                    }
                }
            }
        }
    }

    func testSendMessageWhileReceiverLeftConvo() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (senderConvo, sender, receiver) in
            DBConvo.leaveConvo(senderConvo) { (success) in
                XCTAssert(success)

                DBMessage.sendMessage(from: receiver, to: sender, withText: DBMessageTests.text) { (result) in
                    guard let (convo, _) = result else {
                        XCTFail()
                        return
                    }

                    let key = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
                    key.check(.receiverLeftConvo(false), forConvo: convo, asSender: true)
                    key.check(.senderLeftConvo(false), forConvo: convo, asSender: false)
                    key.check(.convoCount(1), forProxy: sender)
                    key.notify {
                        key.finishWorkGroup()
                        expectation.fulfill()
                    }
                }
            }
        }
    }

    func testSendMessageWhileSenderLeftConvo() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }
        
        DBTest.makeConvo { (senderConvo, sender, receiver) in
            DBConvo.leaveConvo(senderConvo) { (success) in
                XCTAssert(success)
                
                DBMessage.sendMessage(from: sender, to: receiver, withText: DBMessageTests.text) { (result) in
                    guard let (convo, _) = result else {
                        XCTFail()
                        return
                    }
                    
                    let key = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
                    key.check(.receiverLeftConvo(false), forConvo: convo, asSender: false)
                    key.check(.senderLeftConvo(false), forConvo: convo, asSender: true)
                    key.check(.convoCount(1), forProxy: sender)
                    key.notify {
                        key.finishWorkGroup()
                        expectation.fulfill()
                    }
                }
            }
        }
    }
}

extension AsyncWorkGroupKey {
    func checkMessageCreated(_ message: Message) {
        startWork()
        DB.get(Child.Messages, message.parentConvo, message.key) { (data) in
            XCTAssertEqual(Message(data?.value as AnyObject), message)
            self.finishWork()
        }
    }
}
