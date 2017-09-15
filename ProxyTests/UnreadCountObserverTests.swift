import XCTest
@testable import Proxy

class UnreadCountObserverTests: DBTest {
    let delegate = TestUnreadCountObserverDelegate()
    var unreadCountObserver: UnreadCountObserver?

    func testReadMessage() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        unreadCountObserver = UnreadCountObserver(user: DBTest.testUser, delegate: delegate)
        unreadCountObserver?.observe()

        DBTest.sendMessage { (message, _, _, _) in

            DBMessage.read(message) { (success) in
                XCTAssert(success)

                XCTAssertEqual(self.delegate.unreadCount, 0)

                expectation.fulfill()
            }
        }
    }
    
    func testReceiveMessage() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        unreadCountObserver = UnreadCountObserver(user: DBTest.testUser, delegate: delegate)
        unreadCountObserver?.observe()

        DBTest.sendMessage { (_, _, _, _) in
            XCTAssertEqual(self.delegate.unreadCount, 1)

            expectation.fulfill()
        }
    }
}

class TestUnreadCountObserverDelegate: UnreadCountObserving {
    var unreadCount: Int?

    func setUnreadCount(_ count: Int?) {
        unreadCount = count
    }
}
