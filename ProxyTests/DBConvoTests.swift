import FirebaseDatabase
import GroupWork
import XCTest
@testable import Proxy

class DBConvoTests: DBTest {
    func testDeleteConvo() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (convo, _, _) in
            DB.deleteConvo(convo) { (success) in
                XCTAssert(success)

                let work = GroupWork()
                work.checkConvoDeleted(convo, asSender: true)
                work.allDone {
                    expectation.fulfill()
                }
            }
        }
    }

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

    func testGetConvosForProxy() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (convo, sender, _) in
            DB.getConvos(forProxy: sender) { (convos) in
                XCTAssertEqual(convos?.count, 1)
                XCTAssertEqual(convos?[0], convo)
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

    func testToConvosArray() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBTest.makeConvo { (convo, _, _) in
            DB.get(Child.convos, convo.senderId) { (data) in
                let convos = data?.toConvosArray()
                XCTAssertEqual(convos?.count, 1)
                XCTAssertEqual(convos?[safe: 0], convo)
                expectation.fulfill()
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
            XCTAssertEqual(Convo(data?.value as AnyObject), convo)
            self.finish(withResult: true)
        }

        start()
        DB.get(Child.convos, proxyKey, convo.key) { (data) in
            XCTAssertEqual(Convo(data?.value as AnyObject), convo)
            self.finish(withResult: true)
        }
    }
}
