import FirebaseDatabase
import GroupWork
import XCTest
@testable import Proxy

class DBConvoTests: DBTest {
    func testDeleteConvo() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (convo, _, _) in
            DBConvo.deleteConvo(convo) { (success) in
                XCTAssert(success)

                let work = GroupWork()
                work.check(.convoCount(0), forProxyInConvo: convo, asSender: true)
                work.checkConvoDeleted(convo, asSender: true)
                work.allDone {
                    expectation.fulfill()
                }
            }
        }
    }

    func testGetConvo() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (convo, _, _) in
            DBConvo.getConvo(withKey: convo.key, belongingTo: DBTest.uid) { (retrievedConvo) in
                XCTAssertEqual(retrievedConvo, convo)
                expectation.fulfill()
            }
        }
    }

    func testGetConvosForProxy() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (convo, sender, _) in
            DBConvo.getConvos(forProxy: sender, filtered: false) { (convos) in
                XCTAssertEqual(convos?.count, 1)
                XCTAssertEqual(convos?[0], convo)
                expectation.fulfill()
            }
        }
    }

    func testGetConvosForUser() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (convo, _, _) in
            DBConvo.getConvos(forUser: DBTest.uid, filtered: false) { (convos) in
                XCTAssertEqual(convos?.count, 1)
                XCTAssertEqual(convos?[0], convo)
                expectation.fulfill()
            }
        }
    }

    func testGetUnreadMessages() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (senderConvo, sender, receiver) in
            DBMessage.sendMessage(senderProxy: receiver, receiverProxy: sender, text: "") { (result) in
                switch result {
                case .failure:
                    XCTFail()
                case .success(let tuple):
                    DBConvo.getUnreadMessages(for: tuple.convo) { (messages) in
                        guard let messages = messages else {
                            XCTFail()
                            return
                        }
                        XCTAssertEqual(messages[safe: 0], tuple.message)
                        expectation.fulfill()
                    }
                }
            }
        }
    }

    func testLeaveConvo() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (convo, sender, _) in
            DBConvo.leaveConvo(convo) { (success) in
                XCTAssert(success)
                let work = GroupWork()
                work.check(.convoCount(0), forProxy: sender)
                work.check(.hasUnreadMessage(false), forProxy: sender)
                work.check(.receiverLeftConvo(true), forConvo: convo, asSender: false)
                work.check(.senderLeftConvo(true), forConvo: convo, asSender: true)
                work.checkUnreadMessagesDeleted(for: convo)
                work.allDone {
                    expectation.fulfill()
                }
            }
        }
    }

    func testLeaveConvoWithOtherMessages() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeProxy { (sender) in
            DBTest.makeProxy(forUser: DBTest.testUser) { (receiver1) in
                DBTest.makeProxy(forUser: DBTest.testUser) { (receiver2) in
                    DBMessage.sendMessage(senderProxy: receiver1, receiverProxy: sender, text: DBTest.text) { (result) in
                        XCTAssertNotNil(result)
                        DBMessage.sendMessage(senderProxy: receiver2, receiverProxy: sender, text: DBTest.text) { (result) in
                            switch result {
                            case .failure:
                                XCTFail()
                            case .success(let tuple):
                                DBConvo.leaveConvo(tuple.convo) { (success) in
                                    XCTAssert(success)
                                    let work = GroupWork()
                                    work.check(.hasUnreadMessage(true), forProxy: sender)
                                    work.allDone {
                                        expectation.fulfill()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func testMakeConvo() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (senderConvo, sender, receiver) in
            let convoKey = DBConvo.makeConvoKey(senderProxy: sender, receiverProxy: receiver)
            XCTAssertEqual(senderConvo.receiverIcon, receiver.icon)
            XCTAssertEqual(senderConvo.key, convoKey)
            XCTAssertEqual(senderConvo.receiverId, receiver.ownerId)
            XCTAssertEqual(senderConvo.receiverProxyKey, receiver.key)
            XCTAssertEqual(senderConvo.receiverProxyName, receiver.name)
            XCTAssertEqual(senderConvo.senderId, sender.ownerId)
            XCTAssertEqual(senderConvo.senderIsBlocked, false)
            XCTAssertEqual(senderConvo.senderProxyKey, sender.key)
            XCTAssertEqual(senderConvo.senderProxyName, sender.name)
            var receiverConvo = Convo()
            receiverConvo.receiverIcon = sender.icon
            receiverConvo.key = convoKey
            receiverConvo.receiverId = sender.ownerId
            receiverConvo.receiverIsBlocked = false
            receiverConvo.receiverProxyKey = sender.key
            receiverConvo.receiverProxyName = sender.name
            receiverConvo.senderId = receiver.ownerId
            receiverConvo.senderProxyKey = receiver.key
            receiverConvo.senderProxyName = receiver.name
            let work = GroupWork()
            work.check(.convoCount(1), forProxy: receiver)
            work.check(.convoCount(1), forProxy: sender)
            work.check(.proxiesInteractedWith, 1, forUser: receiver.ownerId)
            work.check(.proxiesInteractedWith, 1, forUser: sender.ownerId)
            work.checkConvoCreated(receiverConvo, asSender: true)
            work.checkConvoCreated(senderConvo, asSender: true)
            work.allDone {
                expectation.fulfill()
            }
        }
    }

    func testMakeConvo_WhileSenderIsBlocked() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DB.set(true, at: Child.userInfo, DBTest.testUser, Child.blockedUsers, DBTest.uid) { (success) in
            XCTAssert(success)
            DBTest.makeConvo { (convo, _, _) in
                let work = GroupWork()
                work.check(.receiverIsBlocked(true), forConvo: convo, asSender: false)
                work.check(.senderIsBlocked(true), forConvo: convo, asSender: true)
                work.allDone {
                    expectation.fulfill()
                }
            }
        }
    }

    func testMakeConvoKey() {
        var sender = Proxy()
        sender.key = "a"
        sender.ownerId = "b"
        var receiver = Proxy()
        receiver.key = "c"
        receiver.ownerId = "d"
        XCTAssertEqual(DBConvo.makeConvoKey(senderProxy: sender, receiverProxy: receiver), "abcd")
    }

    func testSenderLeftConvo() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (convo, _, _) in
            DBConvo.leaveConvo(convo) { (success) in
                XCTAssert(success)
                DBConvo.senderLeftConvo(convo) { (senderLeftConvo) in
                    XCTAssert(senderLeftConvo)
                    expectation.fulfill()
                }
            }
        }
    }

    func testSetReceiverNickname() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (convo, _, _) in
            let testNickname = "test nickname"
            DBConvo.setReceiverNickname(to: testNickname, forConvo: convo) { (error) in
                XCTAssertNil(error)
                let work = GroupWork()
                work.check(.receiverNickname(testNickname), forConvo: convo, asSender: true)
                work.allDone {
                    expectation.fulfill()
                }
            }
        }
    }

    func testToConvosArray() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (convo, _, _) in
            DB.get(Child.convos, convo.senderId) { (data) in
                let convos = data?.toConvosArray(filtered: false)
                XCTAssertEqual(convos?.count, 1)
                XCTAssertEqual(convos?[safe: 0], convo)
                expectation.fulfill()
            }
        }
    }

    func testSetPresentTrue() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (convo, _, _) in
            DBConvo.setPresent(present: true, uid: convo.senderId, convoKey: convo.key) { (success) in
                XCTAssert(success)
                DBConvo.userIsPresent(user: convo.senderId, inConvoWithKey: convo.key) { (userIsPresent) in
                    XCTAssert(userIsPresent)
                    expectation.fulfill()
                }
            }
        }
    }

    func testSetPresentFalse() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (convo, _, _) in
            DBConvo.setPresent(present: true, uid: convo.senderId, convoKey: convo.key) { (success) in
                XCTAssert(success)
                DBConvo.setPresent(present: false, uid: convo.senderId, convoKey: convo.key) { (success) in
                    XCTAssert(success)
                    DBConvo.userIsPresent(user: convo.senderId, inConvoWithKey: convo.key) { (userIsPresent) in
                        XCTAssertFalse(userIsPresent)
                        expectation.fulfill()
                    }
                }
            }
        }
    }

    func testUserIsPresent() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (convo, _, _) in
            DB.set(true, at: Child.userInfo, convo.senderId, Child.isPresent, convo.key) { (success) in
                XCTAssert(success)
                DBConvo.userIsPresent(user: DBTest.uid, inConvoWithKey: convo.key) { (isPresent) in
                    XCTAssert(isPresent)
                    expectation.fulfill()
                }
            }
        }
    }
}

extension GroupWork {
    func checkUnreadMessagesDeleted(for convo: Convo) {
        start()
        DBConvo.getUnreadMessages(for: convo) { (messages) in
            XCTAssertEqual(messages?.count, 0)
            self.finish(withResult: true)
        }
    }

    func checkConvoDeleted(_ convo: Convo, asSender: Bool) {
        let (ownerId, proxyKey) = GroupWork.getOwnerIdAndProxyKey(fromConvo: convo, asSender: asSender)
        checkDeleted(at: Child.convos, ownerId, convo.key)
        checkDeleted(at: Child.convos, proxyKey, convo.key)
    }

    func checkConvoCreated(_ convo: Convo, asSender: Bool) {
        let (ownerId, proxyKey) = GroupWork.getOwnerIdAndProxyKey(fromConvo: convo, asSender: asSender)

        start()
        DB.get(Child.convos, ownerId, convo.key) { (data) in
            XCTAssertEqual(Convo(data?.value as AnyObject), convo)
            self.finish(withResult: true)
        }

        start()
        DB.get(Child.convos, proxyKey, convo.key) { (data) in
            XCTAssertEqual(Convo(data?.value as AnyObject), convo)
            self.finish(withResult: true)
        }
    }
}
