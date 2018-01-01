import FirebaseDatabase
import GroupWork
import XCTest
@testable import Proxy

class DBConvoTests: DBTest {
    func testGetConvo() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.sendMessage { (_, convo, _, _) in
            DB.getConvo(withKey: convo.key, belongingTo: DBTest.uid) { (retrievedConvo) in
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
            DB.setReceiverNickname(to: testNickname, forConvo: convo) { (error) in
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
