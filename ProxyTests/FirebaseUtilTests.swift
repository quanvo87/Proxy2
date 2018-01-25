import GroupWork
import XCTest
@testable import Proxy

class FirebaseUtilTests: FirebaseTest {
    func testDatasnapshotAsMessagesArray() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTest.sendMessage { (message, _, _, _) in
            FirebaseHelper.get(Child.messages, message.parentConvoKey) { (data) in
                XCTAssert(data?.asMessagesArray.contains(message) ?? false)
                expectation.fulfill()
            }
        }
    }

    func testDatasnapshotToConvosArray() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTest.sendMessage { (_, convo, _, _) in
            FirebaseHelper.get(Child.convos, convo.senderId) { (data) in
                let convos = data!.toConvosArray(uid: "", proxyKey: nil)
                XCTAssertEqual(convos.count, 1)
                XCTAssert(convos.contains(convo))
                expectation.fulfill()
            }
        }
    }

    func testDatasnapshotToProxiesArray() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTest.makeProxy { (proxy1) in
            FirebaseTest.makeProxy { (proxy2) in
                FirebaseHelper.get(Child.proxies, FirebaseTest.uid) { (data) in
                    let proxies = data!.toProxiesArray(uid: "")
                    XCTAssertEqual(proxies.count, 2)
                    XCTAssert(proxies.contains(proxy1))
                    XCTAssert(proxies.contains(proxy2))
                    expectation.fulfill()
                }
            }
        }
    }

    func testIcons() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        let work = GroupWork()
        for icon in ProxyPropertyGenerator().iconNames {
            work.start()
            UIImage.make(name: icon) { (image) in
                XCTAssertNotNil(image)
                work.finish(withResult: true)
            }
        }
        work.allDone {
            expectation.fulfill()
        }
    }

}
