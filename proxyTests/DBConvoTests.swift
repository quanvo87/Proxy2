import FirebaseDatabase
import XCTest
@testable import proxy

class DBConvoTests: DBTest {
    func testDeleteConvo() {
        x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (convo, _, _) in
            DBConvo.deleteConvo(convo) { (success) in
                XCTAssert(success)

                let key = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
                key.check(.convos(0), forProxyInConvo: convo, asSender: true)
                key.checkConvoDeleted(convo, asSender: true)
                key.notify {
                    key.finishWorkGroup()
                    self.x.fulfill()
                }
            }
        }
    }

    func testGetConvo() {
        x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (convo, _, _) in
            DBConvo.getConvo(withKey: convo.key, belongingTo: Shared.shared.uid) { (retrievedConvo) in
                XCTAssertEqual(retrievedConvo, convo)
                self.x.fulfill()
            }
        }
    }

    func testGetConvosForProxy() {
        x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (convo, sender, _) in
            DBConvo.getConvos(forProxy: sender, filtered: false) { (convos) in
                XCTAssertEqual(convos?.count, 1)
                XCTAssertEqual(convos?[0], convo)
                self.x.fulfill()
            }
        }
    }

    func testGetConvosForUser() {
        x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (convo, _, _) in
            DBConvo.getConvos(forUser: Shared.shared.uid, filtered: false) { (convos) in
                XCTAssertEqual(convos?.count, 1)
                XCTAssertEqual(convos?[0], convo)
                self.x.fulfill()
            }
        }
    }

    func testGetConvosFromSnapshot() {
        let x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (convo, _, _) in
            DB.get(Path.Convos, convo.senderId) { (data) in
                let convos = data?.toConvos(filtered: false)
                XCTAssertEqual(convos?.count, 1)
                XCTAssertEqual(convos?[0], convo)
                x.fulfill()
            }
        }
    }

    func testLeaveConvo() {
        x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (convo, sender, _) in
            var convo = convo
            convo.unread = 2

            DBConvo.leaveConvo(convo) { (success) in
                XCTAssert(success)

                let key = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
                key.check(.receiverLeftConvo(true), forConvo: convo, asSender: false)
                key.check(.senderLeftConvo(true), forConvo: convo, asSender: true)
                key.check(.convos(0), forProxy: sender)
                key.check(.unread(-convo.unread), forProxy: sender)
                key.check(.unread, equals: -convo.unread, forUser: convo.senderId)
                key.notify {
                    key.finishWorkGroup()
                    self.x.fulfill()
                }
            }
        }
    }

    func testMakeConvo() {
        x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (senderConvo, sender, receiver) in
            let convoKey = DBConvo.makeConvoKey(senderProxy: sender, receiverProxy: receiver)

            XCTAssertEqual(senderConvo.icon, receiver.icon)
            XCTAssertEqual(senderConvo.key, convoKey)
            XCTAssertEqual(senderConvo.receiverId, receiver.ownerId)
            XCTAssertEqual(senderConvo.receiverProxyKey, receiver.key)
            XCTAssertEqual(senderConvo.receiverProxyName, receiver.name)
            XCTAssertEqual(senderConvo.senderId, sender.ownerId)
            XCTAssertEqual(senderConvo.senderIsBlocked, false)
            XCTAssertEqual(senderConvo.senderProxyKey, sender.key)
            XCTAssertEqual(senderConvo.senderProxyName, sender.name)

            var receiverConvo = Convo()
            receiverConvo.icon = sender.icon
            receiverConvo.key = convoKey
            receiverConvo.receiverId = sender.ownerId
            receiverConvo.receiverIsBlocked = false
            receiverConvo.receiverProxyKey = sender.key
            receiverConvo.receiverProxyName = sender.name
            receiverConvo.senderId = receiver.ownerId
            receiverConvo.senderProxyKey = receiver.key
            receiverConvo.senderProxyName = receiver.name

            let key = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
            key.checkConvoCreated(receiverConvo, asSender: true)
            key.checkConvoCreated(senderConvo, asSender: true)
            key.check(.convos(1), forProxy: receiver)
            key.check(.convos(1), forProxy: sender)
            key.check(.proxiesInteractedWith, equals: 1, forUser: receiver.ownerId)
            key.check(.proxiesInteractedWith, equals: 1, forUser: sender.ownerId)
            key.notify {
                key.finishWorkGroup()
                self.x.fulfill()
            }
        }
    }

    func testMakeConvoWhileSenderIsBlocked() {
        x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DB.set(true, at: Path.UserInfo, DBTest.testUser, Path.Blocked, Shared.shared.uid) { (success) in
            XCTAssert(success)

            DBTest.makeConvo { (convo, _, _) in
                let key = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
                key.check(.receiverIsBlocked(true), forConvo: convo, asSender: false)
                key.check(.senderIsBlocked(true), forConvo: convo, asSender: true)
                key.notify {
                    key.finishWorkGroup()
                    self.x.fulfill()
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

    func testMakeConvoTitle() {
        XCTAssertEqual(DBConvo.makeConvoTitle(receiverNickname: "a", receiverName: "b", senderNickname: "c", senderName: "d").string, "a, c")
        XCTAssertEqual(DBConvo.makeConvoTitle(receiverNickname: "", receiverName: "a", senderNickname: "", senderName: "b").string, "a, b")
    }

    func testSetNickname() {
        x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (convo, _, _) in
            let testNickname = "test nickname"

            DBConvo.setReceiverNickname(to: testNickname, forConvo: convo) { (success) in
                XCTAssert(success)

                let key = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
                key.check(.receiverNickname(testNickname), forConvo: convo, asSender: true)
                key.notify {
                    key.finishWorkGroup()
                    self.x.fulfill()
                }
            }
        }
    }

    func testUserIsPresent() {
        x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (convo, _, _) in
            DB.set(true, at: Path.UserInfo, convo.senderId, Path.Present, convo.key, Path.Present) { (success) in
                XCTAssert(success)

                DBConvo.userIsPresent(user: Shared.shared.uid, inConvoWithKey: convo.key) { (isPresent) in
                    XCTAssert(isPresent)
                    self.x.fulfill()
                }
            }
        }
    }
}

extension AsyncWorkGroupKey {
    func checkConvoDeleted(_ convo: Convo, asSender: Bool) {
        let (ownerId, proxyKey) = AsyncWorkGroupKey.getOwnerIdAndProxyKey(fromConvo: convo, asSender: asSender)
        checkDeleted(at: Path.Convos, rest: ownerId, convo.key)
        checkDeleted(at: Path.Convos, rest: proxyKey, convo.key)
    }

    func checkConvoCreated(_ convo: Convo, asSender: Bool) {
        let (ownerId, proxyKey) = AsyncWorkGroupKey.getOwnerIdAndProxyKey(fromConvo: convo, asSender: asSender)

        startWork()
        DB.get(Path.Convos, ownerId, convo.key) { (data) in
            XCTAssertEqual(Convo(data?.value as AnyObject), convo)
            self.finishWork()
        }

        startWork()
        DB.get(Path.Convos, proxyKey, convo.key) { (data) in
            XCTAssertEqual(Convo(data?.value as AnyObject), convo)
            self.finishWork()
        }
    }
}
