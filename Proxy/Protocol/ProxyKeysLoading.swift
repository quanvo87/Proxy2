import FirebaseDatabase
import SearchTextField

protocol ProxyKeysLoading {
    func load(query: String, senderId: String, completion: @escaping ([SearchTextFieldItem]) -> Void)
}

class ProxyKeysLoader: ProxyKeysLoading {
    private let ref = try? Shared.firebaseHelper.makeReference(Child.proxyKeys)
    private var pendingWorkItem: DispatchWorkItem?

    func load(query: String, senderId: String, completion: @escaping ([SearchTextFieldItem]) -> Void) {
        pendingWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.ref?
                .queryLimited(toFirst: DatabaseOption.querySize)
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
                            image: Image.make(proxy.icon)
                        )
                    })
            }
        }
        pendingWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250), execute: workItem)
    }
}
