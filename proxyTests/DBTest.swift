import FirebaseAuth
import FirebaseDatabase
import XCTest
@testable import proxy

class DBTest: XCTestCase {
    private let auth = Auth.auth(app: Shared.shared.firebase!)
    private weak var handle: AuthStateDidChangeListenerHandle?
    
    private let uid = "YXNArkJQPXcEUFIs87tKm1nEP1K3"
    private let email = "emydadu-3857@yopmail.com"
    private let password = "+7rVajX5sYNRL[kZ"
    
    static let testUser = "test user"
    static let text = "🤤"

    override func setUp() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }
        
        if Shared.shared.uid == uid {
            DBTest.clearData {
                expectation.fulfill()
            }
            
        } else {
            try! auth.signOut()
            
            handle = auth.addStateDidChangeListener { (auth, user) in
                if let uid = user?.uid {
                    Shared.shared.uid = uid
                    DBTest.clearDB {
                        expectation.fulfill()
                    }
                } else {
                    auth.signIn(withEmail: self.email, password: self.password) { (_, error) in
                        XCTAssertNil(error)
                    }
                }
            }
        }
    }
    
    override func tearDown() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.clearData {
            expectation.fulfill()
        }
    }

    private static func clearData(completion: @escaping () -> Void) {
        clearCache()
        clearWorkGroups()
        clearDB(completion: completion)
    }

    private static func clearCache() {
        Shared.shared.cache.removeAllObjects()
    }

    private static func clearWorkGroups() {
        XCTAssert(Shared.shared.asyncWorkGroups.isEmpty)
        Shared.shared.asyncWorkGroups.removeAll()
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
                DBConvo.makeConvo(senderProxy: senderProxy, receiverProxy: receiverProxy) { (convo) in
                    guard let convo = convo else {
                        XCTFail()
                        return
                    }
                    completion(convo, senderProxy, receiverProxy)
                }
            }
        }
    }

    static func makeProxy(withName name: String? = nil, forUser uid: String = Shared.shared.uid, completion: @escaping (Proxy) -> Void) {
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
                DBMessage.sendMessage(from: sender, to: receiver, withText: text) { (result) in
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

extension AsyncWorkGroupKey {
    static func checkEquals(_ data: DataSnapshot?, _ any: Any, function: String, line: Int) {
        let errorMessage = AsyncWorkGroupKey.makeErrorMessage(function: function, line: line)
        switch any {
        case let value as Bool:
            XCTAssertEqual(data?.value as? Bool, value, errorMessage)
        case let value as Double:
            XCTAssertEqual(data?.value as? Double, value, errorMessage)
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
    
    func checkDeleted(at first: String, _ rest: String...) {
        startWork()
        DB.get(first, rest) { (data) in
            XCTAssertFalse(data?.exists() ?? true)
            self.finishWork()
        }
    }
}

extension AsyncWorkGroupKey {
    func check(_ property: SettableConvoProperty, forConvo convo: Convo, asSender: Bool, function: String = #function, line: Int = #line) {
        let (ownerId, proxyKey) = AsyncWorkGroupKey.getOwnerIdAndProxyKey(fromConvo: convo, asSender: asSender)
        check(property, forConvoWithKey: convo.key, ownerId: ownerId, proxyKey: proxyKey, function: function, line: line)
    }

    func check(_ property: SettableConvoProperty, forConvoWithKey convoKey: String, ownerId: String, proxyKey: String, function: String = #function, line: Int = #line) {
        startWork()
        DB.get(Child.Convos, ownerId, convoKey, property.properties.name) { (data) in
            AsyncWorkGroupKey.checkEquals(data, property.properties.value, function: function, line: line)
            self.finishWork()
        }

        startWork()
        DB.get(Child.Convos, proxyKey, convoKey, property.properties.name) { (data) in
            AsyncWorkGroupKey.checkEquals(data, property.properties.value, function: function, line: line)
            self.finishWork()
        }
    }
}

extension AsyncWorkGroupKey {
    func check(_ property: SettableMessageProperty, forMessage message: Message, function: String = #function, line: Int = #line) {
        startWork()
        DB.get(Child.Messages, message.parentConvo, message.key, property.properties.name) { (data) in
            AsyncWorkGroupKey.checkEquals(data, property.properties.value, function: function, line: line)
            self.finishWork()
        }
    }
}

extension AsyncWorkGroupKey {
    func check(_ property: SettableProxyProperty, forProxy proxy: Proxy, function: String = #function, line: Int = #line) {
        check(property, forProxyWithKey: proxy.key, ownerId: proxy.ownerId, function: function, line: line)
    }

    func check(_ property: SettableProxyProperty, forProxyInConvo convo: Convo , asSender: Bool, function: String = #function, line: Int = #line) {
        let (ownerId, proxyKey) = AsyncWorkGroupKey.getOwnerIdAndProxyKey(fromConvo: convo, asSender: asSender)
        check(property, forProxyWithKey: proxyKey, ownerId: ownerId, function: function, line: line)
    }
    
    func check(_ property: SettableProxyProperty, forProxyWithKey proxyKey: String, ownerId: String, function: String = #function, line: Int = #line) {
        startWork()
        DB.get(Child.Proxies, ownerId, proxyKey, property.properties.name) { (data) in
            AsyncWorkGroupKey.checkEquals(data, property.properties.value, function: function, line: line)
            self.finishWork()
        }
    }
}

extension AsyncWorkGroupKey {
    func check(_ property: IncrementableUserProperty, _ value: Int, forUser uid: String, function: String = #function, line: Int = #line) {
        startWork()
        DB.get(Child.UserInfo, uid, property.rawValue) { (data) in
            AsyncWorkGroupKey.checkEquals(data, value, function: function, line: line)
            self.finishWork()
        }
    }
}
