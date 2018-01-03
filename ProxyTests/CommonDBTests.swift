import GroupWork
import XCTest
@testable import Proxy

class CommonDBTests: DBTest {
    func testIcons() {
        XCTAssertEqual(ProxyService.iconNames.count, 101)

        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        let work = GroupWork()
        for icon in ProxyService.iconNames {
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

    func testAsMessagesArray() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.sendMessage { (message, _, _, _) in
            DB.get(Child.messages, message.parentConvoKey) { (data) in
                XCTAssert(data?.asMessagesArray.contains(message) ?? false)
                expectation.fulfill()
            }
        }
    }

    func testToConvosArray() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.sendMessage { (_, convo, _, _) in
            DB.get(Child.convos, convo.senderId) { (data) in
                let convos = data!.toConvosArray(uid: "", proxyKey: nil)
                XCTAssertEqual(convos.count, 1)
                XCTAssert(convos.contains(convo))
                expectation.fulfill()
            }
        }
    }

    func testToProxiesArray() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeProxy { (proxy1) in
            DBTest.makeProxy { (proxy2) in
                DB.get(Child.proxies, DBTest.uid) { (data) in
                    let proxies = data!.toProxiesArray(uid: "")
                    XCTAssertEqual(proxies.count, 2)
                    XCTAssert(proxies.contains(proxy1))
                    XCTAssert(proxies.contains(proxy2))
                    expectation.fulfill()
                }
            }
        }
    }
}
