import FirebaseAuth
import FirebaseDatabase
import XCTest
@testable import proxy

class DBTest: XCTestCase {
    private let auth = Auth.auth(app: Shared.shared.firebase!)
    private var handle: AuthStateDidChangeListenerHandle?

    private let uid = "YXNArkJQPXcEUFIs87tKm1nEP1K3"
    private let email = "emydadu-3857@yopmail.com"
    private let password = "+7rVajX5sYNRL[kZ"

    static let test = "test"
    static let testUser = "test user"

    var x = XCTestExpectation()

    override func setUp() {
        x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        XCTAssert(Shared.shared.asyncWorkGroups.isEmpty)

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
    }

    override func tearDown() {
        x = expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        XCTAssert(Shared.shared.asyncWorkGroups.isEmpty)
        setupTestEnv()
    }

    deinit {
        if let handle = handle {
            auth.removeStateDidChangeListener(handle)
        }
    }
}

private extension DBTest {
    func setupTestEnv() {
        let workKey = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
        workKey.deleteProxies(forUser: DBTest.testUser)
        workKey.deleteProxies(forUser: Shared.shared.uid)
        workKey.deleteTestData()
        workKey.notify {
            workKey.deleteUserInfo(DBTest.testUser)
            workKey.deleteUserInfo(Shared.shared.uid)
            workKey.notify {
                workKey.finishWorkGroup()
                self.x.fulfill()
            }
        }
    }
}

extension AsyncWorkGroupKey {
    func deleteProxies(forUser uid: String) {
        startWork()
        DBProxy.getProxies(forUser: uid) { (proxies) in
            guard let proxies = proxies else {
                XCTFail()
                return
            }
            for proxy in proxies {
                self.deleteProxy(proxy)
            }
            self.finishWork(withResult: true)
        }
    }

    func deleteProxy(_ proxy: Proxy) {
        startWork()
        DBProxy.deleteProxy(proxy) { (success) in
            XCTAssert(success)
            self.finishWork(withResult: success)
        }
    }

    func deleteTestData() {
        startWork()
        DB.delete(DBTest.test) { (success) in
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
    static func makeConvo(completion: @escaping (_ convo: Convo, _ sender: Proxy, _ receiver: Proxy) -> Void) {
        var sender = Proxy()
        var receiver = Proxy()

        let proxiesCreated = DispatchGroup()
        for _ in 1...2 {
            proxiesCreated.enter()
        }

        DBProxy.makeProxy(forUser: Shared.shared.uid) { (result) in
            switch result {
            case .failure: XCTFail()
            case .success(let proxy):
                sender = proxy
                proxiesCreated.leave()
            }
        }

        DBProxy.makeProxy(forUser: testUser) { (result) in
            switch result {
            case .failure: XCTFail()
            case .success(let proxy):
                receiver = proxy
                proxiesCreated.leave()
            }
        }

        proxiesCreated.notify(queue: .main) {
            DBConvo.makeConvo(senderProxy: sender, receiverProxy: receiver) { (convo) in
                guard let convo = convo else {
                    XCTFail()
                    return
                }
                completion(convo, sender, receiver)
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
