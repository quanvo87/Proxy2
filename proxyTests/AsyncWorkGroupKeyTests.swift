import XCTest
@testable import proxy

class AsyncWorkGroupKeyTests: XCTestCase {
    var workKey: AsyncWorkGroupKey!

    override func setUp() {
        workKey = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
    }

    override func tearDown() {
        workKey.finishWorkGroup()
    }

    func testWorkResult() {
        XCTAssert(workKey.workResult)
    }

    func testMake() {
        let workKey = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
        XCTAssertGreaterThan(workKey.count, 0)
        XCTAssertNotNil(Shared.shared.asyncWorkGroups[workKey])
        workKey.finishWorkGroup()
    }

    func testFinishWork() {
        workKey.startWork()
        workKey.finishWork(withResult: false)
        XCTAssertFalse(Shared.shared.asyncWorkGroups[workKey]?.result ?? true)
    }

    func testFinishWorkGroup() {
        let workKey = AsyncWorkGroupKey.makeAsyncWorkGroupKey()
        workKey.startWork()
        workKey.finishWork(withResult: true)
        workKey.finishWorkGroup()
        XCTAssertNil(Shared.shared.asyncWorkGroups[workKey])
    }

    func testSetWorkResult() {
        workKey.setWorkResult(false)
        XCTAssertFalse(Shared.shared.asyncWorkGroups[workKey]?.result ?? true)
    }
}
