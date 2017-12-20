typealias AsyncWorkGroupKey = String

struct WorkGroup {
    static var workGroup: [AsyncWorkGroupKey: (group: DispatchGroup, result: Bool)] = {
        return [AsyncWorkGroupKey: (group: DispatchGroup, result: Bool)]()
    }()
}

extension AsyncWorkGroupKey {
    var workResult: Success {
        return WorkGroup.workGroup[self]?.result ?? false
    }

    init() {
        self = UUID().uuidString
        WorkGroup.workGroup[self] = (DispatchGroup(), true)
    }

    static func makeAsyncWorkGroupKey() -> AsyncWorkGroupKey {
        return AsyncWorkGroupKey()
    }

    func startWork() {
        WorkGroup.workGroup[self]?.group.enter()
    }

    func finishWork(withResult result: Success = true) {
        setWorkResult(result)
        leaveWorkGroup()
    }

    @discardableResult
    func setWorkResult(_ result: Success) -> Success {
        let result = WorkGroup.workGroup[self]?.result ?? false && result
        WorkGroup.workGroup[self]?.result = result
        return result
    }

    func leaveWorkGroup() {
        WorkGroup.workGroup[self]?.group.leave()
    }

    func notify(completion: @escaping () -> Void) {
        WorkGroup.workGroup[self]?.group.notify(queue: .main) {
            completion()
        }
    }

    func removeWorkGroup() {
        WorkGroup.workGroup.removeValue(forKey: self)
    }
}
