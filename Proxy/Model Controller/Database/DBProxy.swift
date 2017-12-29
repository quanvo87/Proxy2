import FirebaseDatabase
import GroupWork
import UIKit

extension DB {
    typealias MakeProxyCallback = (Result<Proxy, ProxyError>) -> Void

    static func deleteProxy(_ proxy: Proxy, completion: @escaping (Success) -> Void) {
        DB.getConvos(forProxy: proxy) { (convos) in
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
        work.allDone {
            completion(work.result)
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

    static func makeProxy(withName proxyName: String = ProxyService.makeRandomProxyName(), forUser uid: String, maxAllowedProxies: Int = Setting.maxAllowedProxies, completion: @escaping MakeProxyCallback) {
        guard proxyName.count < Setting.maxNameSize else {
            completion(.failure(.inputTooLong))
            return
        }
        getProxyCount(forUser: uid) { (proxyCount) in
            guard proxyCount < maxAllowedProxies else {
                completion(.failure(.proxyLimitReached))
                return
            }
            makeProxyHelper(withName: proxyName, forUser: uid, completion: completion)
        }
    }

    private static func makeProxyHelper(withName proxyName: String, forUser uid: String, attempts: Int = 0, completion: @escaping MakeProxyCallback) {
        guard let proxyKeysRef = DB.makeReference(Child.proxyKeys) else {
            completion(.failure(.unknown))
            return
        }

        let proxyKey = proxyName.lowercased()
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
                        let proxy = Proxy(icon: ProxyService.makeRandomIconName(), name: proxyName, ownerId: uid)
                        let proxyOwner = ProxyOwner(key: proxyKey, ownerId: uid)

                        let work = GroupWork()
                        work.set(proxy.toDictionary(), at: Child.proxies, proxy.ownerId, proxy.key)
                        work.set(proxyKeyDictionary, at: Child.proxyKeys, proxy.key)
                        work.set(proxyOwner.toDictionary(), at: Child.proxyOwners, proxy.key)
                        work.allDone {
                            completion(work.result ? .success(proxy) : .failure(.unknown))
                        }

                    } else {
                        if attempts < Setting.maxMakeProxyAttempts {
                            makeProxyHelper(withName: ProxyService.makeRandomProxyName(), forUser: uid, attempts: attempts + 1, completion: completion)
                        } else {
                            completion(.failure(.unknown))
                        }
                    }
                }
            })
        }
    }

    static func setIcon(to icon: String, forProxy proxy: Proxy, completion: @escaping (Success) -> Void) {
        DB.getConvos(forProxy: proxy) { (convos) in
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

    static func setNickname(to nickname: String, forProxy proxy: Proxy, completion: @escaping (ProxyError?) -> Void) {
        guard nickname.count < Setting.maxNameSize else {
            completion(.inputTooLong)
            return
        }
        DB.getConvos(forProxy: proxy) { (convos) in
            guard let convos = convos else {
                completion(.unknown)
                return
            }
            setNickname(to: nickname, forProxy: proxy, withConvos: convos, completion: completion)
        }
    }

    static func setNickname(to nickname: String, forProxy proxy: Proxy, withConvos convos: [Convo], completion: @escaping (ProxyError?) -> Void) {
        let work = GroupWork()
        work.set(.nickname(nickname), forProxy: proxy)
        work.setSenderNickname(to: nickname, forConvos: convos)
        work.allDone {
            completion(work.result ? nil : .unknown)
        }
    }
}

extension GroupWork {
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
        DB.getUnreadMessagesForProxy(owner: proxy.ownerId, key: proxy.key) { (messages) in
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
}
