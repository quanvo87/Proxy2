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

            let convoDataChecked = DispatchGroup()
            for _ in 1...6 {
                convoDataChecked.enter()
            }

            DB.get(Path.Convos, convo.senderId, convo.key) { (data) in
                XCTAssertEqual(Convo(data?.value as AnyObject), convo)
                convoDataChecked.leave()
            }

            DB.get(Path.Convos, convo.senderProxyKey, convo.key) { (data) in
                XCTAssertEqual(Convo(data?.value as AnyObject), convo)
                convoDataChecked.leave()
            }

            DB.get(Path.Proxies, convo.senderId, convo.senderProxyKey, Path.Convos) { (data) in
                XCTAssertEqual(data?.value as? Int, 1)
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

            DB.get(Path.Convos, receiverConvo.senderId, receiverConvo.key) { (data) in
                XCTAssertEqual(Convo(data?.value as AnyObject), receiverConvo)
                convoDataChecked.leave()
            }

            DB.get(Path.Convos, receiverConvo.senderProxyKey, receiverConvo.key) { (data) in
                XCTAssertEqual(Convo(data?.value as AnyObject), receiverConvo)
                convoDataChecked.leave()
            }

            DB.get(Path.Proxies, convo.receiverId, convo.receiverProxyKey, Path.Convos) { (data) in
                XCTAssertEqual(data?.value as? Int, 1)
                convoDataChecked.leave()
            }

            convoDataChecked.notify(queue: .main) {
                self.x.fulfill()
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

    func testSetNickname() {
        x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (convo, _, _) in
            let testNickname = "test nickname"

            DBConvo.setNickname(testNickname, forReceiverInConvo: convo) { (success) in
                XCTAssert(success)

                let nicknameChecked = DispatchGroup()
                for _ in 1...2 {
                    nicknameChecked.enter()
                }

                DB.get(Path.Convos, convo.senderId, convo.key, Path.ReceiverNickname) { (data) in
                    XCTAssertEqual(data?.value as? String, testNickname)
                    nicknameChecked.leave()
                }

                DB.get(Path.Convos, convo.senderProxyKey, convo.key, Path.ReceiverNickname) { (data) in
                    XCTAssertEqual(data?.value as? String, testNickname)
                    nicknameChecked.leave()
                }

                nicknameChecked.notify(queue: .main) {
                    self.x.fulfill()
                }
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

                            let checkLeaveConvoData = DispatchGroup()
                            for _ in 1...7 {
                                checkLeaveConvoData.enter()
                            }

                            DB.get(Path.Convos, convo.senderId, convo.key, Path.SenderLeftConvo) { (data) in
                                XCTAssertEqual(data?.value as? Bool, true)
                                checkLeaveConvoData.leave()
                            }

                            DB.get(Path.Convos, convo.senderProxyKey, convo.key, Path.SenderLeftConvo) { (data) in
                                XCTAssertEqual(data?.value as? Bool, true)
                                checkLeaveConvoData.leave()
                            }

                            DB.get(Path.Convos, convo.receiverId, convo.key, Path.ReceiverLeftConvo) { (data) in
                                XCTAssertEqual(data?.value as? Bool, true)
                                checkLeaveConvoData.leave()
                            }

                            DB.get(Path.Convos, convo.receiverProxyKey, convo.key, Path.ReceiverLeftConvo) { (data) in
                                XCTAssertEqual(data?.value as? Bool, true)
                                checkLeaveConvoData.leave()
                            }

                            DB.get(Path.Proxies, convo.senderId, convo.senderProxyKey, Path.Convos) { (data) in
                                XCTAssertEqual(data?.value as? Int, 0)
                                checkLeaveConvoData.leave()
                            }

                            DB.get(Path.UserInfo, convo.senderId, Path.Unread){ (data) in
                                XCTAssertEqual(data?.value as? Int, -1)
                                checkLeaveConvoData.leave()
                            }

                            DB.get(Path.Proxies, convo.senderId, convo.senderProxyKey, Path.Unread) { (data) in
                                XCTAssertEqual(data?.value as? Int, -1)
                                checkLeaveConvoData.leave()
                            }

                            checkLeaveConvoData.notify(queue: .main) {
                                self.x.fulfill()
                            }
                        }
            }
        }
    }

    func testDeleteConvo() {
        x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (convo, _, _) in
            DBConvo.deleteConvo(convo) { (success) in
                XCTAssert(success)
                
                let convosDeleted = DispatchGroup()
                for _ in 1...3 {
                    convosDeleted.enter()
                }

                DB.get(Path.Convos, convo.senderId, convo.key) { (data) in
                    XCTAssertEqual(data?.value as? FirebaseDatabase.NSNull, FirebaseDatabase.NSNull())
                    convosDeleted.leave()
                }

                DB.get(Path.Convos, convo.senderProxyKey, convo.key) { (data) in
                    XCTAssertEqual(data?.value as? FirebaseDatabase.NSNull, FirebaseDatabase.NSNull())
                    convosDeleted.leave()
                }

                DB.get(Path.Proxies, convo.senderId, convo.senderProxyKey, Path.Convos) { (data) in
                    XCTAssertEqual(data?.value as? Int, 0)
                    convosDeleted.leave()
                }

                convosDeleted.notify(queue: .main) {
                    self.x.fulfill()
                }
            }
        }
    }

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
