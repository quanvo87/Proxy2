import FirebaseDatabase
import GroupWork
import UIKit

extension DB {
    typealias MakeProxyCallback = (Result<Proxy, ProxyError>) -> Void

    static func deleteProxy(_ proxy: Proxy, completion: @escaping (Success) -> Void) {
        getConvos(forProxy: proxy) { (convos) in
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
        get(Child.proxyOwners, key) { (data) in
            guard
                let data = data,
                let proxyOwner = ProxyOwner(data: data, ref: DB.makeReference(Child.proxyOwners)) else {
                    completion(nil)
                    return
            }
            getProxy(withKey: proxyOwner.key, belongingTo: proxyOwner.ownerId, completion: completion)
        }
    }

    static func getProxy(withKey key: String, belongingTo uid: String, completion: @escaping (Proxy?) -> Void) {
        get(Child.proxies, uid, key) { (data) in
            guard let data = data else {
                completion(nil)
                return
            }
            completion(Proxy(data: data, ref: makeReference(Child.proxies, uid)))
        }
    }

    private static func getProxyCount(forUser uid: String, completion: @escaping (UInt) -> Void) {
        get(Child.proxies, uid) { (data) in
            completion(data?.childrenCount ?? 0)
        }
    }

    static func getUnreadMessagesForProxy(ownerId: String, proxyKey: String, completion: @escaping ([Message]?) -> Void) {
        guard let ref = makeReference(Child.userInfo, ownerId, Child.unreadMessages) else {
            completion(nil)
            return
        }
        ref.queryOrdered(byChild: Child.receiverProxyKey).queryEqual(toValue: proxyKey).observeSingleEvent(of: .value, with: { (data) in
            completion(data.toMessagesArray(ref))
        })
    }

    static func makeProxy(withName proxyName: String = ProxyService.makeRandomProxyName(),
                          maxNameSize: Int = Setting.maxNameSize,
                          forUser uid: String,
                          maxProxyCount: Int = Setting.maxProxyCount,
                          maxAttemps: Int = Setting.maxMakeProxyAttempts,
                          completion: @escaping MakeProxyCallback) {
        guard proxyName.count < maxNameSize else {
            completion(.failure(.inputTooLong))
            return
        }
        getProxyCount(forUser: uid) { (proxyCount) in
            guard proxyCount < maxProxyCount else {
                completion(.failure(.proxyLimitReached))
                return
            }
            makeProxyHelper(withName: proxyName, forUser: uid, maxAttempts: maxAttemps, completion: completion)
        }
    }

    private static func makeProxyHelper(withName proxyName: String,
                                        forUser uid: String,
                                        attempts: Int = 0,
                                        maxAttempts: Int,
                                        completion: @escaping MakeProxyCallback) {
        guard let proxyKeysRef = makeReference(Child.proxyKeys) else {
            completion(.failure(.unknown))
            return
        }
        let proxyKey = proxyName.lowercased()
        let proxyKeyDictionary = [Child.key: proxyKey]
        let autoId = proxyKeysRef.childByAutoId().key
        set(proxyKeyDictionary, at: Child.proxyKeys, autoId) { (success) in
            guard success else {
                completion(.failure(.unknown))
                return
            }
            proxyKeyCount(ref: proxyKeysRef, key: proxyKey, completion: { (count) in
                delete(Child.proxyKeys, autoId) { (success) in
                    guard success else {
                        completion(.failure(.unknown))
                        return
                    }
                    if count == 1 {
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
                        if attempts < maxAttempts {
                            makeProxyHelper(withName: ProxyService.makeRandomProxyName(), forUser: uid, attempts: attempts + 1, maxAttempts: maxAttempts, completion: completion)
                        } else {
                            completion(.failure(.unknown))
                        }
                    }
                }
            })
        }
    }

    private static func proxyKeyCount(ref: DatabaseReference, key: String, completion: @escaping (UInt?) -> Void) {
        ref.queryOrdered(byChild: Child.key).queryEqual(toValue: key).observeSingleEvent(of: .value, with: { (data) in
            completion(data.childrenCount)
        })
    }

    static func setIcon(to icon: String, forProxy proxy: Proxy, completion: @escaping (Success) -> Void) {
        getConvos(forProxy: proxy) { (convos) in
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
        getConvos(forProxy: proxy) { (convos) in
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
        DB.getUnreadMessagesForProxy(ownerId: proxy.ownerId, proxyKey: proxy.key) { (messages) in
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
