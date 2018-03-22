import GroupWork
import XCTest
@testable import Proxy

class FirebaseUtilTests: FirebaseTest {
     func testDatasnapshotToConvosArray() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTest.sendMessage { _, convo, _, _ in
            Shared.firebaseHelper.get(Child.convos, convo.senderId) { result in
                switch result {
                case .failure(let error):
                    XCTFail(String(describing: error))
                    expectation.fulfill()
                case .success(let data):
                    let convos = data.asConvosArray(proxyKey: nil)
                    XCTAssertEqual(convos.count, 1)
                    XCTAssert(convos.contains(convo))
                    expectation.fulfill()
                }
            }
        }
    }

    func testDatasnapshotToMessagesArray() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTest.sendMessage { message, _, _, _ in
            Shared.firebaseHelper.get(Child.messages, message.parentConvoKey) { result in
                switch result {
                case .failure(let error):
                    XCTFail(String(describing: error))
                    expectation.fulfill()
                case .success(let data):
                    let messages = data.asMessagesArray
                    XCTAssertEqual(messages.count, 1)
                    XCTAssert(messages.contains(message))
                    expectation.fulfill()
                }
            }
        }
    }

    func testDatasnapshotToProxiesArray() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTest.makeProxy { proxy1 in
            FirebaseTest.makeProxy { proxy2 in
                Shared.firebaseHelper.get(Child.proxies, FirebaseTest.uid) { result in
                    switch result {
                    case .failure(let error):
                        XCTFail(String(describing: error))
                        expectation.fulfill()
                    case .success(let data):
                        let proxies = data.asProxiesArray
                        XCTAssertEqual(proxies.count, 2)
                        XCTAssert(proxies.contains(proxy1))
                        XCTAssert(proxies.contains(proxy2))
                        expectation.fulfill()
                    }
                }
            }
        }
    }
}
