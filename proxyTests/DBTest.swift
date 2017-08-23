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

    var x = XCTestExpectation()

    override func setUp() {
        let x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        XCTAssert(Shared.shared.asyncWorkGroups.isEmpty)

        if Shared.shared.uid == uid {
            DBTest.clearDB {
                x.fulfill()
            }

        } else {
            try! auth.signOut()

            handle = auth.addStateDidChangeListener { (auth, user) in
                if let uid = user?.uid {
                    Shared.shared.uid = uid
                    DBTest.clearDB {
                        x.fulfill()
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
        let x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        XCTAssert(Shared.shared.asyncWorkGroups.isEmpty)
        DBTest.clearDB {
            x.fulfill()
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
}

extension AsyncWorkGroupKey {
    static func makeErrorMessage(function: String, line: Int) -> String {
        return "Function: \(function), Line: \(line)."
    }

    func checkDeleted(at first: String, rest: String...) {
        startWork()
        DB.get(first, rest) { (data) in
            XCTAssertEqual(data?.value as? FirebaseDatabase.NSNull, FirebaseDatabase.NSNull())
            self.finishWork()
        }
    }
}

extension AsyncWorkGroupKey {
    func check(_ property: SettableConvoProperty, forConvo convo: Convo, asSender: Bool, function: String = #function, line: Int = #line) {
        let (ownerId, proxyKey) = AsyncWorkGroupKey.getOwnerIdAndProxyKey(fromConvo: convo, asSender: asSender)
        let errorMessage = AsyncWorkGroupKey.makeErrorMessage(function: function, line: line)

        startWork()
        DB.get(Path.Convos, ownerId, convo.key, property.properties.name) { (data) in
            switch property.properties.value {
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
            self.finishWork()
        }

        startWork()
        DB.get(Path.Convos, proxyKey, convo.key, property.properties.name) { (data) in
            switch property.properties.value {
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
            self.finishWork()
        }
    }
}

extension AsyncWorkGroupKey {
    func check(_ property: SettableProxyProperty, forProxyInConvo convo: Convo , asSender: Bool, function: String = #function, line: Int = #line) {
        let (ownerId, proxyKey) = AsyncWorkGroupKey.getOwnerIdAndProxyKey(fromConvo: convo, asSender: asSender)
        check(property, ownerId: ownerId, proxyKey: proxyKey, function: function, line: line)
    }

    func check(_ property: SettableProxyProperty, forProxy proxy: Proxy, function: String = #function, line: Int = #line) {
        check(property, ownerId: proxy.ownerId, proxyKey: proxy.key, function: function, line: line)
    }

    func check(_ property: SettableProxyProperty, ownerId: String, proxyKey: String, function: String = #function, line: Int = #line) {
        let errorMessage = AsyncWorkGroupKey.makeErrorMessage(function: function, line: line)
        
        startWork()
        DB.get(Path.Proxies, ownerId, proxyKey, property.properties.name) { (data) in
            switch property.properties.value {
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
            self.finishWork()
        }
    }
}

extension AsyncWorkGroupKey {
    func check(_ property: IncrementableUserProperty, equals value: Int, forUser uid: String, function: String = #function, line: Int = #line) {
        startWork()
        DB.get(Path.UserInfo, uid, property.rawValue) { (data) in
            XCTAssertEqual(data?.value as? Int, value, AsyncWorkGroupKey.makeErrorMessage(function: function, line: line))
            self.finishWork()
        }
    }
}
