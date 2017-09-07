import XCTest
@testable import Proxy

class DBMessageTests: DBTest {
    private static let senderText = "You: \(text)"

    func testRead() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.sendMessage { (message, _, _, receiver) in
            let currentTime = Date().timeIntervalSince1970.rounded()

            DBMessage.read(message, atDate: currentTime) { (success) in
                XCTAssert(success)

                let key = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
                key.check(.dateRead(currentTime), forMessage: message)
                key.check(.hasUnreadMessage(false), forConvoWithKey: message.parentConvo, ownerId: message.receiverId, proxyKey: message.receiverProxyKey)
                key.check(.hasUnreadMessage(false), forProxy: receiver)
                key.check(.read(true), forMessage: message)
                key.checkUnreadMessageDeleted(message)
                key.notify {
                    key.finishWorkGroup()
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

                DBMessage.read(message1) { (success) in
                    XCTAssert(success)

                    let key = AsyncWorkGroupKey.makeAsyncWorkGroupKey()

                    key.check(.hasUnreadMessage(true), forProxy: receiver)

                    key.notify {
                        key.finishWorkGroup()

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
            let key = AsyncWorkGroupKey.makeAsyncWorkGroupKey()

            // Check message updates
            key.checkMessageCreated(message)

            // Check receiver updates
            key.check(.lastMessage(DBTest.text), forConvo: convo, asSender: false)
            key.check(.lastMessage(DBTest.text), forProxy: receiver)
            key.check(.messagesReceived, 1, forUser: convo.receiverId)
            key.check(.timestamp(convo.timestamp), forConvo: convo, asSender: false)
            key.check(.timestamp(convo.timestamp), forProxy: receiver)
            key.check(.hasUnreadMessage(true), forConvo: convo, asSender: false)
            key.check(.hasUnreadMessage(true), forProxy: receiver)
            key.checkUnreadMessageCreated(message)
            
            // Check sender updates
            key.check(.lastMessage(DBMessageTests.senderText), forConvo: convo, asSender: true)
            key.check(.lastMessage(DBMessageTests.senderText), forProxy: sender)
            key.check(.messagesSent, 1, forUser: sender.ownerId)
            key.check(.timestamp(convo.timestamp), forConvo: convo, asSender: true)
            key.check(.timestamp(convo.timestamp), forProxy: sender)

            key.notify {
                key.finishWorkGroup()
                expectation.fulfill()
            }
        }
    }

    func testSendMessageWhileReceiverLeftConvo() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (senderConvo, sender, receiver) in
            DBConvo.leaveConvo(senderConvo) { (success) in
                XCTAssert(success)

                DBMessage.sendMessage(from: receiver, to: sender, withText: "") { (result) in
                    guard let (_, convo) = result else {
                        XCTFail()
                        return
                    }

                    let key = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
                    key.check(.convoCount(1), forProxy: sender)
                    key.check(.receiverLeftConvo(false), forConvo: convo, asSender: true)
                    key.check(.senderLeftConvo(false), forConvo: convo, asSender: false)
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
                
                DBMessage.sendMessage(from: sender, to: receiver, withText: "") { (result) in
                    guard let (_, convo) = result else {
                        XCTFail()
                        return
                    }
                    
                    let key = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
                    key.check(.convoCount(1), forProxy: sender)
                    key.check(.receiverLeftConvo(false), forConvo: convo, asSender: false)
                    key.check(.senderLeftConvo(false), forConvo: convo, asSender: true)
                    key.notify {
                        key.finishWorkGroup()
                        expectation.fulfill()
                    }
                }
            }
        }
    }

    func testSetMedia() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.sendMessage { (message, _, _, _) in
            let mediaType = "media type"
            let mediaURL = "media URL"

            DBMessage.setMedia(for: message, mediaType: mediaType, mediaURL: mediaURL) { (success) in
                XCTAssert(success)

                let key = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
                key.check(.mediaType(mediaType), forMessage: message)
                key.check(.mediaURL(mediaURL), forMessage: message)
                key.notify {
                    key.finishWorkGroup()
                    expectation.fulfill()
                }
            }
        }
    }

    func testToMessagesArray() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.sendMessage { (message, _, _, _) in

            DB.get(Child.Messages, message.parentConvo) { (data) in
                XCTAssertEqual(data?.toMessagesArray()[safe: 0], message)

                expectation.fulfill()
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

    func checkUnreadMessageCreated(_ message: Message) {
        startWork()
        DB.get(Child.UserInfo, message.receiverId, Child.unreadMessages, message.key) { (data) in
            XCTAssertEqual(Message(data?.value as AnyObject), message)
            self.finishWork()
        }
    }

    func checkUnreadMessageDeleted(_ message: Message) {
        startWork()
        DB.get(Child.UserInfo, message.receiverId, Child.unreadMessages, message.key) { (data) in
            XCTAssertFalse(data?.exists() ?? true)
            self.finishWork()
        }
    }
}
