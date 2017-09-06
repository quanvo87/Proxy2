import XCTest
@testable import Proxy

class AsyncWorkGroupKeyTests: XCTestCase {
    var key: AsyncWorkGroupKey!
    
    override func setUp() {
        key = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
    }
    
    override func tearDown() {
        key.finishWorkGroup()
    }
    
    func testWorkResult() {
        XCTAssert(key.workResult)
    }
    
    func testMake() {
        let key = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
        XCTAssertGreaterThan(key.count, 0)
        XCTAssertNotNil(Shared.shared.asyncWorkGroups[key])
        key.finishWorkGroup()
    }
    
    func testFinishWork() {
        key.startWork()
        key.finishWork(withResult: false)
        XCTAssertFalse(Shared.shared.asyncWorkGroups[key]?.result ?? true)
    }
    
    func testFinishWorkGroup() {
        let key = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
        key.startWork()
        key.finishWork(withResult: true)
        key.finishWorkGroup()
        XCTAssertNil(Shared.shared.asyncWorkGroups[key])
    }
    
    func testSetWorkResult() {
        key.setWorkResult(false)
        XCTAssertFalse(Shared.shared.asyncWorkGroups[key]?.result ?? true)
    }
}
