import FirebaseDatabase
import XCTest
@testable import proxy

class DBTests: DBTest {
    func testGetSetDelete() {
        let expectation = self.expectation(description: #function)
        
        DB.set("a", at: "test") { (success) in
            XCTAssert(success)
            
            DB.get("test") { (data) in
                XCTAssertEqual(data?.value as? String ?? "", "a")
                
                DB.delete("test") { (success) in
                    XCTAssert(success)
                    
                    DB.get("test") { (data) in
                        XCTAssertEqual(data?.value as? FirebaseDatabase.NSNull, FirebaseDatabase.NSNull())
                        expectation.fulfill()
                    }
                }
            }
        }
        waitForExpectations(timeout: 10)
    }
    
    func testIncrement() {
        let expectation = self.expectation(description: #function)
        
        DB.increment(by: 1, at: "test") { (success) in
            XCTAssert(success)
            
            DB.get("test") { (data) in
                XCTAssertEqual(data?.value as? Int ?? 0, 1)
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 10)
    }
    
    func testIncrementConcurrent() {
        let expectation = self.expectation(description: #function)
        
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
                XCTAssertEqual(data?.value as? Int ?? 0, 2)
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 10)
    }

    func testMakeDatabaseReference() {
        XCTAssertNotNil(DB.makeDatabaseReference("a"))
        XCTAssertNotNil(DB.makeDatabaseReference("a", "b"))
        XCTAssertNotNil(DB.makeDatabaseReference("/a/"))
        XCTAssertNotNil(DB.makeDatabaseReference("//a//"))
        XCTAssertNotNil(DB.makeDatabaseReference("/a/a/"))
    }
    
    func testMakeDatabaseReferenceFail() {
        XCTAssertNil(DB.makeDatabaseReference(""))
        XCTAssertNil(DB.makeDatabaseReference("a", ""))
        XCTAssertNil(DB.makeDatabaseReference("", "a"))
        XCTAssertNil(DB.makeDatabaseReference("/"))
        XCTAssertNil(DB.makeDatabaseReference("//"))
        XCTAssertNil(DB.makeDatabaseReference("///"))
        XCTAssertNil(DB.makeDatabaseReference("/a//a/"))
    }
}
