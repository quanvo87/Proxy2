//
//  DB.swift
//  proxy
//
//  Created by Quan Vo on 6/14/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import XCTest
@testable import proxy
import FirebaseAuth

class DBTest: XCTestCase {
    private let auth = Auth.auth(app: Shared.shared.firebase!)
    private var handle: AuthStateDidChangeListenerHandle?

    private let uid = "YXNArkJQPXcEUFIs87tKm1nEP1K3"
    private let email = "emydadu-3857@yopmail.com"
    private let password = "+7rVajX5sYNRL[kZ"

    var x = XCTestExpectation()

    let setupTestEnvDone = DispatchGroup()

    override func setUp() {
        x = expectation(description: #function)

        if Shared.shared.uid == uid {
            setupTestEnv()

        } else {
            do {
                try auth.signOut()
            } catch {
                XCTFail()
            }

            handle = auth.addStateDidChangeListener { [weak self] (auth, user) in
                guard let strong = self else {
                    return
                }

                if let uid = user?.uid {
                    Shared.shared.uid = uid
                    strong.loadProxyInfo()
                    strong.setupTestEnv()

                } else {
                    auth.signIn(withEmail: strong.email, password: strong.password) { (_, error) in
                        XCTAssertNil(error)
                    }
                }
            }
        }

        waitForExpectations(timeout: 10)
    }

    override func tearDown() {
        x = expectation(description: #function)
        setupTestEnv()
        waitForExpectations(timeout: 10)
    }

    deinit {
        if let handle = handle {
            auth.removeStateDidChangeListener(handle)
        }
    }
}

private extension DBTest {
    func loadProxyInfo() {
        setupTestEnvDone.enter()

        DBProxy.loadProxyInfo { (success) in
            XCTAssert(success)
            self.setupTestEnvDone.leave()
        }
    }

    func setupTestEnv() {
        deleteTestData()
        deleteProxiesInteractedWith(Shared.shared.uid)
        deleteProxiesInteractedWith("test")
        deleteMessagesSent(Shared.shared.uid)
        deleteMessagesSent("test")
        deleteMessagesReceived(Shared.shared.uid)
        deleteMessagesReceived("test")
        deleteProxies()
        deleteConvos()

        setupTestEnvDone.notify(queue: .main) {
            self.deleteUnread(Shared.shared.uid)
            self.deleteUnread("test")

            self.setupTestEnvDone.notify(queue: .main) {
                self.x.fulfill()
            }
        }
    }

    func deleteTestData() {
        setupTestEnvDone.enter()

        DB.delete("test") { (success) in
            XCTAssert(success)
            self.setupTestEnvDone.leave()
        }
    }

    func deleteUnread(_ uid: String) {
        setupTestEnvDone.enter()

        DB.delete(Path.UserInfo, Path.Unread, uid, Path.Unread) { (success) in
            XCTAssert(success)
            self.setupTestEnvDone.leave()
        }
    }

    func deleteProxiesInteractedWith(_ uid: String) {
        setupTestEnvDone.enter()

        DB.delete(Path.UserInfo, Path.ProxiesInteractedWith, uid, Path.ProxiesInteractedWith) { (success) in
            XCTAssert(success)
            self.setupTestEnvDone.leave()
        }
    }

    func deleteMessagesSent(_ uid: String) {
        setupTestEnvDone.enter()

        DB.delete(Path.UserInfo, Path.MessagesSent, uid, Path.MessagesSent) { (success) in
            XCTAssert(success)
            self.setupTestEnvDone.leave()
        }
    }

    func deleteMessagesReceived(_ uid: String) {
        setupTestEnvDone.enter()

        DB.delete(Path.UserInfo, Path.MessagesReceived, uid, Path.MessagesReceived) { (success) in
            XCTAssert(success)
            self.setupTestEnvDone.leave()
        }
    }

    func deleteProxies() {
        setupTestEnvDone.enter()

        DB.get(Path.Proxies, Shared.shared.uid) { (snapshot) in
            guard let proxies = snapshot?.toProxies() else {
                XCTFail()
                return
            }

            let deleteProxiesDone = DispatchGroup()

            for proxy in proxies {
                deleteProxiesDone.enter()

                DBProxy.deleteProxy(proxy) { (success) in
                    XCTAssert(success)
                    deleteProxiesDone.leave()
                }
            }

            deleteProxiesDone.notify(queue: .main) {
                self.setupTestEnvDone.leave()
            }
        }
    }

    func deleteConvos() {
        setupTestEnvDone.enter()

        DBConvo.getConvos(forUser: Shared.shared.uid, filtered: false) { (convos) in
            guard let convos = convos else {
                XCTFail()
                return
            }

            let deleteConvosDone = DispatchGroup()

            for convo in convos {
                deleteConvosDone.enter()

                DBConvo.deleteConvo(convo) { (success) in
                    XCTAssert(success)
                    deleteConvosDone.leave()
                }
            }

            deleteConvosDone.notify(queue: .main) {
                self.setupTestEnvDone.leave()
            }
        }
    }
}

extension DBTest {
    var proxy: Proxy {
        var proxy = Proxy()
        proxy.icon = UUID().uuidString
        proxy.key = UUID().uuidString
        proxy.message = UUID().uuidString
        proxy.name = UUID().uuidString
        proxy.nickname = UUID().uuidString
        proxy.ownerId = Shared.shared.uid
        return proxy
    }

    var convo: Convo {
        var convo = Convo()
        convo.icon = UUID().uuidString
        convo.key = UUID().uuidString
        convo.message = UUID().uuidString
        convo.receiverId = UUID().uuidString
        convo.receiverNickname = UUID().uuidString
        convo.receiverProxyKey = UUID().uuidString
        convo.receiverProxyName = UUID().uuidString
        convo.senderId = Shared.shared.uid
        convo.senderNickname = UUID().uuidString
        convo.senderProxyKey = UUID().uuidString
        convo.senderProxyName = UUID().uuidString
        return convo
    }
}
