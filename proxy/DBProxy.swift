import FirebaseDatabase

struct DBProxy {
    typealias MakeProxyCallback = (Result<Proxy, ProxyError>) -> Void

    private static var randomIcon: String {
        let randomIconIndex = Int(arc4random_uniform(UInt32(Shared.shared.proxyIconNames.count)))
        guard let randomIcon = Shared.shared.proxyIconNames[safe: randomIconIndex] else {
            return ""
        }
        return randomIcon
    }

    private static var randomName: String {
        let randomAdjectiveIndex = Int(arc4random_uniform(UInt32(Shared.shared.proxyNameWords.adjectives.count)))
        let randomNounIndex = Int(arc4random_uniform(UInt32(Shared.shared.proxyNameWords.nouns.count)))
        guard
            let randomAdjective = Shared.shared.proxyNameWords.adjectives[safe: randomAdjectiveIndex]?.lowercased().capitalized,
            let noun = Shared.shared.proxyNameWords.nouns[safe: randomNounIndex]?.lowercased().capitalized else {
                return ""
        }
        let randomNumber = Int(arc4random_uniform(9)) + 1
        return randomAdjective + noun + String(randomNumber)
    }

    static func cancelCreatingProxy() {
        Shared.shared.isCreatingProxy = false
    }

    static func deleteProxy(_ proxy: Proxy, completion: @escaping (Success) -> Void) {
        DBConvo.getConvos(forProxy: proxy, filtered: false) { (convos) in
            guard let convos = convos else {
                completion(false)
                return
            }
            deleteProxy(proxy, withConvos: convos, completion: completion)
        }
    }

    static func deleteProxy(_ proxy: Proxy, withConvos convos: [Convo], completion: @escaping (Success) -> Void) {
        let key = AsyncWorkGroupKey()
        key.delete(at: Child.Proxies, proxy.ownerId, proxy.key)
        key.delete(at: Child.ProxyKeys, proxy.key)
        key.delete(at: Child.ProxyOwners, proxy.key)
        key.deleteConvos(convos)
        key.increment(by: -proxy.unreadCount, forProperty: .unreadCount, forUser: proxy.ownerId)
        key.setReceiverDeletedProxy(to: true, forReceiverInConvos: convos)
        key.notify {
            completion(key.workResult)
            key.finishWorkGroup()
        }
    }

    static func getImageForIcon(_ icon: String, tag: Int, completion: @escaping ((image: UIImage, cellTag: Int)?) -> Void) {
        Shared.shared.queue.async {
            guard let image = UIImage(named: icon) else {
                completion(nil)
                return
            }
            completion((image, tag))
        }
    }
    
    static func getProxies(forUser uid: String, completion: @escaping ([Proxy]?) -> Void) {
        DB.get(Child.Proxies, uid) { (data) in
            completion(data?.toProxies())
        }
    }

    static func getProxy(withKey key: String, completion: @escaping (Proxy?) -> Void) {
        DB.get(Child.ProxyOwners, key) { (data) in
            guard let proxyOwner = ProxyOwner(data?.value as AnyObject) else {
                completion(nil)
                return
            }
            getProxy(withKey: proxyOwner.key, belongingTo: proxyOwner.ownerId, completion: completion)
        }
    }

    static func getProxy(withKey key: String, belongingTo uid: String, completion: @escaping (Proxy?) -> Void) {
        DB.get(Child.Proxies, uid, key) { (data) in
            completion(Proxy(data?.value as AnyObject))
        }
    }

    private static func getProxyCount(forUser uid: String, completion: @escaping (UInt) -> Void) {
        DB.get(Child.Proxies, uid) { (data) in
            completion(data?.childrenCount ?? 0)
        }
    }

    static func makeProxy(withName specificName: String? = nil, forUser uid: String = Shared.shared.uid, maxAllowedProxies: UInt = Settings.MaxAllowedProxies, completion: @escaping MakeProxyCallback) {
        getProxyCount(forUser: uid) { (proxyCount) in
            guard proxyCount < maxAllowedProxies else {
                completion(.failure(.proxyLimitReached))
                return
            }
            Shared.shared.isCreatingProxy = true
            makeProxyHelper(withName: specificName, forUser: uid, completion: completion)
        }
    }

    private static func makeProxyDone(result: Result<Proxy, ProxyError>, completion: MakeProxyCallback) {
        Shared.shared.isCreatingProxy = false
        completion(result)
    }

    private static func makeProxyHelper(withName specificName: String? = nil, forUser uid: String = Shared.shared.uid, completion: @escaping MakeProxyCallback) {
        guard let proxyKeysRef = DB.makeReference(Child.ProxyKeys) else {
            makeProxyDone(result: .failure(.unknown), completion: completion)
            return
        }

        let name: String

        if let specificName = specificName {
            name = specificName
        } else {
            name = DBProxy.randomName
        }

        let proxyKey = name.lowercased()
        let proxyKeyDictionary = [Child.Key: proxyKey]
        let autoId = proxyKeysRef.childByAutoId().key

        DB.set(proxyKeyDictionary, at: Child.ProxyKeys, autoId) { (success) in
            guard success else {
                makeProxyDone(result: .failure(.unknown), completion: completion)
                return
            }

            proxyKeysRef.queryOrdered(byChild: Child.Key).queryEqual(toValue: proxyKey).observeSingleEvent(of: .value, with: { (data) in
                DB.delete(Child.ProxyKeys, autoId) { (success) in
                    guard success else {
                        makeProxyDone(result: .failure(.unknown), completion: completion)
                        return
                    }

                    guard Shared.shared.isCreatingProxy else {
                        return
                    }

                    if data.childrenCount == 1 {
                        let proxy = Proxy(icon: DBProxy.randomIcon, name: name, ownerId: uid)
                        let proxyOwner = ProxyOwner(key: proxyKey, ownerId: uid)

                        let key = AsyncWorkGroupKey()
                        key.set(proxy.toDictionary(), at: Child.Proxies, proxy.ownerId, proxy.key)
                        key.set(proxyKeyDictionary, at: Child.ProxyKeys, proxy.key)
                        key.set(proxyOwner.toDictionary(), at: Child.ProxyOwners, proxy.key)
                        key.notify {
                            makeProxyDone(result: key.workResult ? .success(proxy) : .failure(.unknown), completion: completion)
                            key.finishWorkGroup()
                        }

                    } else {
                        if specificName == nil {
                            makeProxyHelper(forUser: uid, completion: completion)
                        } else {
                            makeProxyDone(result: .failure(.unknown), completion: completion)
                        }
                    }
                }
            })
        }
    }

    static func setIcon(to icon: String, forProxy proxy: Proxy, completion: @escaping (Success) -> Void) {
        DBConvo.getConvos(forProxy: proxy, filtered: false) { (convos) in
            guard let convos = convos else {
                completion(false)
                return
            }
            setIcon(to: icon, forProxy: proxy, withConvos: convos, completion: completion)
        }
    }

    static func setIcon(to icon: String, forProxy proxy: Proxy, withConvos convos: [Convo], completion: @escaping (Success) -> Void) {
        let key = AsyncWorkGroupKey()
        key.set(.icon(icon), forProxy: proxy)
        key.setReceiverIcon(to: icon, forConvos: convos)
        key.notify {
            completion(key.workResult)
            key.finishWorkGroup()
        }
    }

    static func setNickname(to nickname: String, forProxy proxy: Proxy, completion: @escaping (Success) -> Void) {
        DBConvo.getConvos(forProxy: proxy, filtered: false) { (convos) in
            guard let convos = convos else {
                completion(false)
                return
            }
            setNickname(to: nickname, forProxy: proxy, withConvos: convos, completion: completion)
        }
    }

    static func setNickname(to nickname: String, forProxy proxy: Proxy, withConvos convos: [Convo], completion: @escaping (Success) -> Void) {
        let key = AsyncWorkGroupKey()
        key.set(.nickname(nickname), forProxy: proxy)
        key.setSenderNickname(to: nickname, forConvos: convos)
        key.notify {
            completion(key.workResult)
            key.finishWorkGroup()
        }
    }
}

extension DataSnapshot {
    func toProxies() -> [Proxy] {
        var proxies = [Proxy]()
        for child in self.children {
            if let proxy = Proxy((child as? DataSnapshot)?.value as AnyObject) {
                proxies.append(proxy)
            }
        }
        return proxies
    }
}

extension AsyncWorkGroupKey {
    func deleteConvos(_ convos: [Convo]) {
        for convo in convos {
            self.delete(convo, asSender: true)
        }
    }

    func setReceiverIcon(to icon: String, forConvos convos: [Convo]) {
        for convo in convos {
            self.set(.receiverIcon(icon), forConvo: convo, asSender: false)
        }
    }

    func setSenderNickname(to nickname: String, forConvos convos: [Convo]) {
        for convo in convos {
            self.set(.senderNickname(nickname), forConvo: convo, asSender: true)
        }
    }

    func setReceiverDeletedProxy(to value: Bool, forReceiverInConvos convos: [Convo]) {
        for convo in convos {
            startWork()
            DBConvo.getConvo(withKey: convo.key, belongingTo: convo.receiverId) { (convo) in
                if let convo = convo {
                    self.set(.receiverDeletedProxy(value), forConvo: convo, asSender: true)
                }
                self.finishWork(withResult: true)
            }
        }
    }
}
