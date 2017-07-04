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

class DBConvoTests: DBTest {}

extension DBConvoTests {
    func testGetConvoKey() {
        var sender = proxy("b")
        sender.key = "a"

        var receiver = proxy("d")
        receiver.key = "c"

        XCTAssertEqual(DBConvo.getConvoKey(senderProxy: sender,
                                           receiverProxy: receiver),
                       "abcd")
    }

    func testCreateConvo() {
        x = expectation(description: #function)

        let sender = proxy()
        let receiver = proxy("test")

        DBConvo.createConvo(sender: sender, receiver: receiver) { (senderConvo) in
            guard let senderConvo = senderConvo else {
                XCTFail()
                return
            }

            let convoKey = DBConvo.getConvoKey(senderProxy: sender,
                                               receiverProxy: receiver)

            XCTAssertEqual(senderConvo.key, convoKey)
            XCTAssertEqual(senderConvo.senderId, sender.ownerId)
            XCTAssertEqual(senderConvo.senderProxyKey, sender.key)
            XCTAssertEqual(senderConvo.senderProxyName, sender.name)
            XCTAssertEqual(senderConvo.receiverId, receiver.ownerId)
            XCTAssertEqual(senderConvo.receiverProxyKey, receiver.key)
            XCTAssertEqual(senderConvo.receiverProxyName, receiver.name)
            XCTAssertEqual(senderConvo.icon, receiver.icon)
            XCTAssertEqual(senderConvo.receiverIsBlocking, false)

            let convoDataChecked = DispatchGroup()

            for _ in 1...4 {
                convoDataChecked.enter()
            }

            DB.get(Path.Convos, senderConvo.senderId, senderConvo.key) { (snapshot) in
                XCTAssertEqual(Convo(snapshot?.value as AnyObject), senderConvo)
                convoDataChecked.leave()
            }

            DB.get(Path.Convos, senderConvo.senderProxyKey, senderConvo.key) { (snapshot) in
                XCTAssertEqual(Convo(snapshot?.value as AnyObject), senderConvo)
                convoDataChecked.leave()
            }

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

            DB.get(Path.Convos, receiverConvo.senderId, receiverConvo.key) { (snapshot) in
                XCTAssertEqual(Convo(snapshot?.value as AnyObject), receiverConvo)
                convoDataChecked.leave()
            }

            DB.get(Path.Convos, receiverConvo.senderProxyKey, receiverConvo.key) { (snapshot) in
                XCTAssertEqual(Convo(snapshot?.value as AnyObject), receiverConvo)
                convoDataChecked.leave()
            }

            convoDataChecked.notify(queue: .main) {
                self.x.fulfill()
            }
        }
        waitForExpectations(timeout: 10)
    }
}

extension DBConvoTests {
    func testGetConvo() {
        x = expectation(description: #function)

        let convo = self.convo()
        DB.set(convo.toJSON(), at: Path.Convos, Shared.shared.uid, convo.key) { (success) in
            XCTAssert(success)

            DBConvo.getConvo(withKey: convo.key, belongingTo: Shared.shared.uid) { (retrievedConvo) in
                XCTAssertEqual(retrievedConvo, convo)
                self.x.fulfill()
            }
        }
        waitForExpectations(timeout: 10)
    }

    func testGetConvosForProxy() {
        x = expectation(description: #function)

        DBProxy.createProxy { (result) in
            switch result {
            case .failure(_):
                XCTFail()
            case .success(let proxy):
                let convo1 = self.convo(senderProxyKey: proxy.key)
                let convo2 = self.convo(senderProxyKey: proxy.key)

                DB.set([DB.Transaction(set: convo1.toJSON(), at: Path.Convos, proxy.key, convo1.key),
                        DB.Transaction(set: convo2.toJSON(), at: Path.Convos, proxy.key, convo2.key)]) { (success) in
                            XCTAssert(success)

                            DBConvo.getConvos(forProxy: proxy, filtered: false) { (convos) in
                                XCTAssertEqual(convos?.count, 2)
                                XCTAssert(convos?.contains(convo1) ?? false)
                                XCTAssert(convos?.contains(convo2) ?? false)
                                self.x.fulfill()
                            }
                }
            }
        }
        waitForExpectations(timeout: 10)
    }

    func testGetConvosForUser() {
        x = expectation(description: #function)

        let convo1 = convo()
        let convo2 = convo()

        DB.set([DB.Transaction(set: convo1.toJSON(), at: Path.Convos, Shared.shared.uid, convo1.key),
                DB.Transaction(set: convo2.toJSON(), at: Path.Convos, Shared.shared.uid, convo2.key)]) { (success) in
                    XCTAssert(success)

                    DBConvo.getConvos(forUser: Shared.shared.uid, filtered: false) { (convos) in
                        XCTAssertEqual(convos?.count, 2)
                        XCTAssert(convos?.contains(convo1) ?? false)
                        XCTAssert(convos?.contains(convo2) ?? false)
                        self.x.fulfill()
                    }
        }
        waitForExpectations(timeout: 10)
    }
}

extension DBConvoTests {
    func testSetNickname() {
        x = expectation(description: #function)

        let sender = proxy()
        let receiver = proxy("test")

        DBConvo.createConvo(sender: sender, receiver: receiver) { (convo) in
            guard let convo = convo else {
                XCTFail()
                return
            }

            let testNickname = "test nickname"

            DBConvo.setNickname(testNickname, forReceiverInConvo: convo) { (success) in
                XCTAssert(success)

                let nicknameChecked = DispatchGroup()

                for _ in 1...2 {
                    nicknameChecked.enter()
                }

                DB.get(Path.Convos, convo.senderId, convo.key, Path.ReceiverNickname) { (snapshot) in
                    XCTAssertEqual(snapshot?.value as? String ?? "", "test nickname")
                    nicknameChecked.leave()
                }

                DB.get(Path.Convos, convo.senderProxyKey, convo.key, Path.ReceiverNickname) { (snapshot) in
                    XCTAssertEqual(snapshot?.value as? String ?? "", "test nickname")
                    nicknameChecked.leave()
                }

                nicknameChecked.notify(queue: .main) {
                    self.x.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 10)
    }

    func testLeaveConvo() {
        x = expectation(description: #function)

        DBProxy.createProxy { (result) in
            switch result {
            case .failure(_):
                XCTFail()

            case .success(let sender):
                DBProxy.createProxy { (result) in
                    switch result {
                    case .failure(_):
                        XCTFail()

                    case .success(let proxy):
                        var receiver = proxy
                        receiver.ownerId = "test"

                        DBConvo.createConvo(sender: sender, receiver: receiver) { (convo) in
                            guard var convo = convo else {
                                XCTFail()
                                return
                            }

                            DB.set([DB.Transaction(set: false, at: Path.Convos, convo.senderId, convo.key, Path.SenderLeftConvo),
                                    DB.Transaction(set: false, at: Path.Convos, convo.senderProxyKey, convo.key, Path.SenderLeftConvo),
                                    DB.Transaction(set: false, at: Path.Convos, convo.receiverId, convo.key, Path.ReceiverLeftConvo),
                                    DB.Transaction(set: false, at: Path.Convos, convo.receiverProxyKey, convo.key, Path.ReceiverLeftConvo)]) { (success) in
                                        XCTAssert(success)

                                        convo.unread = 1

                                        DBConvo.leaveConvo(convo) { (success) in
                                            XCTAssert(success)

                                            let checkLeaveConvoData = DispatchGroup()

                                            for _ in 1...7 {
                                                checkLeaveConvoData.enter()
                                            }

                                            DB.get(Path.Convos, convo.senderId, convo.key, Path.SenderLeftConvo) { (snapshot) in
                                                XCTAssertEqual(snapshot?.value as? Bool, true)
                                                checkLeaveConvoData.leave()
                                            }

                                            DB.get(Path.Convos, convo.senderProxyKey, convo.key, Path.SenderLeftConvo) { (snapshot) in
                                                XCTAssertEqual(snapshot?.value as? Bool, true)
                                                checkLeaveConvoData.leave()
                                            }

                                            DB.get(Path.Convos, convo.receiverId, convo.key, Path.ReceiverLeftConvo) { (snapshot) in
                                                XCTAssertEqual(snapshot?.value as? Bool, true)
                                                checkLeaveConvoData.leave()
                                            }

                                            DB.get(Path.Convos, convo.receiverProxyKey, convo.key, Path.ReceiverLeftConvo) { (snapshot) in
                                                XCTAssertEqual(snapshot?.value as? Bool, true)
                                                checkLeaveConvoData.leave()
                                            }

                                            DB.get(Path.Proxies, convo.senderId, convo.senderProxyKey, Path.Convos) { (snapshot) in
                                                XCTAssertEqual(snapshot?.value as? Int, -1)
                                                checkLeaveConvoData.leave()
                                            }

                                            DB.get(Path.UserInfo, convo.senderId, Path.Unread){ (snapshot) in
                                                XCTAssertEqual(snapshot?.value as? Int, -1)
                                                checkLeaveConvoData.leave()
                                            }

                                            DB.get(Path.Proxies, convo.senderId, convo.senderProxyKey, Path.Unread) { (snapshot) in
                                                XCTAssertEqual(snapshot?.value as? Int, -1)
                                                checkLeaveConvoData.leave()
                                            }

                                            checkLeaveConvoData.notify(queue: .main) {
                                                self.x.fulfill()
                                            }
                                        }
                            }
                        }
                    }
                }
            }
        }
        waitForExpectations(timeout: 10)
    }

    func testDeleteConvo() {
        x = expectation(description: #function)

        let sender = proxy()
        let receiver = proxy("test")

        DBConvo.createConvo(sender: sender, receiver: receiver) { (convo) in
            guard let convo = convo else {
                XCTFail()
                return
            }

            DBConvo.deleteConvo(convo) { (success) in
                XCTAssert(success)

                let convosDeleted = DispatchGroup()

                for _ in 1...4 {
                    convosDeleted.enter()
                }

                DB.get(Path.Convos, convo.senderId, convo.key) { (snapshot) in
                    XCTAssertEqual(snapshot?.value as? FirebaseDatabase.NSNull, FirebaseDatabase.NSNull())
                    convosDeleted.leave()
                }

                DB.get(Path.Convos, convo.senderProxyKey, convo.key) { (snapshot) in
                    XCTAssertEqual(snapshot?.value as? FirebaseDatabase.NSNull, FirebaseDatabase.NSNull())
                    convosDeleted.leave()
                }

                DB.get(Path.Convos, convo.receiverId, convo.key) { (snapshot) in
                    XCTAssertEqual(snapshot?.value as? FirebaseDatabase.NSNull, FirebaseDatabase.NSNull())
                    convosDeleted.leave()
                }

                DB.get(Path.Convos, convo.receiverProxyKey, convo.key) { (snapshot) in
                    XCTAssertEqual(snapshot?.value as? FirebaseDatabase.NSNull, FirebaseDatabase.NSNull())
                    convosDeleted.leave()
                }

                convosDeleted.notify(queue: .main) {
                    self.x.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 10)
    }
}

extension DBConvoTests {
    func testMakeConvoTitle() {
        XCTAssertEqual(DBConvo.makeConvoTitle(receiverNickname: "a", receiverName: "b", senderNickname: "c", senderName: "d").string, "a, c")
        XCTAssertEqual(DBConvo.makeConvoTitle(receiverNickname: "", receiverName: "a", senderNickname: "", senderName: "b").string, "a, b")
    }
}

extension DBConvoTests {
    func testUserIsPresent() {
        x = expectation(description: #function)

        let convo = self.convo(key: "test")
        DB.set(true, at: Path.Present, convo.key, Shared.shared.uid, Path.Present) { (success) in
            XCTAssert(success)

            DBConvo.userIsPresent(uid: Shared.shared.uid, inConvoWithKey: convo.key) { (isPresent) in
                XCTAssert(isPresent)
                self.x.fulfill()
            }
        }

        waitForExpectations(timeout: 10)
    }
}

extension DBConvoTests {
    func testGetConvosFromSnapshot() throws {
        let x = expectation(description: #function)

        var convo1 = convo()
        convo1.senderLeftConvo = false
        convo1.senderIsBlocking = false

        var convo2 = convo()
        convo2.senderLeftConvo = true
        convo2.senderIsBlocking = true

        DB.set([DB.Transaction(set: convo1.toJSON(), at: "test", "a"),
                DB.Transaction(set: convo2.toJSON(), at: "test", "b")]) { (success) in
                    XCTAssert(success)

                    DB.get("test") { (snapshot) in
                        let convos = snapshot?.toConvos(filtered: true)
                        XCTAssertEqual(convos?.count, 1)
                        XCTAssertEqual(convos?[0], convo1)
                        x.fulfill()
                    }
        }
        waitForExpectations(timeout: 10)
    }
}
