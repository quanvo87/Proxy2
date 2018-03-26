import FirebaseDatabase
import SearchTextField

protocol ProxyKeysLoading {
    func load(query: String, senderId: String, completion: @escaping ([SearchTextFieldItem]) -> Void)
}

class ProxyKeysLoader: ProxyKeysLoading {
    private let querySize: UInt
    private let ref = try? Shared.firebaseHelper.makeReference(Child.proxyKeys)
    private var pendingWorkItem: DispatchWorkItem?

    init(querySize: UInt = DatabaseOption.querySize) {
        self.querySize = querySize
    }

    func load(query: String, senderId: String, completion: @escaping ([SearchTextFieldItem]) -> Void) {
        pendingWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let _self = self else {
                return
            }
            self?.ref?
                .queryLimited(toFirst: _self.querySize)
                .queryOrderedByKey()
                .queryStarting(atValue: query)
                .observeSingleEvent(of: .value) { data in
                    completion(data.children.flatMap {
                        guard let data = $0 as? DataSnapshot,
                            let proxy = try? Proxy(data),
                            proxy.ownerId != senderId else {
                                return nil
                        }
                        return SearchTextFieldItem(
                            title: proxy.name,
                            subtitle: nil,
                            image: UIImage(named: proxy.icon)
                        )
                    })
            }
        }
        pendingWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250), execute: workItem)
    }
}
