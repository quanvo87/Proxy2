import XCTest
@testable import Proxy

class AsyncWorkGroupKeyTests: XCTestCase {
    var key: AsyncWorkGroupKey!
    
    override func setUp() {
        key = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
    }
    
    override func tearDown() {
        key.removeWorkGroup()
    }
    
    func testWorkResult() {
        XCTAssert(key.workResult)
    }
    
    func testMake() {
        let key = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
        XCTAssertGreaterThan(key.count, 0)
        XCTAssertNotNil(WorkGroup.workGroup[key])
        key.removeWorkGroup()
    }
    
    func testFinishWork() {
        key.startWork()
        key.finishWork(withResult: false)
        XCTAssertFalse(WorkGroup.workGroup[key]?.result ?? true)
    }
    
    func testFinishWorkGroup() {
        let key = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
        key.startWork()
        key.finishWork(withResult: true)
        key.removeWorkGroup()
        XCTAssertNil(WorkGroup.workGroup[key])
    }
    
    func testSetWorkResult() {
        key.setWorkResult(false)
        XCTAssertFalse(WorkGroup.workGroup[key]?.result ?? true)
    }
}
