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

                let work = GroupWork()
                work.check(.dateRead(currentTime), forMessage: message)
                work.check(.hasUnreadMessage(false), forConvoWithKey: message.parentConvo, ownerId: message.receiverId, proxyKey: message.receiverProxyKey)
                work.check(.hasUnreadMessage(false), forProxy: receiver)
                work.check(.read(true), forMessage: message)
                work.checkUnreadMessageDeleted(message)
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

                DBMessage.read(message1) { (success) in
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

    func testSendMessage() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.sendMessage { (message, convo, sender, receiver) in
            let work = GroupWork()

            // Check message updates
            work.checkMessageCreated(message)

            // Check receiver updates
            work.check(.lastMessage(DBTest.text), forConvo: convo, asSender: false)
            work.check(.lastMessage(DBTest.text), forProxy: receiver)
            work.check(.messagesReceived, 1, forUser: convo.receiverId)
            work.check(.timestamp(convo.timestamp), forConvo: convo, asSender: false)
            work.check(.timestamp(convo.timestamp), forProxy: receiver)
            work.check(.hasUnreadMessage(true), forConvo: convo, asSender: false)
            work.check(.hasUnreadMessage(true), forProxy: receiver)
            work.checkUnreadMessageCreated(message)
            
            // Check sender updates
            work.check(.lastMessage(DBMessageTests.senderText), forConvo: convo, asSender: true)
            work.check(.lastMessage(DBMessageTests.senderText), forProxy: sender)
            work.check(.messagesSent, 1, forUser: sender.ownerId)
            work.check(.timestamp(convo.timestamp), forConvo: convo, asSender: true)
            work.check(.timestamp(convo.timestamp), forProxy: sender)

            work.allDone {
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

                    let work = GroupWork()
                    work.check(.convoCount(1), forProxy: sender)
                    work.check(.receiverLeftConvo(false), forConvo: convo, asSender: true)
                    work.check(.senderLeftConvo(false), forConvo: convo, asSender: false)
                    work.allDone {
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
                    
                    let work = GroupWork()
                    work.check(.convoCount(1), forProxy: sender)
                    work.check(.receiverLeftConvo(false), forConvo: convo, asSender: false)
                    work.check(.senderLeftConvo(false), forConvo: convo, asSender: true)
                    work.allDone {
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

                let key = GroupWork()
                key.check(.mediaType(mediaType), forMessage: message)
                key.check(.mediaURL(mediaURL), forMessage: message)
                key.allDone {
                    expectation.fulfill()
                }
            }
        }
    }

    func testToMessagesArray() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.sendMessage { (message, _, _, _) in

            DB.get(Child.messages, message.parentConvo) { (data) in
                XCTAssertEqual(data?.toMessagesArray()[safe: 0], message)

                expectation.fulfill()
            }
        }
    }
}

extension GroupWork {
    func checkMessageCreated(_ message: Message) {
        start()
        DB.get(Child.messages, message.parentConvo, message.key) { (data) in
            XCTAssertEqual(Message(data?.value as AnyObject), message)
            self.finish(withResult: true)
        }
    }

    func checkUnreadMessageCreated(_ message: Message) {
        start()
        DB.get(Child.userInfo, message.receiverId, Child.unreadMessages, message.key) { (data) in
            XCTAssertEqual(Message(data?.value as AnyObject), message)
            self.finish(withResult: true)
        }
    }

    func checkUnreadMessageDeleted(_ message: Message) {
        start()
        DB.get(Child.userInfo, message.receiverId, Child.unreadMessages, message.key) { (data) in
            XCTAssertFalse(data?.exists() ?? true)
            self.finish(withResult: true)
        }
    }
}
