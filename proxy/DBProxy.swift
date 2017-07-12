//
//  DBProxy.swift
//  proxy
//
//  Created by Quan Vo on 6/12/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import FirebaseStorage
import FirebaseDatabase

struct DBProxy {}

extension DBProxy {
    static func loadProxyInfo(completion: ((Success) -> Void)? = nil) {
        if  !Shared.shared.adjectives.isEmpty &&
            !Shared.shared.nouns.isEmpty &&
            !Shared.shared.iconNames.isEmpty {
            completion?(true)
            return
        }
        let workKey = WorkKey()
        workKey.loadProxyNameWords()
        workKey.loadIconNames()
        workKey.notify() {
            completion?(workKey.workResult)
            workKey.finishWorkGroup()
        }
    }
}

private extension WorkKey {
    func loadProxyNameWords() {
        startWork()
        Storage.storage().reference(forURL: URLs.Storage + "/app").child("words.json").getData(maxSize: 1 * 1024 * 1024) { (data, error) in
            if  error == nil,
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []),
                let dictionary = json as? [String: Any],
                let adjectives = dictionary["adjectives"] as? [String],
                let nouns = dictionary["nouns"] as? [String] {
                Shared.shared.adjectives = adjectives
                Shared.shared.nouns = nouns
            }
            self.finishWork(withResult: !Shared.shared.adjectives.isEmpty && !Shared.shared.nouns.isEmpty)
        }
    }

    func loadIconNames() {
        startWork()
        Storage.storage().reference(forURL: URLs.Storage + "/app").child("iconNames.json").getData(maxSize: 1 * 1024 * 1024) { (data, error) in
            if  error == nil,
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []),
                let dictionary = json as? [String: Any],
                let iconsNames = dictionary["iconNames"] as? [String]  {
                    Shared.shared.iconNames = iconsNames
            }
            self.finishWork(withResult: !Shared.shared.iconNames.isEmpty)
        }
    }
}

extension DBProxy {
    typealias CreateProxyCallback = (Result<Proxy, ProxyError>) -> Void

    static func createProxy(withName specificName: String? = nil,
                            forUser uid: String = Shared.shared.uid,
                            completion: @escaping CreateProxyCallback) {
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
                createProxyHelper(withName: specificName, forUser: uid, completion: completion)
            }
        }
    }

    private static func createProxyHelper(withName specificName: String? = nil,
                                          forUser uid: String = Shared.shared.uid, 
                                          completion: @escaping CreateProxyCallback) {
        guard let proxyKeysRef = DB.ref(Path.ProxyKeys) else {
            createProxyFinished(result: .failure(.unknown), completion: completion)
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
                createProxyFinished(result: .failure(.unknown), completion: completion)
                return
            }
            proxyKeysRef.queryOrdered(byChild: Path.Key).queryEqual(toValue: key).observeSingleEvent(of: .value, with: { (snapshot) in
                DB.delete(Path.ProxyKeys, autoId) { (success) in
                    guard success else {
                        createProxyFinished(result: .failure(.unknown), completion: completion)
                        return
                    }

                    guard Shared.shared.isCreatingProxy else {
                        return
                    }

                    if snapshot.childrenCount == 1 {
                        let proxyOwner = ProxyOwner(key: key, ownerId: uid).toJSON()
                        let userProxy = Proxy(name: name, ownerId: uid, icon: randomIconName)

                        DB.set([DB.Transaction(set: proxyKey, at: Path.ProxyKeys, key),
                                DB.Transaction(set: proxyOwner, at: Path.ProxyOwners, key),
                                DB.Transaction(set: userProxy.toJSON(), at: Path.Proxies, uid, key)]) { (success) in
                                    guard success else {
                                        createProxyFinished(result: .failure(.unknown), completion: completion)
                                        return
                                    }

                                    DB.increment(1, at: Path.UserInfo, uid, Path.ProxyCount) { (success) in
                                        createProxyFinished(result: success ? .success(userProxy) : .failure(.unknown), completion: completion)
                                    }
                        }
                    } else {
                        if specificName == nil {
                            createProxyHelper(forUser: uid, completion: completion)
                        } else {
                            createProxyFinished(result: .failure(.unknown), completion: completion)
                        }
                    }
                }
            })
        }
    }

    private static func createProxyFinished(result: Result<Proxy, ProxyError>, completion: CreateProxyCallback) {
        Shared.shared.isCreatingProxy = false
        completion(result)
    }

    private static var randomProxyName: String {
        guard
            !Shared.shared.adjectives.isEmpty &&
            !Shared.shared.nouns.isEmpty else {
                return ""
        }
        let randomAdj = Int(arc4random_uniform(UInt32(Shared.shared.adjectives.count)))
        let randomNoun = Int(arc4random_uniform(UInt32(Shared.shared.nouns.count)))
        let adj = Shared.shared.adjectives[randomAdj].lowercased().capitalized
        let noun = Shared.shared.nouns[randomNoun].lowercased().capitalized
        let num = String(Int(arc4random_uniform(9)) + 1)
        return adj + noun + num
    }

    private static var randomIconName: String {
        guard !Shared.shared.iconNames.isEmpty else {
            return ""
        }
        let random = Int(arc4random_uniform(UInt32(Shared.shared.iconNames.count)))
        return Shared.shared.iconNames[random]
    }

    static func cancelCreatingProxy() {
        Shared.shared.isCreatingProxy = false
    }
}

extension DBProxy {
    static func getProxy(withKey key: String, completion: @escaping (Proxy?) -> Void) {
        DB.get(Path.ProxyOwners, key) { (snapshot) in
            guard let proxyOwner = ProxyOwner(snapshot?.value as AnyObject) else {
                completion(nil)
                return
            }
            getProxy(withKey: proxyOwner.key, belongingTo: proxyOwner.ownerId, completion: completion)
        }
    }

    static func getProxy(withKey key: String, belongingTo uid: String, completion: @escaping (Proxy?) -> Void) {
        DB.get(Path.Proxies, uid, key) { (snapshot) in
            completion(Proxy(snapshot?.value as AnyObject))
        }
    }

    static func getProxies(forUser uid: String, completion: @escaping ([Proxy]?) -> Void) {
        DB.get(Path.Proxies, uid) { (data) in
            completion(data?.toProxies())
        }
    }
}

extension DBProxy {
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
        let workKey = WorkKey()
        workKey.setIcon(icon, forProxy: proxy)
        workKey.setIcon(icon, forConvos: convos)
        workKey.notify {
            completion(workKey.workResult)
            workKey.finishWorkGroup()
        }
    }
}

private extension WorkKey {
    func setIcon(_ icon: String, forProxy proxy: Proxy) {
        startWork()
        DB.set(icon, at: Path.Proxies, proxy.ownerId, proxy.key, Path.Icon) { (success) in
            self.finishWork(withResult: success)
        }
    }

    func setIcon(_ icon: String, forConvos convos: [Convo]) {
        for convo in convos {
            setIcon(icon, forConvo: convo)
        }
    }

    private func setIcon(_ icon: String, forConvo convo: Convo) {
        startWork()
        DB.set([DB.Transaction(set: icon, at: Path.Convos, convo.receiverId, convo.key, Path.Icon),
                DB.Transaction(set: icon, at: Path.Convos, convo.receiverProxyKey, convo.key, Path.Icon)]) { (success) in
                    self.finishWork(withResult: success)
        }
    }
}

extension DBProxy {
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
        let workKey = WorkKey()
        workKey.setNickname(nickname, forProxy: proxy)
        workKey.setNickname(nickname, forConvos: convos)
        workKey.notify {
            completion(workKey.workResult)
            workKey.finishWorkGroup()
        }
    }
}

private extension WorkKey {
    func setNickname(_ nickname: String, forProxy proxy: Proxy) {
        startWork()
        DB.set(nickname, at: Path.Proxies, proxy.ownerId, proxy.key, Path.Nickname) { (success) in
            self.finishWork(withResult: success)
        }
    }

    func setNickname(_ nickname: String, forConvos convos: [Convo]) {
        for convo in convos {
            setNickname(nickname, forConvo: convo)
        }
    }

    private func setNickname(_ nickname: String, forConvo convo: Convo) {
        startWork()
        DB.set([DB.Transaction(set: nickname, at: Path.Convos, convo.senderId, convo.key, Path.SenderNickname),
                DB.Transaction(set: nickname, at: Path.Convos, convo.senderProxyKey, convo.key)]) { (success) in
                    self.finishWork(withResult: success)
        }
    }
}

extension DBProxy {
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
        let workKey = WorkKey()
        workKey.deleteProxyKey(forProxy: proxy)
        workKey.deleteProxyOwner(forProxy: proxy)
        workKey.deleteProxy(proxy)
        workKey.deleteConvos(forProxy: proxy)
        workKey.deleteConvosForUser(convos: convos)
        workKey.adjustUserUnread(fromProxy: proxy)
        workKey.notify {
            decrementProxyCount(forUser: proxy.ownerId) { (success) in
                completion(workKey.setWorkResult(success))
                workKey.finishWorkGroup()
            }
        }
    }

    private static func decrementProxyCount(forUser uid: String, completion: @escaping (Success) -> Void) {
        DB.increment(-1, at: Path.UserInfo, uid, Path.ProxyCount) { (success) in
            completion(success)
        }
    }
}

private extension WorkKey {
    func deleteProxyKey(forProxy proxy: Proxy) {
        startWork()
        DB.delete(Path.ProxyKeys, proxy.key) { (success) in
            self.finishWork(withResult: success)
        }
    }

    func deleteProxyOwner(forProxy proxy: Proxy) {
        startWork()
        DB.delete(Path.ProxyOwners, proxy.key) { (success) in
            self.finishWork(withResult: success)
        }
    }

    func deleteProxy(_ proxy: Proxy) {
        startWork()
        DB.delete(Path.Proxies, proxy.ownerId, proxy.key) { (success) in
            self.finishWork(withResult: success)
        }
    }

    func deleteConvos(forProxy proxy: Proxy) {
        startWork()
        DB.delete(Path.Convos, proxy.key) { (success) in
            self.finishWork(withResult: success)
        }
    }

    func deleteConvosForUser(convos: [Convo]) {
        for convo in convos {
            startWork()

            let convoWorkKey = WorkKey()
            convoWorkKey.deleteConvoForUser(convo: convo)
            convoWorkKey.setReceiverDeletedProxyForConvo(convo)
            convoWorkKey.notify {
                self.finishWork(withResult: convoWorkKey.workResult)
                convoWorkKey.finishWorkGroup()
            }
        }
    }

    private func deleteConvoForUser(convo: Convo) {
        startWork()
        DB.delete(Path.Convos, convo.senderId, convo.key) { (success) in
            self.finishWork(withResult: success)
        }
    }

    func setReceiverDeletedProxyForConvo(_ convo: Convo) {
        startWork()
        DB.set([DB.Transaction(set: true, at: Path.Convos, convo.receiverId, convo.key, Path.ReceiverDeletedProxy),
                DB.Transaction(set: true, at: Path.Convos, convo.receiverProxyKey, convo.key, Path.ReceiverDeletedProxy)]) { (success) in
                    self.finishWork(withResult: success)
        }
    }

    func adjustUserUnread(fromProxy proxy: Proxy) {
        startWork()
        DB.increment(-proxy.unread, at: Path.UserInfo, proxy.ownerId, Path.Unread) { (success) in
            self.finishWork(withResult: success)
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
