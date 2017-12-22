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
    static func makeConvo(completion: @escaping (_ convo: Convo, _ sender: Proxy, _ receiver: Proxy) -> Void) {
        makeProxy { (senderProxy) in
            makeProxy(forUser: testUser) { (receiverProxy) in
                DBConvo.makeConvo(sender: senderProxy, receiver: receiverProxy) { (convo) in
                    guard let convo = convo else {
                        XCTFail()
                        return
                    }
                    completion(convo, senderProxy, receiverProxy)
                }
            }
        }
    }

    static func makeProxy(withName name: String? = nil, forUser uid: String = DBTest.uid, completion: @escaping (Proxy) -> Void) {
        DBProxy.makeProxy(withName: name, forUser: uid) { (result) in
            switch result {
            case .failure: XCTFail()
            case .success(let proxy):
                completion(proxy)
            }
        }
    }

    static func sendMessage(completion: @escaping (_ message: Message, _ convo: Convo, _ sender: Proxy, _ receiver: Proxy) -> Void) {
        makeProxy { (sender) in
            makeProxy (forUser: testUser) { (receiver) in
                DBMessage.sendMessage(senderProxy: sender, receiverProxy: receiver, text: text) { (result) in
                    guard let (message, convo) = result else {
                        XCTFail()
                        return
                    }
                    completion(message, convo, sender, receiver)
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
    
    func checkDeleted(at first: String, _ rest: String..., function: String = #function, line: Int = #line) {
        start()
        DB.get(first, rest) { (data) in
            XCTAssertFalse(data?.exists() ?? true, GroupWork.makeErrorMessage(function: function, line: line))
            self.finish(withResult: true)
        }
    }
}

extension GroupWork {
    func check(_ property: SettableConvoProperty, forConvo convo: Convo, asSender: Bool, function: String = #function, line: Int = #line) {
        let (ownerId, proxyKey) = GroupWork.getOwnerIdAndProxyKey(fromConvo: convo, asSender: asSender)
        check(property, forConvoWithKey: convo.key, ownerId: ownerId, proxyKey: proxyKey, function: function, line: line)
    }

    func check(_ property: SettableConvoProperty, forConvoWithKey convoKey: String, ownerId: String, proxyKey: String, function: String = #function, line: Int = #line) {
        start()
        DB.get(Child.convos, ownerId, convoKey, property.properties.name) { (data) in
            GroupWork.checkEquals(data, property.properties.value, function: function, line: line)
            self.finish(withResult: true)
        }

        start()
        DB.get(Child.convos, proxyKey, convoKey, property.properties.name) { (data) in
            GroupWork.checkEquals(data, property.properties.value, function: function, line: line)
            self.finish(withResult: true)
        }
    }
}

extension GroupWork {
    func check(_ property: SettableMessageProperty, forMessage message: Message, function: String = #function, line: Int = #line) {
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
    func check(_ property: SettableProxyProperty, forProxy proxy: Proxy, function: String = #function, line: Int = #line) {
        check(property, forProxyWithKey: proxy.key, ownerId: proxy.ownerId, function: function, line: line)
    }

    func check(_ property: SettableProxyProperty, forProxyInConvo convo: Convo , asSender: Bool, function: String = #function, line: Int = #line) {
        let (ownerId, proxyKey) = GroupWork.getOwnerIdAndProxyKey(fromConvo: convo, asSender: asSender)
        check(property, forProxyWithKey: proxyKey, ownerId: ownerId, function: function, line: line)
    }

    func check(_ property: SettableProxyProperty, forProxyWithKey proxyKey: String, ownerId: String, function: String = #function, line: Int = #line) {
        start()
        DB.get(Child.proxies, ownerId, proxyKey, property.properties.name) { (data) in
            GroupWork.checkEquals(data, property.properties.value, function: function, line: line)
            self.finish(withResult: true)
        }
    }
}

extension GroupWork {
    func check(_ property: IncrementableUserProperty, _ value: Int, forUser uid: String, function: String = #function, line: Int = #line) {
        start()
        DB.get(Child.userInfo, uid, property.rawValue) { (data) in
            GroupWork.checkEquals(data, value, function: function, line: line)
            self.finish(withResult: true)
        }
    }
}
