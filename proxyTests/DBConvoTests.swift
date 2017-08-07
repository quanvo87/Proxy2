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

                let workKey = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
                workKey.checkConvoCount(forSenderProxyOfConvo: convo, equals: 0)
                workKey.checkProxyConvoDeleted(convo)
                workKey.checkUserConvoDeleted(convo)
                workKey.notify {
                    workKey.finishWorkGroup()
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

        DBTest.makeConvo { (convo, _, _) in
            var convo = convo
            DB.set([DB.Transaction(set: false, at: Path.Convos, convo.senderId, convo.key, Path.SenderLeftConvo),
                    DB.Transaction(set: false, at: Path.Convos, convo.senderProxyKey, convo.key, Path.SenderLeftConvo),
                    DB.Transaction(set: false, at: Path.Convos, convo.receiverId, convo.key, Path.ReceiverLeftConvo),
                    DB.Transaction(set: false, at: Path.Convos, convo.receiverProxyKey, convo.key, Path.ReceiverLeftConvo)]) { (success) in
                        XCTAssert(success)

                        convo.unread = 1

                        DBConvo.leaveConvo(convo) { (success) in
                            XCTAssert(success)

                            let workKey = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
                            workKey.checkConvoCount(forSenderProxyOfConvo: convo, equals: 0)
                            workKey.checkReceiverLeftConvo(forReceiverProxyConvoOfConvo: convo)
                            workKey.checkReceiverLeftConvo(forReceiverUserConvoOfConvo: convo)
                            workKey.checkSenderLeftConvo(forSenderProxyConvoOfConvo: convo)
                            workKey.checkSenderLeftConvo(forSenderUserConvoOfConvo: convo)
                            workKey.checkUnread(forSenderOfConvo: convo)
                            workKey.checkUnread(forSenderProxyOfConvo: convo)
                            workKey.notify {
                                workKey.finishWorkGroup()
                                self.x.fulfill()
                            }
                        }
            }
        }
    }

    func testMakeConvo() {
        x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (convo, sender, receiver) in
            let convoKey = DBConvo.makeConvoKey(senderProxy: sender, receiverProxy: receiver)

            XCTAssertEqual(convo.icon, receiver.icon)
            XCTAssertEqual(convo.key, convoKey)
            XCTAssertEqual(convo.receiverId, receiver.ownerId)
            XCTAssertEqual(convo.receiverProxyKey, receiver.key)
            XCTAssertEqual(convo.receiverProxyName, receiver.name)
            XCTAssertEqual(convo.senderId, sender.ownerId)
            XCTAssertEqual(convo.senderIsBlocked, false)
            XCTAssertEqual(convo.senderProxyKey, sender.key)
            XCTAssertEqual(convo.senderProxyName, sender.name)

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

            let workKey = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
            workKey.checkConvoCount(forSenderProxyOfConvo: convo, equals: 1)
            workKey.checkConvoCount(forSenderProxyOfConvo: receiverConvo, equals: 1)
            workKey.checkProxyConvoCreated(convo)
            workKey.checkProxyConvoCreated(receiverConvo)
            workKey.checkUserConvoCreated(convo)
            workKey.checkUserConvoCreated(receiverConvo)
            workKey.notify {
                workKey.finishWorkGroup()
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
                let workKey = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
                workKey.checkReceiverIsBlocked(forReceiverProxyConvoOfConvo: convo)
                workKey.checkReceiverIsBlocked(forReceiverUserConvoOfConvo: convo)
                workKey.checkSenderIsBlocked(forSenderProxyConvoOfConvo: convo)
                workKey.checkSenderIsBlocked(forSenderUserConvoOfConvo: convo)
                workKey.notify {
                    workKey.finishWorkGroup()
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

            DBConvo.setNickname(testNickname, forReceiverInConvo: convo) { (success) in
                XCTAssert(success)

                let workKey = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
                workKey.checkReceiverNickname(forProxyConvo: convo, equals: testNickname)
                workKey.checkReceiverNickname(forUserConvo: convo, equals: testNickname)
                workKey.notify {
                    workKey.finishWorkGroup()
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
    func checkConvoCount(forSenderProxyOfConvo convo: Convo, equals convoCount: Int) {
        startWork()
        DB.get(Path.Proxies, convo.senderId, convo.senderProxyKey, Path.Convos) { (data) in
            XCTAssertEqual(data?.value as? Int, convoCount)
            self.finishWork(withResult: true)
        }
    }

    func checkReceiverNickname(forProxyConvo convo: Convo, equals nickname: String) {
        startWork()
        DB.get(Path.Convos, convo.senderProxyKey, convo.key, Path.ReceiverNickname) { (data) in
            XCTAssertEqual(data?.value as? String, nickname)
            self.finishWork(withResult: true)
        }
    }

    func checkReceiverNickname(forUserConvo convo: Convo, equals nickname: String) {
        startWork()
        DB.get(Path.Convos, convo.senderId, convo.key, Path.ReceiverNickname) { (data) in
            XCTAssertEqual(data?.value as? String, nickname)
            self.finishWork(withResult: true)
        }
    }

    func checkProxyConvoCreated(_ convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.senderProxyKey, convo.key) { (data) in
            XCTAssertEqual(Convo(data?.value as AnyObject), convo)
            self.finishWork(withResult: true)
        }
    }

    func checkProxyConvoDeleted(_ convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.senderProxyKey, convo.key) { (data) in
            XCTAssertEqual(data?.value as? FirebaseDatabase.NSNull, FirebaseDatabase.NSNull())
            self.finishWork(withResult: true)
        }
    }

    func checkReceiverIsBlocked(forReceiverProxyConvoOfConvo convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.receiverProxyKey, convo.key, Path.ReceiverIsBlocked) { (data) in
            XCTAssert(data?.value as? Bool ?? false)
            self.finishWork(withResult: true)
        }
    }

    func checkReceiverIsBlocked(forReceiverUserConvoOfConvo convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.receiverId, convo.key, Path.ReceiverIsBlocked) { (data) in
            XCTAssert(data?.value as? Bool ?? false)
            self.finishWork(withResult: true)
        }
    }

    func checkReceiverLeftConvo(forReceiverProxyConvoOfConvo convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.receiverProxyKey, convo.key, Path.ReceiverLeftConvo) { (data) in
            XCTAssert(data?.value as? Bool ?? false)
            self.finishWork(withResult: true)
        }
    }

    func checkReceiverLeftConvo(forReceiverUserConvoOfConvo convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.receiverId, convo.key, Path.ReceiverLeftConvo) { (data) in
            XCTAssert(data?.value as? Bool ?? false)
            self.finishWork(withResult: true)
        }
    }

    func checkSenderIsBlocked(forSenderProxyConvoOfConvo convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.senderProxyKey, convo.key, Path.SenderIsBlocked) { (data) in
            XCTAssert(data?.value as? Bool ?? false)
            self.finishWork(withResult: true)
        }
    }

    func checkSenderIsBlocked(forSenderUserConvoOfConvo convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.senderId, convo.key, Path.SenderIsBlocked) { (data) in
            XCTAssert(data?.value as? Bool ?? false)
            self.finishWork(withResult: true)
        }
    }

    func checkSenderLeftConvo(forSenderProxyConvoOfConvo convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.senderProxyKey, convo.key, Path.SenderLeftConvo) { (data) in
            XCTAssert(data?.value as? Bool ?? false)
            self.finishWork(withResult: true)
        }
    }

    func checkSenderLeftConvo(forSenderUserConvoOfConvo convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.senderId, convo.key, Path.SenderLeftConvo) { (data) in
            XCTAssert(data?.value as? Bool ?? false)
            self.finishWork(withResult: true)
        }
    }

    func checkUnread(forSenderOfConvo convo: Convo) {
        startWork()
        DB.get(Path.UserInfo, convo.senderId, Path.Unread){ (data) in
            XCTAssertEqual(data?.value as? Int, -1)
            self.finishWork(withResult: true)
        }
    }

    func checkUnread(forSenderProxyOfConvo convo: Convo) {
        startWork()
        DB.get(Path.Proxies, convo.senderId, convo.senderProxyKey, Path.Unread) { (data) in
            XCTAssertEqual(data?.value as? Int, -1)
            self.finishWork(withResult: true)
        }
    }

    func checkUserConvoCreated(_ convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.senderId, convo.key) { (data) in
            XCTAssertEqual(Convo(data?.value as AnyObject), convo)
            self.finishWork(withResult: true)
        }
    }
    
    func checkUserConvoDeleted(_ convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.senderId, convo.key) { (data) in
            XCTAssertEqual(data?.value as? FirebaseDatabase.NSNull, FirebaseDatabase.NSNull())
            self.finishWork(withResult: true)
        }
    }
}
