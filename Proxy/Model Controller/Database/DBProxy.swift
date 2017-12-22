import FirebaseDatabase
import GroupWork
import UIKit

struct DBProxy {
    typealias MakeProxyCallback = (Result<Proxy, ProxyError>) -> Void

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
        let work = GroupWork()
        work.delete(at: Child.proxies, proxy.ownerId, proxy.key)
        work.delete(at: Child.proxyKeys, proxy.key)
        work.delete(at: Child.proxyOwners, proxy.key)
        work.deleteConvos(convos)
        work.deleteUnreadMessages(for: proxy)
        work.setReceiverDeletedProxy(to: true, forReceiverInConvos: convos)
        work.allDone {
            completion(work.result)
        }
    }

    static func fixConvoCounts(uid: String, completion: @escaping (Success) -> Void) {
        DBProxy.getProxies(forUser: uid) { (proxies) in
            guard let proxies = proxies else {
                completion(false)
                return
            }
            let work = GroupWork()
            for proxy in proxies {
                work.start()
                getConvoCount(forProxy: proxy) { (convoCount) in
                    guard let convoCount = convoCount else {
                        completion(false)
                        return
                    }
                    work.set(.convoCount(Int(convoCount)), forProxy: proxy)
                    work.finish(withResult: true)
                }
            }
            work.allDone {
                completion(work.result)
            }
        }
    }

    static func getConvoCount(forProxy proxy: Proxy, completion: @escaping (UInt?) -> Void) {
        DB.get(Child.convos, proxy.key) { (data) in
            completion(data?.childrenCount)
        }
    }

    static func getProxies(forUser uid: String, completion: @escaping ([Proxy]?) -> Void) {
        DB.get(Child.proxies, uid) { (data) in
            completion(data?.toProxiesArray())
        }
    }

    static func getProxy(withKey key: String, completion: @escaping (Proxy?) -> Void) {
        DB.get(Child.proxyOwners, key) { (data) in
            guard let proxyOwner = ProxyOwner(data?.value as AnyObject) else {
                completion(nil)
                return
            }
            getProxy(withKey: proxyOwner.key, belongingTo: proxyOwner.ownerId, completion: completion)
        }
    }

    static func getProxy(withKey key: String, belongingTo uid: String, completion: @escaping (Proxy?) -> Void) {
        DB.get(Child.proxies, uid, key) { (data) in
            completion(Proxy(data?.value as AnyObject))
        }
    }

    private static func getProxyCount(forUser uid: String, completion: @escaping (UInt) -> Void) {
        DB.get(Child.proxies, uid) { (data) in
            completion(data?.childrenCount ?? 0)
        }
    }

    static func getUnreadMessagesForProxy(owner: String, key: String, completion: @escaping ([Message]?) -> Void) {
        guard let ref = DB.makeReference(Child.userInfo, owner, Child.unreadMessages) else {
            completion(nil)
            return
        }

        ref.queryOrdered(byChild: "receiverProxyKey").queryEqual(toValue: key).observeSingleEvent(of: .value, with: { (data) in
            completion(data.toMessagesArray())
        })
    }

    static func makeProxy(withName specificName: String? = nil, forUser uid: String, maxAllowedProxies: UInt = Setting.maxAllowedProxies, completion: @escaping MakeProxyCallback) {
        getProxyCount(forUser: uid) { (proxyCount) in
            guard proxyCount < maxAllowedProxies else {
                completion(.failure(.proxyLimitReached))
                return
            }
            makeProxyHelper(withName: specificName, forUser: uid, completion: completion)
        }
    }

    private static func makeProxyHelper(withName specificName: String? = nil, forUser uid: String, completion: @escaping MakeProxyCallback) {
        guard let proxyKeysRef = DB.makeReference(Child.proxyKeys) else {
            completion(.failure(.unknown))
            return
        }

        let name: String

        if let specificName = specificName {
            name = specificName
        } else {
            name = DBProxy.makeRandomProxyName()
        }

        let proxyKey = name.lowercased()
        let proxyKeyDictionary = [Child.key: proxyKey]
        let autoId = proxyKeysRef.childByAutoId().key

        DB.set(proxyKeyDictionary, at: Child.proxyKeys, autoId) { (success) in
            guard success else {
                completion(.failure(.unknown))
                return
            }

            proxyKeysRef.queryOrdered(byChild: Child.key).queryEqual(toValue: proxyKey).observeSingleEvent(of: .value, with: { (data) in
                DB.delete(Child.proxyKeys, autoId) { (success) in
                    guard success else {
                        completion(.failure(.unknown))
                        return
                    }

                    if data.childrenCount == 1 {
                        let proxy = Proxy(icon: DBProxy.makeRandomIconName(), name: name, ownerId: uid)
                        let proxyOwner = ProxyOwner(key: proxyKey, ownerId: uid)

                        let work = GroupWork()
                        work.set(proxy.toDictionary(), at: Child.proxies, proxy.ownerId, proxy.key)
                        work.set(proxyKeyDictionary, at: Child.proxyKeys, proxy.key)
                        work.set(proxyOwner.toDictionary(), at: Child.proxyOwners, proxy.key)
                        work.allDone {
                            completion(work.result ? .success(proxy) : .failure(.unknown))
                        }

                    } else {
                        if specificName == nil {
                            makeProxyHelper(forUser: uid, completion: completion)
                        } else {
                            completion(.failure(.unknown))
                        }
                    }
                }
            })
        }
    }

    static func makeRandomIconName(iconNames: [String] = ProxyService.iconNames) -> String {
        guard let name = iconNames[safe: iconNames.count.random] else {
            return ""
        }
        return name
    }

    static func makeRandomProxyName(adjectives: [String] = ProxyService.words.adjectives, nouns: [String] = ProxyService.words.nouns, numberRange: Int = 9) -> String {
        guard
            let adjective = adjectives[safe: adjectives.count.random]?.lowercased().capitalized,
            let noun = nouns[safe: nouns.count.random]?.lowercased().capitalized else {
                return ""
        }
        let number = numberRange.random + 1
        return adjective + noun + String(number)
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
        let work = GroupWork()
        work.set(.icon(icon), forProxy: proxy)
        work.setReceiverIcon(to: icon, forConvos: convos)
        work.allDone {
            completion(work.result)
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
        let work = GroupWork()
        work.set(.nickname(nickname), forProxy: proxy)
        work.setSenderNickname(to: nickname, forConvos: convos)
        work.allDone {
            completion(work.result)
        }
    }
}

extension DataSnapshot {
    func toProxiesArray() -> [Proxy] {
        var proxies = [Proxy]()
        for child in self.children {
            if let proxy = Proxy((child as? DataSnapshot)?.value as AnyObject) {
                proxies.append(proxy)
            }
        }
        return proxies
    }
}

extension GroupWork {
    func increment(by amount: Int, forProperty property: IncrementableProxyProperty, forProxy proxy: Proxy) {
        increment(by: amount, forProperty: property, forProxyWithKey: proxy.key, ownerId: proxy.ownerId)
    }

    func increment(by amount: Int, forProperty property: IncrementableProxyProperty, forProxyInConvo convo: Convo, asSender: Bool) {
        let (ownerId, proxyKey) = GroupWork.getOwnerIdAndProxyKey(fromConvo: convo, asSender: asSender)
        increment(by: amount, forProperty: property, forProxyWithKey: proxyKey, ownerId: ownerId)
    }

    func increment(by amount: Int, forProperty property: IncrementableProxyProperty, forProxyWithKey key: String, ownerId: String) {
        increment(by: amount, at: Child.proxies, ownerId, key, property.rawValue)
    }

    func set(_ property: SettableProxyProperty, forProxy proxy: Proxy) {
        set(property, forProxyWithKey: proxy.key, proxyOwner: proxy.ownerId)
    }

    func set(_ property: SettableProxyProperty, forProxyInConvo convo: Convo, asSender: Bool) {
        let (ownerId, proxyKey) = GroupWork.getOwnerIdAndProxyKey(fromConvo: convo, asSender: asSender)
        set(property, forProxyWithKey: proxyKey, proxyOwner: ownerId)
    }

    func set(_ property: SettableProxyProperty, forProxyWithKey key: String, proxyOwner: String) {
        set(property.properties.value, at: Child.proxies, proxyOwner, key, property.properties.name)
    }
}

extension GroupWork {
    func deleteConvos(_ convos: [Convo]) {
        for convo in convos {
            self.delete(convo, asSender: true)
        }
    }

    func deleteUnreadMessages(for proxy: Proxy) {
        start()
        DBProxy.getUnreadMessagesForProxy(owner: proxy.ownerId, key: proxy.key) { (messages) in
            guard let messages = messages else {
                self.finish(withResult: false)
                return
            }

            for message in messages {
                self.delete(at: Child.userInfo, message.receiverId, Child.unreadMessages, message.messageId)
            }

            self.finish(withResult: true)
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
            start()
            DBConvo.getConvo(withKey: convo.key, belongingTo: convo.receiverId) { (convo) in
                if let convo = convo {
                    self.set(.receiverDeletedProxy(value), forConvo: convo, asSender: true)
                }
                self.finish(withResult: true)
            }
        }
    }
}
