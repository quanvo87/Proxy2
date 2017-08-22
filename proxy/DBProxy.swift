import FirebaseDatabase
import FirebaseStorage

struct DBProxy {
    typealias CreateProxyCallback = (Result<Proxy, ProxyError>) -> Void

    private static var randomIconName: String {
        guard !Shared.shared.iconNames.isEmpty else {
            return ""
        }
        let random = Int(arc4random_uniform(UInt32(Shared.shared.iconNames.count)))
        return Shared.shared.iconNames[random]
    }

    private static var randomProxyName: String {
        guard !Shared.shared.adjectives.isEmpty && !Shared.shared.nouns.isEmpty else {
            return ""
        }
        let randomAdj = Int(arc4random_uniform(UInt32(Shared.shared.adjectives.count)))
        let randomNoun = Int(arc4random_uniform(UInt32(Shared.shared.nouns.count)))
        let adj = Shared.shared.adjectives[randomAdj].lowercased().capitalized
        let noun = Shared.shared.nouns[randomNoun].lowercased().capitalized
        let num = String(Int(arc4random_uniform(9)) + 1)
        return adj + noun + num
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
        key.delete(at: Path.Proxies, proxy.ownerId, proxy.key)
        key.delete(at: Path.ProxyKeys, proxy.key)
        key.delete(at: Path.ProxyOwners, proxy.key)
        key.deleteConvos(convos)
        key.increment(by: -1, forProperty: .proxyCount, forUser: proxy.ownerId)
        key.increment(by: -proxy.unread, forProperty: .unread, forUser: proxy.ownerId)
        key.setReceiverDeletedProxy(to: true, forReceiverInConvos: convos)
        key.notify {
            completion(key.workResult)
            key.finishWorkGroup()
        }
    }

    static func getProxies(forUser uid: String, completion: @escaping ([Proxy]?) -> Void) {
        DB.get(Path.Proxies, uid) { (data) in
            completion(data?.toProxies())
        }
    }

    static func getProxy(withKey key: String, completion: @escaping (Proxy?) -> Void) {
        DB.get(Path.ProxyOwners, key) { (data) in
            guard let proxyOwner = ProxyOwner(data?.value as AnyObject) else {
                completion(nil)
                return
            }
            getProxy(withKey: proxyOwner.key, belongingTo: proxyOwner.ownerId, completion: completion)
        }
    }

    static func getProxy(withKey key: String, belongingTo uid: String, completion: @escaping (Proxy?) -> Void) {
        DB.get(Path.Proxies, uid, key) { (data) in
            completion(Proxy(data?.value as AnyObject))
        }
    }

    static func loadProxyInfo(completion: ((Success) -> Void)? = nil) {
        if  !Shared.shared.adjectives.isEmpty &&
            !Shared.shared.nouns.isEmpty &&
            !Shared.shared.iconNames.isEmpty {
            completion?(true)
            return
        }
        let workKey = AsyncWorkGroupKey()
        workKey.loadIconNames()
        workKey.loadProxyNameWords()
        workKey.notify() {
            completion?(workKey.workResult)
            workKey.finishWorkGroup()
        }
    }

    static func makeProxy(withName specificName: String? = nil, forUser uid: String = Shared.shared.uid, completion: @escaping CreateProxyCallback) {
        loadProxyInfo { (success) in
            guard success else {
                completion(.failure(.unknown))
                return
            }
            DB.get(Path.UserInfo, uid, Path.ProxyCount) { (data) in
                guard data?.value as? Int ?? 0 <= Settings.MaxAllowedProxies else {
                    completion(.failure(.proxyLimitReached))
                    return
                }
                Shared.shared.isCreatingProxy = true
                makeProxyHelper(withName: specificName, forUser: uid, completion: completion)
            }
        }
    }

    private static func makeProxyDone(result: Result<Proxy, ProxyError>, completion: CreateProxyCallback) {
        Shared.shared.isCreatingProxy = false
        completion(result)
    }

    private static func makeProxyHelper(withName specificName: String? = nil, forUser uid: String = Shared.shared.uid, completion: @escaping CreateProxyCallback) {
        guard let proxyKeysRef = DB.ref(Path.ProxyKeys) else {
            makeProxyDone(result: .failure(.unknown), completion: completion)
            return
        }

        let name: String

        if let specificName = specificName {
            name = specificName
        } else {
            name = DBProxy.randomProxyName
        }

        let proxyKey = name.lowercased()
        let proxyKeyDictionary = [Path.Key: proxyKey]
        let autoId = proxyKeysRef.childByAutoId().key

        DB.set(proxyKeyDictionary, at: Path.ProxyKeys, autoId) { (success) in
            guard success else {
                makeProxyDone(result: .failure(.unknown), completion: completion)
                return
            }
            proxyKeysRef.queryOrdered(byChild: Path.Key).queryEqual(toValue: proxyKey).observeSingleEvent(of: .value, with: { (data) in
                DB.delete(Path.ProxyKeys, autoId) { (success) in
                    guard success else {
                        makeProxyDone(result: .failure(.unknown), completion: completion)
                        return
                    }

                    guard Shared.shared.isCreatingProxy else {
                        return
                    }

                    if data.childrenCount == 1 {
                        let proxy = Proxy(icon: randomIconName, name: name, ownerId: uid)
                        let proxyOwner = ProxyOwner(key: proxyKey, ownerId: uid)

                        let key = AsyncWorkGroupKey()
                        key.increment(by: 1, forProperty: .proxyCount, forUser: uid)
                        key.set(proxy.toDictionary(), at: Path.Proxies, proxy.ownerId, proxy.key)
                        key.set(proxyKeyDictionary, at: Path.ProxyKeys, proxy.key)
                        key.set(proxyOwner.toDictionary(), at: Path.ProxyOwners, proxy.key)
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
        key.setIcon(to: icon, forConvos: convos)
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

    func loadIconNames() {
        startWork()
        Storage.storage().reference(forURL: URLs.Storage + "/app").child("iconNames.json").getData(maxSize: 1 * 1024 * 1024) { (data, error) in
            if  error == nil,
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data),
                let dictionary = json as? [String: Any],
                let iconsNames = dictionary["iconNames"] as? [String] {
                Shared.shared.iconNames = iconsNames
            }
            self.finishWork(withResult: !Shared.shared.iconNames.isEmpty)
        }
    }

    func loadProxyNameWords() {
        startWork()
        Storage.storage().reference(forURL: URLs.Storage + "/app").child("words.json").getData(maxSize: 1 * 1024 * 1024) { (data, error) in
            if  error == nil,
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data),
                let dictionary = json as? [String: Any],
                let adjectives = dictionary["adjectives"] as? [String],
                let nouns = dictionary["nouns"] as? [String] {
                Shared.shared.adjectives = adjectives
                Shared.shared.nouns = nouns
            }
            self.finishWork(withResult: !Shared.shared.adjectives.isEmpty && !Shared.shared.nouns.isEmpty)
        }
    }

    func setIcon(to icon: String, forConvos convos: [Convo]) {
        for convo in convos {
            self.set(.icon(icon), forConvo: convo, asSender: false)
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
