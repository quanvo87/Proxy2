import FirebaseDatabase
import GroupWork
import XCTest
@testable import Proxy

class FirebaseHelperTests: FirebaseTest {
    func testDecrement() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        let rand1 = Int(arc4random_uniform(500))
        let rand2 = Int(arc4random_uniform(500))
        FirebaseHelper.set(rand1, at: "test") { (success) in
            XCTAssert(success)
            let work = GroupWork()
            for _ in 1...rand2 {
                work.start()
                FirebaseHelper.increment(-1, at: "test") { (success) in
                    XCTAssert(success)
                    work.finish(withResult: true)
                }
            }
            work.allDone {
                FirebaseHelper.get("test") { (data) in
                    XCTAssertEqual(data?.value as? Int, rand1 - rand2)
                    expectation.fulfill()
                }
            }
        }
    }

    func testGetSetDelete() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseHelper.set("a", at: "test") { (success) in
            XCTAssert(success)
            FirebaseHelper.get("test") { (data) in
                XCTAssertEqual(data?.value as? String, "a")
                FirebaseHelper.delete("test") { (success) in
                    XCTAssert(success)
                    FirebaseHelper.get("test") { (data) in
                        XCTAssertFalse(data!.exists())
                        expectation.fulfill()
                    }
                }
            }
        }
    }

    func testIncrement() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        FirebaseHelper.increment(1, at: "test") { (success) in
            XCTAssert(success)
            FirebaseHelper.get("test") { (data) in
                XCTAssertEqual(data?.value as? Int, 1)
                expectation.fulfill()
            }
        }
    }

    func testIncrementConcurrent() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        let incrementsDone = DispatchGroup()
        for _ in 1...2 {
            incrementsDone.enter()
            FirebaseHelper.increment(1, at: "test") { (success) in
                XCTAssert(success)
                incrementsDone.leave()
            }
        }
        incrementsDone.notify(queue: .main) {
            FirebaseHelper.get("test") { (data) in
                XCTAssertEqual(data?.value as? Int, 2)
                expectation.fulfill()
            }
        }
    }

    func testMakeDatabaseReference() {
        XCTAssertNotNil(FirebaseHelper.makeReference("a"))
        XCTAssertNotNil(FirebaseHelper.makeReference("a", "b"))
        XCTAssertNotNil(FirebaseHelper.makeReference("/a/"))
        XCTAssertNotNil(FirebaseHelper.makeReference("//a//"))
        XCTAssertNotNil(FirebaseHelper.makeReference("/a/a/"))
    }

    func testMakeDatabaseReferenceFail() {
        XCTAssertNil(FirebaseHelper.makeReference(""))
        XCTAssertNil(FirebaseHelper.makeReference("a", ""))
        XCTAssertNil(FirebaseHelper.makeReference("", "a"))
        XCTAssertNil(FirebaseHelper.makeReference("/"))
        XCTAssertNil(FirebaseHelper.makeReference("//"))
        XCTAssertNil(FirebaseHelper.makeReference("///"))
        XCTAssertNil(FirebaseHelper.makeReference("/a//a/"))
    }
}
