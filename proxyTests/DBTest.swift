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
    func setupTestEnv() {
        deleteTestData()
        deleteProxies(forUser: Shared.shared.uid)
        deleteProxies(forUser: testUser)
        deleteConvos(forUser: Shared.shared.uid)
        deleteConvos(forUser: testUser)

        deletePresent() // TODO: - move to `userInfo`

        setupTestEnvDone.notify(queue: .main) {
            self.deleteUserInfo(Shared.shared.uid)
            self.deleteUserInfo(testUser)

            self.setupTestEnvDone.notify(queue: .main) {
                self.x.fulfill()
            }
        }
    }

    func deletePresent() {
        setupTestEnvDone.enter()

        DB.delete(Path.Present, "test") { (success) in
            XCTAssert(success)
            self.setupTestEnvDone.leave()
        }
    }

    func deleteTestData() {
        setupTestEnvDone.enter()

        DB.delete(test) { (success) in
            XCTAssert(success)
            self.setupTestEnvDone.leave()
        }
    }

    func deleteProxies(forUser uid: String) {
        setupTestEnvDone.enter()

        DBProxy.getProxies(forUser: uid) { (proxies) in
            guard let proxies = proxies else {
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

    func deleteConvos(forUser uid: String) {
        setupTestEnvDone.enter()

        DBConvo.getConvos(forUser: uid, filtered: false) { (convos) in
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

    func deleteUserInfo(_ uid: String) {
        setupTestEnvDone.enter()

        DB.delete(Path.UserInfo, uid) { (success) in
            XCTAssert(success)
            self.setupTestEnvDone.leave()
        }
    }
}

extension DBTest {
    func proxy(ownerId: String) -> Proxy {
        var proxy = Proxy()
        proxy.icon = UUID().uuidString
        proxy.key = UUID().uuidString
        proxy.message = UUID().uuidString
        proxy.name = UUID().uuidString
        proxy.nickname = UUID().uuidString
        proxy.ownerId = ownerId
        return proxy
    }

    func setProxy(_ proxy: Proxy, completion: @escaping (Success) -> Void) {
        DB.set(proxy.toJSON(), at: Path.Proxies, proxy.ownerId, proxy.key) { (success) in
            completion(success)
        }
    }
}

extension DBTest {
    func convo(senderId: String,
               senderProxyKey: String) -> Convo {
        var convo = Convo()
        convo.icon = UUID().uuidString
        convo.key = UUID().uuidString
        convo.message = UUID().uuidString
        convo.receiverId = UUID().uuidString
        convo.receiverNickname = UUID().uuidString
        convo.receiverProxyKey = UUID().uuidString
        convo.receiverProxyName = UUID().uuidString
        convo.senderId = senderId
        convo.senderNickname = UUID().uuidString
        convo.senderProxyKey = senderProxyKey
        convo.senderProxyName = UUID().uuidString
        return convo
    }

    func setConvoForUser(_ convo: Convo, completion: @escaping (Success) -> Void) {
        DB.set(convo.toJSON(), at: Path.Convos, convo.senderId, convo.key) { (success) in
            completion(success)
        }
    }

    func setConvoForProxy(_ convo: Convo, completion: @escaping (Success) -> Void) {
        DB.set(convo.toJSON(), at: Path.Convos, convo.senderProxyKey, convo.key) { (success) in
            completion(success)
        }
    }
}

let test = "test"
let testUser = "test user"
let testProxyKey = "test proxy key"
