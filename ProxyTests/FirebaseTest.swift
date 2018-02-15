import Firebase
import GroupWork
import XCTest
@testable import Proxy

class FirebaseTest: XCTestCase {
    static let database = Firebase()
    static let testUserId = "testUserId"
    static let text = "🤤"
    static let uid = "37Xoavv6znT6DrJjnx1I6hTQVr23"
    private static let email = "test@test.com"
    private static let password = "test123"
    private let auth = Auth.auth(app: Shared.firebaseApp!)
    private var handle: AuthStateDidChangeListenerHandle?

    override func setUp() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        if auth.currentUser?.uid == FirebaseTest.uid {
            FirebaseTest.clearDB {
                expectation.fulfill()
            }
        } else {
            handle = auth.addStateDidChangeListener { auth, user in
                if user?.uid == FirebaseTest.uid {
                    FirebaseTest.clearDB {
                        expectation.fulfill()
                    }
                } else {
                    do {
                        try auth.signOut()
                    } catch {
                        XCTFail(String(describing: error))
                        expectation.fulfill()
                    }
                    auth.signIn(withEmail: FirebaseTest.email, password: FirebaseTest.password) { user, _ in
                        if user?.uid != FirebaseTest.uid {
                            XCTFail()
                            expectation.fulfill()
                        }
                    }
                }
            }
        }
    }

    private static func clearDB(completion: @escaping () -> Void) {
        Database.database().reference().removeValue { error, _ in
            XCTAssertNil(error)
            completion()
        }
    }

    static func makeProxy(ownerId: String = FirebaseTest.uid, completion: @escaping (Proxy) -> Void) {
        database.makeProxy(currentProxyCount: 0, ownerId: ownerId) { result in
            switch result {
            case .failure:
                XCTFail()
            case .success(let proxy):
                completion(proxy)
            }
        }
    }

    static func sendMessage(completion: @escaping (_ message: Message, _ convo: Convo, _ sender: Proxy, _ receiver: Proxy) -> Void) {
        makeProxy { sender in
            makeProxy (ownerId: testUserId) { receiver in
                database.sendMessage(sender: sender, receiver: receiver, text: text) { result in
                    switch result {
                    case .failure:
                        XCTFail()
                    case .success(let tuple):
                        database.getConvo(convoKey: tuple.convo.key, ownerId: tuple.convo.senderId) { result in
                            switch result {
                            case .failure(let error):
                                XCTFail(String(describing: error))
                            case .success(let convo):
                                completion(tuple.message, convo, sender, receiver)
                            }
                        }
                    }
                }
            }
        }
    }

    deinit {
        if let handle = handle {
            auth.removeStateDidChangeListener(handle)
        }
    }
}

extension GroupWork {
    func check(_ property: SettableConvoProperty, for convo: Convo, asSender: Bool, function: String = #function, line: Int = #line) {
        let (uid, _) = GroupWork.getOwnerIdAndProxyKey(convo: convo, asSender: asSender)
        check(property, uid: uid, convoKey: convo.key, function: function, line: line)
    }

    func check(_ property: SettableConvoProperty, uid: String, convoKey: String, function: String = #function, line: Int = #line) {
        start()
        Shared.firebaseHelper.get(Child.convos, uid, convoKey, property.properties.name) { result in
            switch result {
            case .failure(let error):
                XCTFail(String(describing: error))
            case .success(let data):
                GroupWork.checkEquals(data, property.properties.value, function: function, line: line)
            }
            self.finish(withResult: true)
        }
    }

    func check(_ property: SettableMessageProperty, for message: Message, function: String = #function, line: Int = #line) {
        start()
        Shared.firebaseHelper.get(Child.messages, message.parentConvoKey, message.messageId, property.properties.name) { result in
            switch result {
            case .failure(let error):
                XCTFail(String(describing: error))
            case .success(let data):
                switch property {
                case .dateRead(let date):
                    GroupWork.checkEquals(data, date.timeIntervalSince1970, function: function, line: line)
                }
            }
            self.finish(withResult: true)
        }
    }

    func check(_ property: SettableProxyProperty, for proxy: Proxy, function: String = #function, line: Int = #line) {
        check(property, uid: proxy.ownerId, proxyKey: proxy.key, function: function, line: line)
    }

    func check(_ property: SettableProxyProperty, forProxyIn convo: Convo, asSender: Bool, function: String = #function, line: Int = #line) {
        let (uid, proxyKey) = GroupWork.getOwnerIdAndProxyKey(convo: convo, asSender: asSender)
        check(property, uid: uid, proxyKey: proxyKey, function: function, line: line)
    }

    func check(_ property: SettableProxyProperty, uid: String, proxyKey: String, function: String = #function, line: Int = #line) {
        start()
        Shared.firebaseHelper.get(Child.proxies, uid, proxyKey, property.properties.name) { result in
            switch result {
            case .failure(let error):
                XCTFail(String(describing: error))
            case .success(let data):
                GroupWork.checkEquals(data, property.properties.value, function: function, line: line)
            }
            self.finish(withResult: true)
        }
    }

    func check(_ property: IncrementableUserProperty, equals value: Int, uid: String, function: String = #function, line: Int = #line) {
        start()
        Shared.firebaseHelper.get(Child.userInfo, uid, property.rawValue) { result in
            switch result {
            case .failure(let error):
                XCTFail(String(describing: error))
            case .success(let data):
                GroupWork.checkEquals(data, value, function: function, line: line)
            }
            self.finish(withResult: true)
        }
    }

    static func checkEquals(_ data: DataSnapshot?, _ any: Any, function: String, line: Int) {
        let errorMessage = GroupWork.makeErrorMessage(function: function, line: line)
        switch any {
        case let value as Bool:
            XCTAssertEqual(data?.value as? Bool, value, errorMessage)
        case let value as Double:
            XCTAssertEqual((data?.value as? Double)?.rounded(), value.rounded(), errorMessage)
        case let value as Int:
            XCTAssertEqual(data?.value as? Int, value, errorMessage)
        case let value as String:
            XCTAssertEqual(data?.value as? String, value, errorMessage)
        default:
            XCTFail(errorMessage)
        }
    }

    func checkDeleted(_ first: String, _ rest: String..., function: String = #function, line: Int = #line) {
        start()
        Shared.firebaseHelper.get(first, rest) { result in
            switch result {
            case .failure(let error):
                XCTFail(String(describing: error))
            case .success(let data):
                XCTAssertFalse(data.exists(), GroupWork.makeErrorMessage(function: function, line: line))
            }
            self.finish(withResult: true)
        }
    }

    static func makeErrorMessage(function: String, line: Int) -> String {
        return "Function: \(function), Line: \(line)."
    }
}
