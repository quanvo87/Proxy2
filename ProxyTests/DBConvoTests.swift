import FirebaseDatabase
import GroupWork
import XCTest
@testable import Proxy

class DBConvoTests: DBTest {
    func testDelete() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.sendMessage { (_, convo, _, _) in
            DB.delete(convo, asSender: true) { (success) in
                XCTAssert(success)
                let work = GroupWork()
                work.checkDeleted(at: Child.convos, convo.senderId, convo.key)
                work.allDone {
                    expectation.fulfill()
                }
            }
        }
    }

    func testGetConvo() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.sendMessage { (_, convo, _, _) in
            DB.getConvo(uid: convo.senderId, key: convo.key) { (retrievedConvo) in
                XCTAssertEqual(retrievedConvo, convo)
                expectation.fulfill()
            }
        }
    }

    func testSetReceiverNickname() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.sendMessage { (_, convo, _, _) in
            let testNickname = "test nickname"
            DB.setReceiverNickname(to: testNickname, for: convo) { (error) in
                XCTAssertNil(error)
                let work = GroupWork()
                work.check(.receiverNickname(testNickname), forConvo: convo, asSender: true)
                work.allDone {
                    expectation.fulfill()
                }
            }
        }
    }
}
