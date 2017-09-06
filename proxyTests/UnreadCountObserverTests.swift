import XCTest
@testable import proxy

class UnreadCountObserverTests: DBTest {
    let delegate = TestUnreadCountObserverDelegate()
    let unreadCountObserver = UnreadCountObserver()

    func testReadMessage() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        unreadCountObserver.observe(uid: DBTest.testUser, delegate: delegate)

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

        unreadCountObserver.observe(uid: DBTest.testUser, delegate: delegate)

        DBTest.sendMessage { (_, _, _, _) in
            XCTAssertEqual(self.delegate.unreadCount, 1)

            expectation.fulfill()
        }
    }
}

class TestUnreadCountObserverDelegate: UnreadCountObserverDelegate {
    var unreadCount: Int?

    func setUnreadCount(to unreadCount: Int?) {
        self.unreadCount = unreadCount
    }
}
