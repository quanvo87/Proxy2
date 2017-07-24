//
//  DBConvo.swift
//  proxy
//
//  Created by Quan Vo on 6/15/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import XCTest
@testable import proxy
import FirebaseDatabase

class DBConvoTests: DBTest {
    func testGetConvoKey() {
        var sender = Proxy()
        sender.key = "a"
        sender.ownerId = "b"

        var receiver = Proxy()
        receiver.key = "c"
        receiver.ownerId = "d"

        XCTAssertEqual(DBConvo.getConvoKey(senderProxy: sender, receiverProxy: receiver), "abcd")
    }

    func testMakeConvo() {
        x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (convo, sender, receiver) in
            let convoKey = DBConvo.getConvoKey(senderProxy: sender, receiverProxy: receiver)

            XCTAssertEqual(convo.key, convoKey)
            XCTAssertEqual(convo.senderId, sender.ownerId)
            XCTAssertEqual(convo.senderProxyKey, sender.key)
            XCTAssertEqual(convo.senderProxyName, sender.name)
            XCTAssertEqual(convo.receiverId, receiver.ownerId)
            XCTAssertEqual(convo.receiverProxyKey, receiver.key)
            XCTAssertEqual(convo.receiverProxyName, receiver.name)
            XCTAssertEqual(convo.icon, receiver.icon)
            XCTAssertEqual(convo.receiverIsBlocking, false)

            var receiverConvo = Convo()
            receiverConvo.key = convoKey
            receiverConvo.senderId = receiver.ownerId
            receiverConvo.senderProxyKey = receiver.key
            receiverConvo.senderProxyName = receiver.name
            receiverConvo.receiverId = sender.ownerId
            receiverConvo.receiverProxyKey = sender.key
            receiverConvo.receiverProxyName = sender.name
            receiverConvo.icon = sender.icon
            receiverConvo.senderIsBlocking = false

            let workKey = WorkKey.makeWorkKey()
            workKey.checkUserConvo(convo)
            workKey.checkUserConvo(receiverConvo)
            workKey.checkProxyConvo(convo)
            workKey.checkProxyConvo(receiverConvo)
            workKey.checkProxyConvoCount(convo)
            workKey.checkProxyConvoCount(receiverConvo)
            workKey.notify {
                workKey.finishWorkGroup()
                self.x.fulfill()
            }
        }
    }
}

private extension WorkKey {
    func checkUserConvo(_ convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.senderId, convo.key) { (data) in
            XCTAssertEqual(Convo(data?.value as AnyObject), convo)
            self.finishWork(withResult: true)
        }
    }

    func checkProxyConvo(_ convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.senderProxyKey, convo.key) { (data) in
            XCTAssertEqual(Convo(data?.value as AnyObject), convo)
            self.finishWork(withResult: true)
        }
    }

    func checkProxyConvoCount(_ convo: Convo) {
        startWork()
        DB.get(Path.Proxies, convo.senderId, convo.senderProxyKey, Path.Convos) { (data) in
            XCTAssertEqual(data?.value as? Int, 1)
            self.finishWork(withResult: true)
        }
    }
}

extension DBConvoTests {
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
}

extension DBConvoTests {
    func testSetNickname() {
        x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (convo, _, _) in
            let testNickname = "test nickname"

            DBConvo.setNickname(testNickname, forReceiverInConvo: convo) { (success) in
                XCTAssert(success)

                let workKey = WorkKey.makeWorkKey()
                workKey.checkNicknameForReceiverInUserConvo(convo: convo, nickname: testNickname)
                workKey.checkNicknameForReceiverInProxyConvo(convo: convo, nickname: testNickname)
                workKey.notify {
                    workKey.finishWorkGroup()
                    self.x.fulfill()
                }
            }
        }
    }
}

private extension WorkKey {
    func checkNicknameForReceiverInUserConvo(convo: Convo, nickname: String) {
        startWork()
        DB.get(Path.Convos, convo.senderId, convo.key, Path.ReceiverNickname) { (data) in
            XCTAssertEqual(data?.value as? String, nickname)
            self.finishWork(withResult: true)
        }
    }

    func checkNicknameForReceiverInProxyConvo(convo: Convo, nickname: String) {
        startWork()
        DB.get(Path.Convos, convo.senderProxyKey, convo.key, Path.ReceiverNickname) { (data) in
            XCTAssertEqual(data?.value as? String, nickname)
            self.finishWork(withResult: true)
        }
    }
}

extension DBConvoTests {
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

                            let workKey = WorkKey.makeWorkKey()
                            workKey.checkSenderLeftConvoInUserConvo(convo)
                            workKey.checkSenderLeftConvoInProxyConvo(convo)
                            workKey.checkReceiverLeftConvoInReceiverUserConvo(convo)
                            workKey.checkReceiverLeftConvoInReceiverProxyConvo(convo)
                            workKey.checkConvoCountForProxy(convo: convo)
                            workKey.checkUnreadForUser(convo: convo)
                            workKey.checkUnreadForProxy(convo: convo)
                            workKey.notify {
                                workKey.finishWorkGroup()
                                self.x.fulfill()
                            }
                        }
            }
        }
    }
}

private extension WorkKey {
    func checkSenderLeftConvoInUserConvo(_ convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.senderId, convo.key, Path.SenderLeftConvo) { (data) in
            XCTAssertEqual(data?.value as? Bool, true)
            self.finishWork(withResult: true)
        }
    }

    func checkSenderLeftConvoInProxyConvo(_ convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.senderProxyKey, convo.key, Path.SenderLeftConvo) { (data) in
            XCTAssertEqual(data?.value as? Bool, true)
            self.finishWork(withResult: true)
        }
    }

    func checkReceiverLeftConvoInReceiverUserConvo(_ convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.receiverId, convo.key, Path.ReceiverLeftConvo) { (data) in
            XCTAssertEqual(data?.value as? Bool, true)
            self.finishWork(withResult: true)
        }
    }

    func checkReceiverLeftConvoInReceiverProxyConvo(_ convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.receiverProxyKey, convo.key, Path.ReceiverLeftConvo) { (data) in
            XCTAssertEqual(data?.value as? Bool, true)
            self.finishWork(withResult: true)
        }
    }

    func checkUnreadForUser(convo: Convo) {
        startWork()
        DB.get(Path.UserInfo, convo.senderId, Path.Unread){ (data) in
            XCTAssertEqual(data?.value as? Int, -1)
            self.finishWork(withResult: true)
        }
    }

    func checkUnreadForProxy(convo: Convo) {
        startWork()
        DB.get(Path.Proxies, convo.senderId, convo.senderProxyKey, Path.Unread) { (data) in
            XCTAssertEqual(data?.value as? Int, -1)
            self.finishWork(withResult: true)
        }
    }
}

extension DBConvoTests {
    func testDeleteConvo() {
        x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (convo, _, _) in
            DBConvo.deleteConvo(convo) { (success) in
                XCTAssert(success)
                
                let workKey = WorkKey.makeWorkKey()
                workKey.checkUserConvoDeleted(convo)
                workKey.checkProxyConvoDeleted(convo)
                workKey.checkConvoCountForProxy(convo: convo)
                workKey.notify {
                    workKey.finishWorkGroup()
                    self.x.fulfill()
                }
            }
        }
    }
}

extension WorkKey {
    func checkUserConvoDeleted(_ convo: Convo) {
        startWork()
        DB.get(Path.Convos, convo.senderId, convo.key) { (data) in
            XCTAssertEqual(data?.value as? FirebaseDatabase.NSNull, FirebaseDatabase.NSNull())
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
}

extension DBConvoTests {
    func testMakeConvoTitle() {
        XCTAssertEqual(DBConvo.makeConvoTitle(receiverNickname: "a", receiverName: "b", senderNickname: "c", senderName: "d").string, "a, c")
        XCTAssertEqual(DBConvo.makeConvoTitle(receiverNickname: "", receiverName: "a", senderNickname: "", senderName: "b").string, "a, b")
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

    func testGetConvosFromSnapshot() throws {
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
}

private extension WorkKey {
    func checkConvoCountForProxy(convo: Convo) {
        startWork()
        DB.get(Path.Proxies, convo.senderId, convo.senderProxyKey, Path.Convos) { (data) in
            XCTAssertEqual(data?.value as? Int, 0)
            self.finishWork(withResult: true)
        }
    }
}
