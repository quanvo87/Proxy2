import FirebaseDatabase
import GroupWork
import XCTest
@testable import Proxy

class DBTests: DBTest {
    func testDecrement() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        let rand1 = Int(arc4random_uniform(500))
        let rand2 = Int(arc4random_uniform(500))

        DB.set(rand1, at: "test") { (success) in
            XCTAssert(success)

            let work = GroupWork()

            for _ in 1...rand2 {

                work.start()

                DB.increment(by: -1, at: "test") { (success) in
                    XCTAssert(success)

                    work.finish(withResult: true)
                }
            }

            work.allDone {
                DB.get("test") { (data) in
                    XCTAssertEqual(data?.value as? Int, rand1 - rand2)

                    expectation.fulfill()
                }
            }
        }
    }

    func testGetSetDelete() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DB.set("a", at: "test") { (success) in
            XCTAssert(success)
            
            DB.get("test") { (data) in
                XCTAssertEqual(data?.value as? String, "a")
                
                DB.delete("test") { (success) in
                    XCTAssert(success)
                    
                    DB.get("test") { (data) in
                        XCTAssertFalse(data?.exists() ?? true)
                        expectation.fulfill()
                    }
                }
            }
        }
    }
    
    func testIncrement() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }
        
        DB.increment(by: 1, at: "test") { (success) in
            XCTAssert(success)
            
            DB.get("test") { (data) in
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
            DB.increment(by: 1, at: "test") { (success) in
                XCTAssert(success)
                incrementsDone.leave()
            }
        }
        
        incrementsDone.notify(queue: .main) {
            DB.get("test") { (data) in
                XCTAssertEqual(data?.value as? Int, 2)
                expectation.fulfill()
            }
        }
    }

    func testMakeDatabaseReference() {
        XCTAssertNotNil(DB.makeReference("a"))
        XCTAssertNotNil(DB.makeReference("a", "b"))
        XCTAssertNotNil(DB.makeReference("/a/"))
        XCTAssertNotNil(DB.makeReference("//a//"))
        XCTAssertNotNil(DB.makeReference("/a/a/"))
    }
    
    func testMakeDatabaseReferenceFail() {
        XCTAssertNil(DB.makeReference(""))
        XCTAssertNil(DB.makeReference("a", ""))
        XCTAssertNil(DB.makeReference("", "a"))
        XCTAssertNil(DB.makeReference("/"))
        XCTAssertNil(DB.makeReference("//"))
        XCTAssertNil(DB.makeReference("///"))
        XCTAssertNil(DB.makeReference("/a//a/"))
    }
}
