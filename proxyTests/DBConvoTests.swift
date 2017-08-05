//
//  DBConvo.swift
//  proxy
//
//  Created by Quan Vo on 6/15/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

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
                            workKey.checkReceiverLeftConvo(inReceiverProxyConvoOfConvo: convo)
                            workKey.checkReceiverLeftConvo(inReceiverUserConvoOfConvo: convo)
                            workKey.checkSenderLeftConvo(inSenderProxyConvoOfConvo: convo)
                            workKey.checkSenderLeftConvo(inSenderUserConvoOfConvo: convo)
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
            XCTAssertEqual(convo.receiverIsBlocking, false)
            XCTAssertEqual(convo.receiverProxyKey, receiver.key)
            XCTAssertEqual(convo.receiverProxyName, receiver.name)
            XCTAssertEqual(convo.senderId, sender.ownerId)
            XCTAssertEqual(convo.senderProxyKey, sender.key)
            XCTAssertEqual(convo.senderProxyName, sender.name)

            var receiverConvo = Convo()
            receiverConvo.icon = sender.icon
            receiverConvo.key = convoKey
            receiverConvo.receiverId = sender.ownerId
            receiverConvo.receiverProxyKey = sender.key
            receiverConvo.receiverProxyName = sender.name
            receiverConvo.senderId = receiver.ownerId
            receiverConvo.senderIsBlocking = false
            receiverConvo.senderProxyKey = receiver.key
            receiverConvo.senderProxyName = receiver.name

            let workKey = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
            workKey.checkProxyConvoCreated(convo)
            workKey.checkProxyConvoCreated(receiverConvo)
            workKey.checkConvoCount(forSenderProxyOfConvo: convo, equals: 1)
            workKey.checkConvoCount(forSenderProxyOfConvo: receiverConvo, equals: 1)
            workKey.checkUserConvoCreated(convo)
            workKey.checkUserConvoCreated(receiverConvo)
            workKey.notify {
                workKey.finishWorkGroup()
                self.x.fulfill()
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
                workKey.checkReceiverNickname(inProxyConvo: convo, equals: testNickname)
                workKey.checkReceiverNickname(inUserConvo: convo, equals: testNickname)
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

    func checkReceiverNickname(inProxyConvo convo: Convo, equals nickname: String) {
        startWork()
        DB.get(Path.Convos, convo.senderProxyKey, convo.key, Path.ReceiverNickname) { (data) in
            XCTAssertEqual(data?.value as? String, nickname)
            self.finishWork(withResult: true)
        }
    }

    func checkReceiverNickname(inUserConvo convo: Convo, equals nickname: String) {
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

    func checkReceiverLeftConvo(inReceiverProxyConvoOfConvo convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.receiverProxyKey, convo.key, Path.ReceiverLeftConvo) { (data) in
            XCTAssertEqual(data?.value as? Bool, true)
            self.finishWork(withResult: true)
        }
    }

    func checkReceiverLeftConvo(inReceiverUserConvoOfConvo convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.receiverId, convo.key, Path.ReceiverLeftConvo) { (data) in
            XCTAssertEqual(data?.value as? Bool, true)
            self.finishWork(withResult: true)
        }
    }

    func checkSenderLeftConvo(inSenderProxyConvoOfConvo convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.senderProxyKey, convo.key, Path.SenderLeftConvo) { (data) in
            XCTAssertEqual(data?.value as? Bool, true)
            self.finishWork(withResult: true)
        }
    }

    func checkSenderLeftConvo(inSenderUserConvoOfConvo convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.senderId, convo.key, Path.SenderLeftConvo) { (data) in
            XCTAssertEqual(data?.value as? Bool, true)
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
