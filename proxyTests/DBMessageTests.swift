import XCTest
@testable import proxy

class DBMessageTests: DBTest {
    private static let senderText = "You: \(text)"

    func testSendMessage() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.sendMessage { (message, convo, sender, receiver) in
            let key = AsyncWorkGroupKey.makeAsyncWorkGroupKey()

            // Check sender updates
            key.check(.lastMessage(DBMessageTests.senderText), forConvo: convo, asSender: true)
            key.check(.lastMessage(DBMessageTests.senderText), forProxy: sender)
            key.check(.messagesSent, 1, forUser: sender.ownerId)
            key.check(.timestamp(convo.timestamp), forConvo: convo, asSender: true)
            key.check(.timestamp(convo.timestamp), forProxy: sender)

            // Check receiver updates
            key.check(.lastMessage(DBTest.text), forConvo: convo, asSender: false)
            key.check(.lastMessage(DBTest.text), forProxy: receiver)
            key.check(.messagesReceived, 1, forUser: convo.receiverId)
            key.check(.timestamp(convo.timestamp), forConvo: convo, asSender: false)
            key.check(.timestamp(convo.timestamp), forProxy: receiver)
            key.check(.unreadCount(1), forConvo: convo, asSender: false)
            key.check(.unreadCount(1), forProxy: receiver)
            key.check(.unreadCount, 1, forUser: convo.receiverId)

            // Check message updates
            key.checkMessageCreated(message)

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

    func testSetRead() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.sendMessage { (message, _, _, receiver) in
            let currentTime = Date().timeIntervalSince1970.rounded()

            DBMessage.setRead(forMessage: message, atDate: currentTime) { (success) in
                XCTAssert(success)

                let key = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
                key.check(.dateRead(currentTime), forMessage: message)
                key.check(.read(true), forMessage: message)
                key.check(.unreadCount(0), forConvoWithKey: message.parentConvo, ownerId: receiver.ownerId, proxyKey: receiver.key)
                key.check(.unreadCount(0), forProxy: receiver)
                key.check(.unreadCount, 0, forUser: receiver.ownerId)
                key.notify {
                    key.finishWorkGroup()
                    expectation.fulfill()
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
