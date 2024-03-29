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
            guard let `self` = self else {
                return
            }
            var tempHandle: DatabaseHandle?
            tempHandle = self.ref?
                .queryLimited(toFirst: DatabaseOption.querySize)
                .queryOrderedByKey()
                .queryStarting(atValue: query)
                .observe(.value) { data in
                    guard let handle = tempHandle else {
                        return
                    }
                    defer {
                        self.ref?.removeObserver(withHandle: handle)
                    }
                    completion(data.children.compactMap {
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
