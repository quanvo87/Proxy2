import FirebaseDatabase
import GroupWork
import UIKit

extension DB {
    typealias MakeProxyCallback = (Result<Proxy, ProxyError>) -> Void

    static func deleteProxy(_ proxy: Proxy, completion: @escaping (Bool) -> Void) {
        getConvosForProxy(uid: proxy.ownerId, key: proxy.key) { (convos) in
            guard let convos = convos else {
                completion(false)
                return
            }
            deleteProxy(proxy, convos: convos, completion: completion)
        }
    }

    static func deleteProxy(_ proxy: Proxy, convos: [Convo], completion: @escaping (Bool) -> Void) {
        let work = GroupWork()
        work.delete(Child.proxies, proxy.ownerId, proxy.key)
        work.delete(Child.proxyKeys, proxy.key)
        work.delete(Child.proxyOwners, proxy.key)
        work.delete(convos)
        work.deleteUnreadMessages(for: proxy)
        work.setReceiverDeletedProxy(for: convos)
        work.allDone {
            completion(work.result)
        }
    }

    static func getProxy(key: String, completion: @escaping (Proxy?) -> Void) {
        get(Child.proxyOwners, key.lowercased().noWhiteSpaces) { (data) in
            guard
                let data = data,
                let proxyOwner = ProxyOwner(data) else {
                    completion(nil)
                    return
            }
            getProxy(uid: proxyOwner.ownerId, key: proxyOwner.key, completion: completion)
        }
    }

    static func getProxy(uid: String, key: String, completion: @escaping (Proxy?) -> Void) {
        get(Child.proxies, uid, key) { (data) in
            guard let data = data else {
                completion(nil)
                return
            }
            completion(Proxy(data))
        }
    }

    static func makeProxy(uid: String,
                          name: String = ProxyService.makeRandomProxyName(),
                          maxNameSize: Int = Setting.maxNameSize,
                          currentProxyCount: Int,
                          maxProxyCount: Int = Setting.maxProxyCount,
                          maxAttemps: Int = Setting.maxMakeProxyAttempts,
                          completion: @escaping MakeProxyCallback) {
        guard name.count < maxNameSize else {
            completion(.failure(.inputTooLong))
            return
        }
        guard currentProxyCount < maxProxyCount else {
            completion(.failure(.proxyLimitReached))
            return
        }
        makeProxyHelper(uid: uid, name: name, maxAttempts: maxAttemps, completion: completion)
    }

    private static func makeProxyHelper(uid: String,
                                        name: String,
                                        attempts: Int = 0,
                                        maxAttempts: Int,
                                        completion: @escaping MakeProxyCallback) {
        guard let proxyKeysRef = makeReference(Child.proxyKeys) else {
            completion(.failure(.unknown))
            return
        }
        let proxyKey = name.lowercased()
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
                        let proxy = Proxy(icon: ProxyService.makeRandomIconName(), name: name, ownerId: uid)
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
                            makeProxyHelper(uid: uid, name: ProxyService.makeRandomProxyName(), attempts: attempts + 1, maxAttempts: maxAttempts, completion: completion)
                        } else {
                            completion(.failure(.unknown))
                        }
                    }
                }
            })
        }
    }

    private static func getProxyKeyCount(ref: DatabaseReference, key: String, completion: @escaping (UInt?) -> Void) {
        ref.queryOrdered(byChild: Child.key).queryEqual(toValue: key).observeSingleEvent(of: .value) { (data) in
            completion(data.childrenCount)
        }
    }

    static func setIcon(to icon: String, for proxy: Proxy, completion: @escaping (Bool) -> Void) {
        getConvosForProxy(uid: proxy.ownerId, key: proxy.key) { (convos) in
            guard let convos = convos else {
                completion(false)
                return
            }
            setIcon(to: icon, for: proxy, convos: convos, completion: completion)
        }
    }

    static func setIcon(to icon: String, for proxy: Proxy, convos: [Convo], completion: @escaping (Bool) -> Void) {
        let work = GroupWork()
        work.set(.icon(icon), for: proxy)
        work.setReceiverIcon(to: icon, for: convos)
        work.allDone {
            completion(work.result)
        }
    }

    static func setNickname(to nickname: String, for proxy: Proxy, completion: @escaping (ProxyError?) -> Void) {
        guard nickname.count < Setting.maxNameSize else {
            completion(.inputTooLong)
            return
        }
        getConvosForProxy(uid: proxy.ownerId, key: proxy.key) { (convos) in
            guard let convos = convos else {
                completion(.unknown)
                return
            }
            setNickname(to: nickname, for: proxy, convos: convos, completion: completion)
        }
    }

    static func setNickname(to nickname: String, for proxy: Proxy, convos: [Convo], completion: @escaping (ProxyError?) -> Void) {
        let work = GroupWork()
        work.set(.nickname(nickname), for: proxy)
        work.setSenderNickname(to: nickname, for: convos)
        work.allDone {
            completion(work.result ? nil : .unknown)
        }
    }

    private static func getConvosForProxy(uid: String, key: String, completion: @escaping ([Convo]?) -> Void) {
        get(Child.convos, uid) { (data) in
            completion(data?.toConvosArray(uid: uid, proxyKey: key))
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
        guard let ref = DB.makeReference(Child.userInfo, uid, Child.unreadMessages) else {
            completion(nil)
            return
        }
        ref.queryOrdered(byChild: Child.receiverProxyKey).queryEqual(toValue: key).observeSingleEvent(of: .value) { (data) in
            completion(data.asMessagesArray)
        }
    }

    func setReceiverDeletedProxy(for convos: [Convo]) {
        for convo in convos {
            set(.receiverDeletedProxy(true), for: convo, asSender: false)
        }
    }

    func setReceiverIcon(to icon: String, for convos: [Convo]) {
        for convo in convos {
            set(.receiverIcon(icon), for: convo, asSender: false)
        }
    }

    func setSenderNickname(to nickname: String, for convos: [Convo]) {
        for convo in convos {
            self.set(.senderNickname(nickname), for: convo, asSender: true)
        }
    }
}
