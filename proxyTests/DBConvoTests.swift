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

    func testCreateConvo() {
        x = expectation(description: #function)

        var sender = Proxy()
        var receiver = Proxy()

        DBProxy.createProxy { (result) in
            switch result {
            case .failure(_):
                XCTFail()
            case .success(let proxy):
                sender = proxy

                DBProxy.createProxy { (result) in
                    switch result {
                    case .failure(_):
                        XCTFail()
                    case .success(let proxy):
                        receiver = proxy

                        receiver.ownerId = "receiver"

                        let convoKey = DBConvo.getConvoKey(senderProxy: sender,
                                                           receiverProxy: receiver)

                        DBConvo.createConvo(sender: sender,
                                            receiver: receiver,
                                            convoKey: DBConvo.getConvoKey(senderProxy: sender,
                                                                          receiverProxy: receiver),
                                            text: "test") { (convo) in
                                                XCTAssertNotNil(convo)
                                                XCTAssertEqual(convo?.key, convoKey)
                                                XCTAssertEqual(convo?.senderId, sender.ownerId)
                                                XCTAssertEqual(convo?.senderProxyKey, sender.key)
                                                XCTAssertEqual(convo?.senderProxyName, sender.name)
                                                XCTAssertEqual(convo?.receiverId, receiver.ownerId)
                                                XCTAssertEqual(convo?.receiverProxyKey, receiver.key)
                                                XCTAssertEqual(convo?.receiverProxyName, receiver.name)
                                                XCTAssertEqual(convo?.icon, receiver.icon)
                                                XCTAssertEqual(convo?.receiverIsBlocking, false)

                                                let convosChecked = DispatchGroup()

                                                for _ in 1...2 {
                                                    convosChecked.enter()
                                                }

                                                DBConvo.getConvo(withKey: convoKey, uid: sender.ownerId, completion: { (senderConvo) in
                                                    XCTAssertEqual(senderConvo, convo)
                                                    convosChecked.leave()
                                                })

                                                DBConvo.getConvo(withKey: convoKey, uid: receiver.ownerId, completion: { (receiverConvo) in
                                                    XCTAssertNotNil(receiverConvo)
                                                    XCTAssertEqual(receiverConvo?.key, convoKey)
                                                    XCTAssertEqual(receiverConvo?.senderId, receiver.ownerId)
                                                    XCTAssertEqual(receiverConvo?.senderProxyKey, receiver.key)
                                                    XCTAssertEqual(receiverConvo?.senderProxyName, receiver.name)
                                                    XCTAssertEqual(receiverConvo?.receiverId, sender.ownerId)
                                                    XCTAssertEqual(receiverConvo?.receiverProxyKey, sender.key)
                                                    XCTAssertEqual(receiverConvo?.receiverProxyName, sender.name)
                                                    XCTAssertEqual(receiverConvo?.icon, sender.icon)
                                                    XCTAssertEqual(receiverConvo?.senderIsBlocking, false)
                                                    convosChecked.leave()
                                                })
                                                
                                                convosChecked.notify(queue: .main) {
                                                    self.x.fulfill()
                                                }
                        }
                    }
                }
            }
        }
        waitForExpectations(timeout: 10)
    }

    func testGetConvosFromSnapshot() throws {
        let x = expectation(description: #function)

        var convo1 = Convo()
        convo1.senderLeftConvo = false
        convo1.senderIsBlocking = false

        var convo2 = Convo()
        convo2.senderLeftConvo = true
        convo2.senderIsBlocking = true

        DB.set([(DB.path("test", "a"), convo1.toJSON()),
                (DB.path("test", "b"), convo2.toJSON())]) { (success) in
                    XCTAssert(success)

                    DB.get("test") { (snapshot) in
                        let convos = snapshot?.toConvos()
                        XCTAssertEqual(convos?.count, 1)
                        x.fulfill()
                    }
        }
        
        waitForExpectations(timeout: 10)
    }
}
