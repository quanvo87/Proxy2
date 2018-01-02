import FirebaseDatabase
import GroupWork
import UIKit

extension DB {
    typealias MakeProxyCallback = (Result<Proxy, ProxyError>) -> Void

    static func deleteProxy(_ proxy: Proxy, completion: @escaping (Bool) -> Void) {
        getConvos(forProxyWithKey: proxy.key) { (convos) in
            guard let convos = convos else {
                completion(false)
                return
            }
            deleteProxy(proxy, withConvos: convos, completion: completion)
        }
    }

    static func deleteProxy(_ proxy: Proxy, withConvos convos: [Convo], completion: @escaping (Bool) -> Void) {
        let work = GroupWork()
        work.delete(at: Child.proxies, proxy.ownerId, proxy.key)
        work.delete(at: Child.proxyKeys, proxy.key)
        work.delete(at: Child.proxyOwners, proxy.key)
        work.deleteConvosForProxy(proxy)
        work.deleteUnreadMessages(for: proxy)
        work.setReceiverDeletedProxy(convos)
        work.allDone {
            completion(work.result)
        }
    }

    static func getProxy(withKey key: String, completion: @escaping (Proxy?) -> Void) {
        get(Child.proxyOwners, key) { (data) in
            guard
                let data = data,
                let proxyOwner = ProxyOwner(data) else {
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
            completion(Proxy(data))
        }
    }

    static func makeProxy(withName proxyName: String = ProxyService.makeRandomProxyName(),
                          maxNameSize: Int = Setting.maxNameSize,
                          forUser uid: String,
                          currentProxyCount: Int,
                          maxProxyCount: Int = Setting.maxProxyCount,
                          maxAttemps: Int = Setting.maxMakeProxyAttempts,
                          completion: @escaping MakeProxyCallback) {
        guard proxyName.count < maxNameSize else {
            completion(.failure(.inputTooLong))
            return
        }
        guard currentProxyCount < maxProxyCount else {
            completion(.failure(.proxyLimitReached))
            return
        }
        makeProxyHelper(withName: proxyName, forUser: uid, maxAttempts: maxAttemps, completion: completion)
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
            getProxyKeyCount(ref: proxyKeysRef, key: proxyKey, completion: { (count) in
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

    private static func getProxyKeyCount(ref: DatabaseReference, key: String, completion: @escaping (UInt?) -> Void) {
        ref.queryOrdered(byChild: Child.key).queryEqual(toValue: key).observeSingleEvent(of: .value, with: { (data) in
            completion(data.childrenCount)
        })
    }

    static func setIcon(to icon: String, forProxy proxy: Proxy, completion: @escaping (Bool) -> Void) {
        getConvos(forProxyWithKey: proxy.key) { (convos) in
            guard let convos = convos else {
                completion(false)
                return
            }
            setIcon(to: icon, forProxy: proxy, withConvos: convos, completion: completion)
        }
    }

    static func setIcon(to icon: String, forProxy proxy: Proxy, withConvos convos: [Convo], completion: @escaping (Bool) -> Void) {
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
        getConvos(forProxyWithKey: proxy.key) { (convos) in
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

    private static func getConvos(forProxyWithKey proxyKey: String, completion: @escaping ([Convo]?) -> Void) {
        get(Child.convos, proxyKey) { (data) in
            completion(data?.asConvosArray)
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
    func deleteConvosForProxy(_ proxy: Proxy) {
        delete(at: Child.convos, proxy.key)
        start()
        let ref = DB.makeReference(Child.convos, proxy.ownerId)
        ref?.queryOrdered(byChild: Child.senderProxyKey).queryEqual(toValue: proxy.key).observeSingleEvent(of: .value, with: { (data) in
            for child in data.children {
                guard let childData = child as? DataSnapshot else {
                    continue
                }
                self.delete(at: Child.convos, proxy.ownerId, childData.key)
            }
            self.finish(withResult: true)
        })
    }

    func setReceiverDeletedProxy(_ convos: [Convo]) {
        for convo in convos {
            set(.receiverDeletedProxy(true), forConvo: convo, asSender: false)
        }
    }

    func setReceiverIcon(to icon: String, forConvos convos: [Convo]) {
        for convo in convos {
            set(.receiverIcon(icon), forConvo: convo, asSender: false)
        }
    }

    func setSenderNickname(to nickname: String, forConvos convos: [Convo]) {
        for convo in convos {
            self.set(.senderNickname(nickname), forConvo: convo, asSender: true)
        }
    }

    func deleteUnreadMessages(for proxy: Proxy) {
        start()
        GroupWork.getUnreadMessagesForProxy(ownerId: proxy.ownerId, proxyKey: proxy.key) { (messages) in
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

    static func getUnreadMessagesForProxy(ownerId: String, proxyKey: String, completion: @escaping ([Message]?) -> Void) {
        guard let ref = DB.makeReference(Child.userInfo, ownerId, Child.unreadMessages) else {
            completion(nil)
            return
        }
        ref.queryOrdered(byChild: Child.receiverProxyKey).queryEqual(toValue: proxyKey).observeSingleEvent(of: .value, with: { (data) in
            completion(data.asMessagesArray)
        })
    }
}
