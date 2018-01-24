import FirebaseDatabase
import SearchTextField

protocol ProxyNamesLoading {
    func load(query: String,
              querySize: UInt,
              uid: String,
              completion: @escaping ([SearchTextFieldItem]) -> Void)
}

// https://www.swiftbysundell.com/posts/a-deep-dive-into-grand-central-dispatch-in-swift
class ProxyNamesLoader: ProxyNamesLoading {
    private let ref = FirebaseHelper.makeReference(Child.proxyNames)
    private var pendingWorkItem: DispatchWorkItem?

    func load(query: String,
              querySize: UInt,
              uid: String,
              completion: @escaping ([SearchTextFieldItem]) -> Void) {
        pendingWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.ref?
                .queryOrderedByKey()
                .queryStarting(atValue: query)
                .queryLimited(toFirst: querySize)
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
