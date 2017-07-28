//
//  DBProxy.swift
//  proxy
//
//  Created by Quan Vo on 6/12/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

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
        let workKey = AsyncWorkGroupKey()
        workKey.decrementProxyCount(forOwnerOfProxy: proxy)
        workKey.decrementUnread(forOwnerOfProxy: proxy)
        workKey.deleteProxy(proxy)
        workKey.deleteProxyKey(forProxy: proxy)
        workKey.deleteProxyOwner(forProxy: proxy)
        workKey.deleteProxyConvos(forProxy: proxy)
        workKey.deleteUserConvosForProxy(userConvos: convos)
        workKey.setReceiverDeletedProxy(forReceiverInConvos: convos)
        workKey.notify {
            completion(workKey.workResult)
            workKey.finishWorkGroup()
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

        let key = name.lowercased()
        let proxyKey = [Path.Key: key]
        let autoId = proxyKeysRef.childByAutoId().key

        DB.set(proxyKey, at: Path.ProxyKeys, autoId) { (success) in
            guard success else {
                makeProxyDone(result: .failure(.unknown), completion: completion)
                return
            }
            proxyKeysRef.queryOrdered(byChild: Path.Key).queryEqual(toValue: key).observeSingleEvent(of: .value, with: { (data) in
                DB.delete(Path.ProxyKeys, autoId) { (success) in
                    guard success else {
                        makeProxyDone(result: .failure(.unknown), completion: completion)
                        return
                    }

                    guard Shared.shared.isCreatingProxy else {
                        return
                    }

                    if data.childrenCount == 1 {
                        let proxy = Proxy(name: name, ownerId: uid, icon: randomIconName)
                        let proxyOwner = ProxyOwner(key: key, ownerId: uid)

                        let workKey = AsyncWorkGroupKey()
                        workKey.incrementProxyCount(forUser: uid)
                        workKey.setProxy(proxy)
                        workKey.setProxyKey(proxyKey, key: key)
                        workKey.setProxyOwner(proxyOwner)
                        workKey.notify {
                            makeProxyDone(result: workKey.workResult ? .success(proxy) : .failure(.unknown), completion: completion)
                            workKey.finishWorkGroup()
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

    static func setIcon(_ icon: String, forProxy proxy: Proxy, completion: @escaping (Success) -> Void) {
        DBConvo.getConvos(forProxy: proxy, filtered: false) { (convos) in
            guard let convos = convos else {
                completion(false)
                return
            }
            setIcon(icon, forProxy: proxy, withConvos: convos, completion: completion)
        }
    }

    static func setIcon(_ icon: String, forProxy proxy: Proxy, withConvos convos: [Convo], completion: @escaping (Success) -> Void) {
        let workKey = AsyncWorkGroupKey()
        workKey.setIcon(icon, forProxy: proxy)
        workKey.setIcon(icon, forReceiverInConvos: convos)
        workKey.notify {
            completion(workKey.workResult)
            workKey.finishWorkGroup()
        }
    }

    static func setNickname(_ nickname: String, forProxy proxy: Proxy, completion: @escaping (Success) -> Void) {
        DBConvo.getConvos(forProxy: proxy, filtered: false) { (convos) in
            guard let convos = convos else {
                completion(false)
                return
            }
            setNickname(nickname, forProxy: proxy, withConvos: convos, completion: completion)
        }
    }

    static func setNickname(_ nickname: String, forProxy proxy: Proxy, withConvos convos: [Convo], completion: @escaping (Success) -> Void) {
        let workKey = AsyncWorkGroupKey()
        workKey.setNickname(nickname, forProxy: proxy)
        workKey.setNickname(nickname, forSenderInConvos: convos)
        workKey.notify {
            completion(workKey.workResult)
            workKey.finishWorkGroup()
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
    func decrementProxyCount(forOwnerOfProxy proxy: Proxy) {
        startWork()
        DB.increment(-1, at: Path.UserInfo, proxy.ownerId, Path.ProxyCount) { (success) in
            self.finishWork(withResult: success)
        }
    }

    func decrementUnread(forOwnerOfProxy proxy: Proxy) {
        startWork()
        DB.increment(-proxy.unread, at: Path.UserInfo, proxy.ownerId, Path.Unread) { (success) in
            self.finishWork(withResult: success)
        }
    }

    func deleteProxy(_ proxy: Proxy) {
        startWork()
        DB.delete(Path.Proxies, proxy.ownerId, proxy.key) { (success) in
            self.finishWork(withResult: success)
        }
    }

    func deleteProxyConvos(forProxy proxy: Proxy) {
        startWork()
        DB.delete(Path.Convos, proxy.key) { (success) in
            self.finishWork(withResult: success)
        }
    }

    func deleteProxyKey(forProxy proxy: Proxy) {
        startWork()
        DB.delete(Path.ProxyKeys, proxy.key) { (success) in
            self.finishWork(withResult: success)
        }
    }

    func deleteUserConvosForProxy(userConvos convos: [Convo]) {
        for convo in convos {
            deleteUserConvo(convo)
        }
    }

    func deleteProxyOwner(forProxy proxy: Proxy) {
        startWork()
        DB.delete(Path.ProxyOwners, proxy.key) { (success) in
            self.finishWork(withResult: success)
        }
    }

    func incrementProxyCount(forUser uid: String) {
        startWork()
        DB.increment(1, at: Path.UserInfo, uid, Path.ProxyCount) { (success) in
            self.finishWork(withResult: success)
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

    func setIcon(_ icon: String, forProxy proxy: Proxy) {
        startWork()
        DB.set(icon, at: Path.Proxies, proxy.ownerId, proxy.key, Path.Icon) { (success) in
            self.finishWork(withResult: success)
        }
    }

    func setIcon(_ icon: String, forReceiverInConvos convos: [Convo]) {
        for convo in convos {
            setIcon(icon, forReceiverInProxyConvo: convo)
            setIcon(icon, forReceiverInUserConvo: convo)
        }
    }

    func setIcon(_ icon: String, forReceiverInProxyConvo convo: Convo) {
        startWork()
        DB.set(icon, at: Path.Convos, convo.receiverProxyKey, convo.key, Path.Icon) { (success) in
            self.finishWork(withResult: success)
        }
    }

    func setIcon(_ icon: String, forReceiverInUserConvo convo: Convo) {
        startWork()
        DB.set(icon, at: Path.Convos, convo.receiverId, convo.key, Path.Icon) { (success) in
            self.finishWork(withResult: success)
        }
    }

    func setNickname(_ nickname: String, forProxy proxy: Proxy) {
        startWork()
        DB.set(nickname, at: Path.Proxies, proxy.ownerId, proxy.key, Path.Nickname) { (success) in
            self.finishWork(withResult: success)
        }
    }

    func setNickname(_ nickname: String, forSenderInConvos convos: [Convo]) {
        for convo in convos {
            setNickname(nickname, forSenderInProxyConvo: convo)
            setNickname(nickname, forSenderInUserConvo: convo)
        }
    }

    func setNickname(_ nickname: String, forSenderInProxyConvo convo: Convo) {
        startWork()
        DB.set(nickname, at: Path.Convos, convo.senderProxyKey, convo.key, Path.SenderNickname) { (success) in
            self.finishWork(withResult: success)
        }
    }

    func setNickname(_ nickname: String, forSenderInUserConvo convo: Convo) {
        startWork()
        DB.set(nickname, at: Path.Convos, convo.senderId, convo.key, Path.SenderNickname) { (success) in
            self.finishWork(withResult: success)
        }
    }

    func setProxy(_ proxy: Proxy) {
        startWork()
        DB.set(proxy.toJSON(), at: Path.Proxies, proxy.ownerId, proxy.key) { (success) in
            self.finishWork(withResult: success)
        }
    }

    func setProxyKey(_ proxyKey: [String: String], key: String) {
        startWork()
        DB.set(proxyKey, at: Path.ProxyKeys, key) { (success) in
            self.finishWork(withResult: success)
        }
    }

    func setProxyOwner(_ proxyOwner: ProxyOwner) {
        startWork()
        DB.set(proxyOwner.toJSON(), at: Path.ProxyOwners, proxyOwner.key) { (success) in
            self.finishWork(withResult: success)
        }
    }

    func setReceiverDeletedProxy(forReceiverInConvos convos: [Convo]) {
        for convo in convos {
            setReceiverDeletedProxy(forReceiverInProxyConvo: convo)
            setReceiverDeletedProxy(forReceiverInUserConvo: convo)
        }
    }

    func setReceiverDeletedProxy(forReceiverInProxyConvo convo: Convo) {
        startWork()
        DB.set(true, at: Path.Convos, convo.receiverId, convo.key, Path.ReceiverDeletedProxy) { (success) in
            self.finishWork(withResult: success)
        }
    }

    func setReceiverDeletedProxy(forReceiverInUserConvo convo: Convo) {
        startWork()
        DB.set(true, at: Path.Convos, convo.receiverProxyKey, convo.key, Path.ReceiverDeletedProxy) { (success) in
            self.finishWork(withResult: success)
        }
    }
}
