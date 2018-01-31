import FirebaseDatabase
import FirebaseHelper
import SearchTextField

protocol ProxyNamesLoading {
    init(querySize: UInt)
    func load(query: String, senderId: String, completion: @escaping ([SearchTextFieldItem]) -> Void)
}

// https://www.swiftbysundell.com/posts/a-deep-dive-into-grand-central-dispatch-in-swift
class ProxyNamesLoader: ProxyNamesLoading {
    private let querySize: UInt
    private let ref = try? FirebaseHelper.main.makeReference(Child.proxyNames)
    private var pendingWorkItem: DispatchWorkItem?

    required init(querySize: UInt = Setting.querySize) {
        self.querySize = querySize
    }

    func load(query: String, senderId: String, completion: @escaping ([SearchTextFieldItem]) -> Void) {
        pendingWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let _self = self else {
                return
            }
            self?.ref?
                .queryOrderedByKey()
                .queryStarting(atValue: query)
                .queryLimited(toFirst: _self.querySize)
                .observeSingleEvent(of: .value) { (data) in
                    completion(data.children.flatMap {
                        guard
                            let data = $0 as? DataSnapshot,
                            let proxy = try? Proxy(data),
                            proxy.ownerId != senderId else {
                                return nil
                        }
                        return SearchTextFieldItem(title: proxy.name,
                                                   subtitle: nil,
                                                   image: UIImage(named: proxy.icon))
                    })
            }
        }
        pendingWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250), execute: workItem)
    }
}
