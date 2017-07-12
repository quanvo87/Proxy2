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
import FirebaseDatabase

class DBTest: XCTestCase {
    private let auth = Auth.auth(app: Shared.shared.firebase!)
    private var handle: AuthStateDidChangeListenerHandle?

    private let uid = "YXNArkJQPXcEUFIs87tKm1nEP1K3"
    private let email = "emydadu-3857@yopmail.com"
    private let password = "+7rVajX5sYNRL[kZ"

    static let test = "test"
    static let testUser = "test user"
    static let testProxyKey = "test proxy key"

    var x = XCTestExpectation()

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
        let workKey = WorkKey.makeWorkKey()
        workKey.deleteTestData()
        workKey.deleteProxies(forUser: Shared.shared.uid)
        workKey.deleteProxies(forUser: DBTest.testUser)
        workKey.deleteConvos(forUser: Shared.shared.uid)
        workKey.deleteConvos(forUser: DBTest.testUser)
        workKey.deletePresent() // TODO: - move to userInfo
        workKey.notify {
            workKey.deleteUserInfo(Shared.shared.uid)
            workKey.deleteUserInfo(DBTest.testUser)
            workKey.notify {
                workKey.finishWorkGroup()
                self.x.fulfill()
            }
        }
    }
}

extension WorkKey {
    func deleteTestData() {
        startWork()
        DB.delete(DBTest.test) { (success) in
            XCTAssert(success)
            self.finishWork(withResult: success)
        }
    }

    func deleteProxies(forUser uid: String) {
        startWork()
        DBProxy.getProxies(forUser: uid) { (proxies) in
            guard let proxies = proxies else {
                XCTFail()
                return
            }
            let deleteProxiesWorkKey = WorkKey.makeWorkKey()
            for proxy in proxies {
                deleteProxiesWorkKey.deleteProxy(proxy)
            }
            deleteProxiesWorkKey.notify {
                self.finishWork(withResult: deleteProxiesWorkKey.workResult)
                deleteProxiesWorkKey.finishWorkGroup()
            }
        }
    }

    private func deleteProxy(_ proxy: Proxy) {
        startWork()
        DBProxy.deleteProxy(proxy) { (success) in
            XCTAssert(success)
            self.finishWork(withResult: success)
        }
    }

    func deleteConvos(forUser uid: String) {
        startWork()
        DBConvo.getConvos(forUser: uid, filtered: false) { (convos) in
            guard let convos = convos else {
                XCTFail()
                return
            }
            let deleteConvosWorkKey = WorkKey.makeWorkKey()
            for convo in convos {
                deleteConvosWorkKey.deleteConvo(convo)
            }
            deleteConvosWorkKey.notify {
                self.finishWork(withResult: deleteConvosWorkKey.workResult)
                deleteConvosWorkKey.finishWorkGroup()
            }
        }
    }

    private func deleteConvo(_ convo: Convo) {
        startWork()
        DBConvo.deleteConvo(convo) { (success) in
            XCTAssert(success)
            self.finishWork(withResult: success)
        }
    }

    func deletePresent() {
        startWork()
        DB.delete(Path.Present, "test") { (success) in
            XCTAssert(success)
            self.finishWork(withResult: success)
        }
    }

    func deleteUserInfo(_ uid: String) {
        startWork()
        DB.delete(Path.UserInfo, uid) { (success) in
            XCTAssert(success)
            self.finishWork(withResult: success)
        }
    }
}

extension DBTest {
    func assertValue<T: Comparable>(at first: String, _ rest: String..., equals value: T,
                                    group: DispatchGroup,
                                    function: String = #function,
                                    line: Int = #line) {
        group.enter()
        DB.get(first, rest) { (data) in
            XCTAssertEqual(data?.value as? T, value,
                           "\(function): line \(line)")
            group.leave()
        }
    }

    func assertNull(at first: String, _ rest: String..., group: DispatchGroup,
                    function: String = #function,
                    line: Int = #line) {
        group.enter()
        DB.get(first, rest) { (data) in
            XCTAssertEqual(data?.value as? FirebaseDatabase.NSNull,
                           FirebaseDatabase.NSNull(),
                           "\(function): line \(line)")
            group.leave()
        }
    }
}

extension DBTest {
    static func proxy(ownerId: String) -> Proxy {
        var proxy = Proxy()
        proxy.icon = UUID().uuidString
        proxy.key = UUID().uuidString
        proxy.message = UUID().uuidString
        proxy.name = UUID().uuidString
        proxy.nickname = UUID().uuidString
        proxy.ownerId = ownerId
        return proxy
    }

    static func setProxy(_ proxy: Proxy, completion: @escaping (Success) -> Void) {
        DB.set(proxy.toJSON(), at: Path.Proxies, proxy.ownerId, proxy.key) { (success) in
            completion(success)
        }
    }
}

extension DBTest {
    static func convo(senderId: String,
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

    static func setConvoForUser(_ convo: Convo, completion: @escaping (Success) -> Void) {
        DB.set(convo.toJSON(), at: Path.Convos, convo.senderId, convo.key) { (success) in
            completion(success)
        }
    }

    static func setConvoForProxy(_ convo: Convo, completion: @escaping (Success) -> Void) {
        DB.set(convo.toJSON(), at: Path.Convos, convo.senderProxyKey, convo.key) { (success) in
            completion(success)
        }
    }
}
