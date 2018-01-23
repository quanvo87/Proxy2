import FirebaseDatabase
import GroupWork

class FirebaseDatabase: DatabaseType {
    private let generator: ProxyPropertyGenerating
    private let makeProxyRetries: Int

    required init(_ settings: [String: Any] = [:]) {
        self.generator = settings["generator"] as? ProxyPropertyGenerating ?? ProxyPropertyGenerator()
        self.makeProxyRetries = settings["makeProxyRetries"] as? Int ?? Setting.makeProxyRetries
    }

    func delete(_ proxy: Proxy, completion: @escaping (Error?) -> Void) {
        FirebaseDatabase.getConvosForProxy(key: proxy.key, ownerId: proxy.ownerId) { (convos) in
            guard let convos = convos else {
                completion(ProxyError.unknown)
                return
            }
            let work = GroupWork()
            work.delete(Child.proxies, proxy.ownerId, proxy.key)
            work.delete(Child.proxyNames, proxy.key)
            work.delete(convos)
            work.deleteUnreadMessages(for: proxy)
            work.setReceiverDeletedProxy(for: convos)
            work.allDone {
                completion(work.result ? nil : ProxyError.unknown)
            }
        }
    }

    func getProxy(key: String, completion: @escaping Callback) {
        FirebaseHelper.get(Child.proxyNames, key.lowercased().noWhiteSpaces) { (data) in
            guard
                let data = data,
                let proxy = Proxy(data) else {
                    completion(.failure(ProxyError.unknown))
                    return
            }
            self.getProxy(key: proxy.key, ownerId: proxy.ownerId, completion: completion)
        }
    }

    func getProxy(key: String, ownerId: String, completion: @escaping Callback) {
        FirebaseHelper.get(Child.proxies, ownerId, key) { (data) in
            guard
                let data = data,
                let proxy = Proxy(data) else {
                    completion(.failure(ProxyError.unknown))
                    return
            }
            completion(.success(proxy))
        }
    }

    func makeProxy(ownerId: String, completion: @escaping Callback) {
        makeProxy(ownerId: ownerId, attempt: 0, completion: completion)
    }

    private func makeProxy(ownerId: String, attempt: Int, completion: @escaping Callback) {
        guard let ref = FirebaseHelper.makeReference(Child.proxyNames) else {
            completion(.failure(ProxyError.unknown))
            return
        }
        let name = generator.randomProxyName
        let proxy = Proxy(icon: generator.randomIconName, name: name, ownerId: ownerId)
        let testKey = ref.childByAutoId().key
        FirebaseHelper.set(proxy.toDictionary(), at: Child.proxyNames, testKey) { [weak self] (success) in
            guard success else {
                completion(.failure(ProxyError.unknown))
                return
            }
            FirebaseDatabase.getProxyNameCount(ref: ref, name: name) { (count) in
                FirebaseHelper.delete(Child.proxyNames, testKey) { _ in }
                guard let _self = self else {
                    return
                }
                if count == 1 {
                    let work = GroupWork()
                    work.set(proxy.toDictionary(), at: Child.proxies, proxy.ownerId, proxy.key)
                    work.set(proxy.toDictionary(), at: Child.proxyNames, proxy.key)
                    work.allDone {
                        completion(work.result ? .success(proxy) : .failure(ProxyError.unknown))
                    }
                } else {
                    if attempt < _self.makeProxyRetries {
                        self?.makeProxy(ownerId: ownerId, attempt: attempt + 1, completion: completion)
                    } else {
                        completion(.failure(ProxyError.unknown))
                    }
                }
            }
        }
    }

    private static func getProxyNameCount(ref: DatabaseReference, name: String, completion: @escaping (UInt?) -> Void) {
        ref.queryOrdered(byChild: Child.name).queryEqual(toValue: name).observeSingleEvent(of: .value) { (data) in
            completion(data.childrenCount)
        }
    }

    func setIcon(to icon: String, for proxy: Proxy, completion: @escaping (Error?) -> Void) {
        FirebaseDatabase.getConvosForProxy(key: proxy.key, ownerId: proxy.ownerId) { (convos) in
            guard let convos = convos else {
                completion(ProxyError.unknown)
                return
            }
            let work = GroupWork()
            work.set(.icon(icon), for: proxy)
            work.setReceiverIcon(to: icon, for: convos)
            work.setSenderIcon(to: icon, for: convos)
            work.allDone {
                completion(work.result ? nil : ProxyError.unknown)
            }
        }
    }

    func setNickname(to nickname: String, for proxy: Proxy, completion: @escaping (Error?) -> Void) {
        FirebaseDatabase.getConvosForProxy(key: proxy.key, ownerId: proxy.ownerId) { (convos) in
            guard let convos = convos else {
                completion(ProxyError.unknown)
                return
            }
            let work = GroupWork()
            work.set(.nickname(nickname), for: proxy)
            work.setSenderNickname(to: nickname, for: convos)
            work.allDone {
                completion(work.result ? nil : ProxyError.unknown)
            }
        }
    }

    private static func getConvosForProxy(key: String, ownerId: String, completion: @escaping ([Convo]?) -> Void) {
        FirebaseHelper.get(Child.convos, ownerId) { (data) in
            completion(data?.toConvosArray(uid: ownerId, proxyKey: key))
        }
    }
}

extension GroupWork {
    func set(_ property: SettableProxyProperty, for proxy: Proxy) {
        set(property, uid: proxy.ownerId, proxyKey: proxy.key)
    }

    func set(_ property: SettableProxyProperty, forProxyIn convo: Convo, asSender: Bool) {
        let (ownerId, proxyKey) = GroupWork.getOwnerIdAndProxyKey(convo: convo, asSender: asSender)
        set(property, uid: ownerId, proxyKey: proxyKey)
    }

    func set(_ property: SettableProxyProperty, uid: String, proxyKey: String) {
        set(property.properties.value, at: Child.proxies, uid, proxyKey, property.properties.name)
    }
}

extension GroupWork {
    func delete(_ convos: [Convo]) {
        for convo in convos {
            delete(Child.convos, convo.senderId, convo.key)
            if convo.receiverDeletedProxy {
                delete(Child.messages, convo.key)
            }
        }
    }

    func deleteUnreadMessages(for proxy: Proxy) {
        start()
        GroupWork.getUnreadMessagesForProxy(uid: proxy.ownerId, key: proxy.key) { (messages) in
            guard let messages = messages else {
                self.finish(withResult: false)
                return
            }
            for message in messages {
                self.delete(Child.userInfo, message.receiverId, Child.unreadMessages, message.messageId)
            }
            self.finish(withResult: true)
        }
    }

    static func getUnreadMessagesForProxy(uid: String, key: String, completion: @escaping ([Message]?) -> Void) {
        guard let ref = FirebaseHelper.makeReference(Child.userInfo, uid, Child.unreadMessages) else {
            completion(nil)
            return
        }
        ref.queryOrdered(byChild: Child.receiverProxyKey).queryEqual(toValue: key).observeSingleEvent(of: .value) { (data) in
            completion(data.asMessagesArray)
        }
    }

    func setReceiverDeletedProxy(for convos: [Convo]) {
        for convo in convos {
            start()
            FirebaseHelper.set(true, at: Child.convos, convo.receiverId, convo.key, Child.receiverDeletedProxy) { (success) in
                self.finish(withResult: success)
                FirebaseHelper.getConvo(uid: convo.receiverId, key: convo.key) { (receiverConvo) in
                    if receiverConvo == nil {
                        FirebaseHelper.delete(Child.convos, convo.receiverId, convo.key) { _ in }
                    }
                }
            }
        }
    }

    func setReceiverIcon(to icon: String, for convos: [Convo]) {
        for convo in convos {
            set(.receiverIcon(icon), for: convo, asSender: false)
        }
    }

    func setSenderIcon(to icon: String, for convos: [Convo]) {
        for convo in convos {
            set(.senderIcon(icon), for: convo, asSender: true)
        }
    }

    func setSenderNickname(to nickname: String, for convos: [Convo]) {
        for convo in convos {
            set(.senderNickname(nickname), for: convo, asSender: true)
        }
    }
}
