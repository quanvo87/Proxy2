import FirebaseDatabase
import SearchTextField

protocol ProxyNamesLoading {
    init(querySize: UInt)
    func load(query: String, uid: String, completion: @escaping ([SearchTextFieldItem]) -> Void)
}

// https://www.swiftbysundell.com/posts/a-deep-dive-into-grand-central-dispatch-in-swift
class ProxyNamesLoader: ProxyNamesLoading {
    private let querySize: UInt
    private let ref = FirebaseHelper.makeReference(Child.proxyNames)
    private var pendingWorkItem: DispatchWorkItem?

    required init(querySize: UInt = Setting.querySize) {
        self.querySize = querySize
    }

    func load(query: String, uid: String, completion: @escaping ([SearchTextFieldItem]) -> Void) {
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
                    var items = [SearchTextFieldItem]()
                    for child in data.children {
                        guard
                            let data = child as? DataSnapshot,
                            let proxy = Proxy(data),
                            proxy.ownerId != uid else {
                                continue
                        }
                        items.append(SearchTextFieldItem.init(title: proxy.name,
                                                              subtitle: nil,
                                                              image: UIImage(named: proxy.icon)))
                    }
                    completion(items)
            }
        }
        pendingWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250), execute: workItem)
    }
}
