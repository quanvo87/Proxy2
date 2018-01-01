import FirebaseDatabase
import GroupWork
import XCTest
@testable import Proxy

class DBConvoTests: DBTest {
    func testGetConvo() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (convo, _, _) in
            DB.getConvo(withKey: convo.key, belongingTo: DBTest.uid) { (retrievedConvo) in
                XCTAssertEqual(retrievedConvo, convo)
                expectation.fulfill()
            }
        }
    }

    func testSetReceiverNickname() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (convo, _, _) in
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

extension GroupWork {
    func checkConvoDeleted(_ convo: Convo, asSender: Bool) {
        let (ownerId, proxyKey) = GroupWork.getOwnerIdAndProxyKey(fromConvo: convo, asSender: asSender)
        checkDeleted(at: Child.convos, ownerId, convo.key)
        checkDeleted(at: Child.convos, proxyKey, convo.key)
    }

    func checkConvoCreated(_ convo: Convo, asSender: Bool) {
        let (ownerId, proxyKey) = GroupWork.getOwnerIdAndProxyKey(fromConvo: convo, asSender: asSender)
        start()
        DB.get(Child.convos, ownerId, convo.key) { (data) in
            XCTAssertEqual(Convo(data!), convo)
            self.finish(withResult: true)
        }
        start()
        DB.get(Child.convos, proxyKey, convo.key) { (data) in
            XCTAssertEqual(Convo(data!), convo)
            self.finish(withResult: true)
        }
    }
}
