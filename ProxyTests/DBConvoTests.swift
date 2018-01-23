import FirebaseDatabase
import GroupWork
import XCTest
@testable import Proxy

class DBConvoTests: FirebaseTest {
    func testDelete() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTest.sendMessage { (_, convo, _, _) in
            FirebaseHelper.delete(convo, asSender: true) { (success) in
                XCTAssert(success)
                let work = GroupWork()
                work.checkDeleted(Child.convos, convo.senderId, convo.key)
                work.allDone {
                    expectation.fulfill()
                }
            }
        }
    }

    func testGetConvo() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTest.sendMessage { (_, convo, _, _) in
            FirebaseHelper.getConvo(uid: convo.senderId, key: convo.key) { (retrievedConvo) in
                XCTAssertEqual(retrievedConvo, convo)
                expectation.fulfill()
            }
        }
    }

    func testSetReceiverNickname() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseTest.sendMessage { (_, convo, _, _) in
            let testNickname = "test nickname"
            FirebaseHelper.setReceiverNickname(to: testNickname, for: convo) { (error) in
                XCTAssertNil(error)
                let work = GroupWork()
                work.check(.receiverNickname(testNickname), for: convo, asSender: true)
                work.allDone {
                    expectation.fulfill()
                }
            }
        }
    }
}
