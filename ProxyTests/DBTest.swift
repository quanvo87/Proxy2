import Firebase
import FirebaseAuth
import FirebaseDatabase
import GroupWork
import XCTest
@testable import Proxy

class DBTest: XCTestCase {
    private let auth = Auth.auth(app: FirebaseApp.app!)
    private let email = "ahettisele-0083@yopmail.com"
    private let password = "BGbN92GY6_W+rR!Q"
    
    static let uid = "bKx62eEMy9gbynfbxvVsAr3nXQJ2"
    static let testUser = "test user"
    static let text = "🤤"

    override func setUp() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        if auth.currentUser?.uid == DBTest.uid {
            DBTest.clearDB {
                expectation.fulfill()
            }
        } else {
            auth.addStateDidChangeListener { (auth, user) in
                if user?.uid == DBTest.uid {
                    DBTest.clearDB {
                        expectation.fulfill()
                    }
                } else {
                    do {
                        try auth.signOut()
                    }
                    catch {
                        XCTFail()
                        expectation.fulfill()
                    }
                    auth.signIn(withEmail: self.email, password: self.password) { (_, error) in
                        XCTAssertNil(error)
                    }
                }
            }
        }
    }

    private static func clearDB(completion: @escaping () -> Void) {
        Database.database().reference().removeValue { (error, _) in
            XCTAssertNil(error)
            completion()
        }
    }
}

extension DBTest {
    static func makeProxy(withName name: String = ProxyService.makeRandomProxyName(), forUser uid: String = DBTest.uid, completion: @escaping (Proxy) -> Void) {
        DB.makeProxy(uid: uid, name: name, currentProxyCount: 0) { (result) in
            switch result {
            case .failure:
                XCTFail()
            case .success(let proxy):
                completion(proxy)
            }
        }
    }

    static func sendMessage(completion: @escaping (_ message: Message, _ convo: Convo, _ sender: Proxy, _ receiver: Proxy) -> Void) {
        makeProxy { (sender) in
            makeProxy (forUser: testUser) { (receiver) in
                DB.sendMessage(sender: sender, receiver: receiver, text: text) { (result) in
                    switch result {
                    case .failure:
                        XCTFail()
                    case .success(let tuple):
                        DB.getConvo(uid: tuple.convo.senderId, key: tuple.convo.key) { (convo) in
                            guard let convo = convo else {
                                XCTFail()
                                return
                            }
                            completion(tuple.message, convo, sender, receiver)
                        }
                    }
                }
            }
        }
    }
}

extension GroupWork {
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

    static func makeErrorMessage(function: String, line: Int) -> String {
        return "Function: \(function), Line: \(line)."
    }
    
    func checkDeleted(_ first: String, _ rest: String..., function: String = #function, line: Int = #line) {
        start()
        DB.get(first, rest) { (data) in
            XCTAssertFalse(data!.exists(), GroupWork.makeErrorMessage(function: function, line: line))
            self.finish(withResult: true)
        }
    }
}

extension GroupWork {
    func check(_ property: SettableConvoProperty, for convo: Convo, asSender: Bool, function: String = #function, line: Int = #line) {
        let (ownerId, _) = GroupWork.getOwnerIdAndProxyKey(convo: convo, asSender: asSender)
        check(property, uid: ownerId, convoKey: convo.key, function: function, line: line)
    }

    func check(_ property: SettableConvoProperty, uid: String, convoKey: String, function: String = #function, line: Int = #line) {
        start()
        DB.get(Child.convos, uid, convoKey, property.properties.name) { (data) in
            GroupWork.checkEquals(data, property.properties.value, function: function, line: line)
            self.finish(withResult: true)
        }
    }
}

extension GroupWork {
    func check(_ property: SettableMessageProperty, for message: Message, function: String = #function, line: Int = #line) {
        start()
        DB.get(Child.messages, message.parentConvoKey, message.messageId, property.properties.name) { (data) in
            switch property {
            case .dateRead(let date):
                GroupWork.checkEquals(data, date.timeIntervalSince1970, function: function, line: line)
            }
            self.finish(withResult: true)
        }
    }
}

extension GroupWork {
    func check(_ property: SettableProxyProperty, for proxy: Proxy, function: String = #function, line: Int = #line) {
        check(property, uid: proxy.ownerId, proxyKey: proxy.key, function: function, line: line)
    }

    func check(_ property: SettableProxyProperty, forProxyIn convo: Convo , asSender: Bool, function: String = #function, line: Int = #line) {
        let (ownerId, proxyKey) = GroupWork.getOwnerIdAndProxyKey(convo: convo, asSender: asSender)
        check(property, uid: ownerId, proxyKey: proxyKey, function: function, line: line)
    }

    func check(_ property: SettableProxyProperty, uid: String, proxyKey: String, function: String = #function, line: Int = #line) {
        start()
        DB.get(Child.proxies, uid, proxyKey, property.properties.name) { (data) in
            GroupWork.checkEquals(data, property.properties.value, function: function, line: line)
            self.finish(withResult: true)
        }
    }
}

extension GroupWork {
    func check(_ property: IncrementableUserProperty, equals value: Int, uid: String, function: String = #function, line: Int = #line) {
        start()
        DB.get(Child.userInfo, uid, property.rawValue) { (data) in
            GroupWork.checkEquals(data, value, function: function, line: line)
            self.finish(withResult: true)
        }
    }
}
