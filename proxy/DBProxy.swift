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
        if Shared.shared.proxyInfoIsLoaded {
            completion?(true)
            return
        }
        loadProxyNameWords()
        loadIconNames()
        Shared.shared.proxyInfoLoaded.notify(queue: .main) {
            if  !Shared.shared.adjectives.isEmpty &&
                !Shared.shared.nouns.isEmpty &&
                !Shared.shared.iconNames.isEmpty {
                Shared.shared.proxyInfoIsLoaded = true
                completion?(true)
                return
            }
            completion?(false)
        }
    }

    private static func loadProxyNameWords() {
        Shared.shared.proxyInfoLoaded.enter()
        Storage.storage().reference(forURL: URLs.Storage + "/app").child("words.json").getData(maxSize: 1 * 1024 * 1024) { (data, error) in
            defer {
                Shared.shared.proxyInfoLoaded.leave()
            }
            guard
                error == nil,
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []),
                let dictionary = json as? [String: Any],
                let adjectives = dictionary["adjectives"] as? [String],
                let nouns = dictionary["nouns"] as? [String] else {
                    return
            }
            Shared.shared.adjectives = adjectives
            Shared.shared.nouns = nouns
        }
    }

    private static func loadIconNames() {
        Shared.shared.proxyInfoLoaded.enter()
        Storage.storage().reference(forURL: URLs.Storage + "/app").child("iconNames.json").getData(maxSize: 1 * 1024 * 1024) { (data, error) in
            defer {
                Shared.shared.proxyInfoLoaded.leave()
            }
            guard
                error == nil,
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []),
                let dictionary = json as? [String: Any],
                let iconsNames = dictionary["iconNames"] as? [String] else {
                    return
            }
            Shared.shared.iconNames = iconsNames
        }
    }
}

extension DBProxy {
    typealias CreateProxyCallback = (Result<Proxy, ProxyError>) -> Void

    static func createProxy(randomProxyName: String? = nil,
                            completion: @escaping CreateProxyCallback) {
        loadProxyInfo { (success) in
            guard success else {
                completion(.failure(.unknown))
                return
            }
            DB.get(Path.UserInfo, Shared.shared.uid, Path.ProxyCount) { (data) in
                guard data?.value as? Int ?? 0 <= Settings.MaxAllowedProxies else {
                    completion(.failure(.proxyLimitReached))
                    return
                }
                Shared.shared.isCreatingProxy = true
                createProxyHelper(randomProxyName: randomProxyName,
                                  completion: completion)
            }
        }
    }

    private static func createProxyHelper(randomProxyName: String? = nil,
                                          completion: @escaping CreateProxyCallback) {
        guard let proxyKeysRef = DB.ref(DB.Path(Path.ProxyKeys)) else {
            createProxyFinished(result: .failure(.unknown),
                                completion: completion)
            return
        }

        let name: String

        if let randomProxyName = randomProxyName {
            name = randomProxyName
        } else {
            name = DBProxy.randomProxyName
        }

        let key = name.lowercased()
        let proxyKey = [Path.Key: key]
        let autoId = proxyKeysRef.childByAutoId().key

        DB.set(proxyKey, at: Path.ProxyKeys, autoId) { (success) in
            guard success else {
                createProxyFinished(result: .failure(.unknown),
                                    completion: completion)
                return
            }
            proxyKeysRef.queryOrdered(byChild: Path.Key).queryEqual(toValue: key).observeSingleEvent(of: .value, with: { (snapshot) in
                DB.delete(Path.ProxyKeys, autoId) { (success) in
                    guard success else {
                        createProxyFinished(result: .failure(.unknown),
                                            completion: completion)
                        return
                    }

                    guard Shared.shared.isCreatingProxy else {
                        return
                    }

                    if snapshot.childrenCount == 1 {
                        let proxyOwner = ProxyOwner(key: key, ownerId: Shared.shared.uid).toJSON()
                        let userProxy = Proxy(name: name, ownerId: Shared.shared.uid, icon: randomIconName)

                        DB.set([DB.Transaction(set: proxyKey, at: Path.ProxyKeys, key),
                                DB.Transaction(set: proxyOwner, at: Path.ProxyOwners, key),
                                DB.Transaction(set: userProxy.toJSON(), at: Path.Proxies, Shared.shared.uid, key)]) { (success) in
                                    guard success else {
                                        createProxyFinished(result: .failure(.unknown),
                                                            completion: completion)
                                        return
                                    }

                                    DB.increment(1, at: Path.UserInfo, Shared.shared.uid, Path.ProxyCount) { (success) in
                                        createProxyFinished(result: success ? .success(userProxy) : .failure(.unknown),
                                                            completion: completion)
                                    }
                        }
                    } else {
                        if randomProxyName == nil {
                            createProxyHelper(completion: completion)
                        } else {
                            createProxyFinished(result: .failure(.unknown),
                                                completion: completion)
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
        guard Shared.shared.proxyInfoIsLoaded else {
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
        guard Shared.shared.proxyInfoIsLoaded else {
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
    static func getProxy(key: String, completion: @escaping (Proxy?) -> Void) {
        DB.get(Path.ProxyOwners, key) { (snapshot) in
            guard let proxyOwner = ProxyOwner(snapshot?.value as AnyObject) else {
                completion(nil)
                return
            }
            getProxy(key: proxyOwner.key, ownerId: proxyOwner.ownerId, completion: completion)
        }
    }

    static func getProxy(key: String, ownerId: String, completion: @escaping (Proxy?) -> Void) {
        DB.get(Path.Proxies, ownerId, key) { (snapshot) in
            guard let proxy = Proxy(snapshot?.value as AnyObject) else {
                completion(nil)
                return
            }
            completion(proxy)
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
        var allSuccess = true

        let setIconDone = DispatchGroup()
        for _ in 1...2 {
            setIconDone.enter()
        }

        DB.set(icon, at: Path.Proxies, proxy.ownerId, proxy.key, Path.Icon) { (success) in
            allSuccess &= success
            setIconDone.leave()
        }

        DBConvo.getConvos(forProxy: proxy, filtered: false) { (convos) in
            guard let convos = convos else {
                completion(false)
                return
            }

            let setIconForConvoDone = DispatchGroup()

            for convo in convos {
                setIconForConvoDone.enter()
                DB.set([DB.Transaction(set: icon, at: Path.Convos, convo.receiverId, convo.key, Path.Icon),
                        DB.Transaction(set: icon, at: Path.Convos, convo.receiverProxyKey, convo.key, Path.Icon)]) { (success) in
                            allSuccess &= success
                            setIconForConvoDone.leave()
                }
            }

            setIconForConvoDone.notify(queue: .main) {
                setIconDone.leave()
            }
        }

        setIconDone.notify(queue: .main) {
            completion(allSuccess)
        }
    }

    static func setNickname(_ nickname: String, forProxy proxy: Proxy, completion: @escaping (Success) -> Void) {
        var allSuccess = true

        let setNicknameDone = DispatchGroup()
        for _ in 1...2 {
            setNicknameDone.enter()
        }

        DB.set(nickname, at: Path.Proxies, proxy.ownerId, proxy.key, Path.Nickname) { (success) in
            allSuccess &= success
            setNicknameDone.leave()
        }

        DBConvo.getConvos(forProxy: proxy, filtered: false) { (convos) in
            guard let convos = convos else {
                completion(false)
                return
            }

            let setNicknameForConvoDone = DispatchGroup()

            for convo in convos {
                setNicknameForConvoDone.enter()
                DB.set([DB.Transaction(set: nickname, at: Path.Convos, convo.senderId, convo.key, Path.SenderNickname),
                        DB.Transaction(set: nickname, at: Path.Convos, convo.senderProxyKey, convo.key)]) { (success) in
                            allSuccess &= success
                            setNicknameForConvoDone.leave()
                }
            }

            setNicknameForConvoDone.notify(queue: .main) {
                setNicknameDone.leave()
            }
        }

        setNicknameDone.notify(queue: .main) {
            completion(allSuccess)
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
        let workKey = Shared.startWorkGroup()

        deleteProxyKey(proxyKey: proxy.key, workKey: workKey)
        deleteProxyOwner(proxyKey: proxy.key, workKey: workKey)
        deleteProxy(proxyOwnerId: proxy.ownerId, proxyKey: proxy.key, workKey: workKey)
        deleteProxyConvos(proxyKey: proxy.key, workKey: workKey)
        deleteUserConvos(convos: convos, workKey: workKey)
        adjustUserUnread(proxyUnread: proxy.unread, proxyOwnerId: proxy.ownerId, workKey: workKey)

        Shared.shared.workGroup[workKey]?.notify(queue: .main) {
            decrementUserProxyCount(uid: proxy.ownerId) { (success) in
                completion(Shared.setWorkResult(success, workKey: workKey))
                Shared.finishWorkGroup(workKey: workKey)
            }
        }
    }

    private static func deleteProxyKey(proxyKey: String, workKey: String) {
        Shared.startWork(workKey)
        DB.delete(Path.ProxyKeys, proxyKey) { (success) in
            Shared.finishWorkWithResult(success, workKey: workKey)
        }
    }

    private static func deleteProxyOwner(proxyKey: String, workKey: String) {
        Shared.startWork(workKey)
        DB.delete(Path.ProxyOwners, proxyKey) { (success) in
            Shared.finishWorkWithResult(success, workKey: workKey)
        }
    }

    private static func deleteProxy(proxyOwnerId: String, proxyKey: String, workKey: String) {
        Shared.startWork(workKey)
        DB.delete(Path.Proxies, proxyOwnerId, proxyKey) { (success) in
            Shared.finishWorkWithResult(success, workKey: workKey)
        }
    }

    private static func deleteProxyConvos(proxyKey: String, workKey: String) {
        Shared.startWork(workKey)
        DB.delete(Path.Convos, proxyKey) { (success) in
            Shared.finishWorkWithResult(success, workKey: workKey)
        }
    }

    private static func deleteUserConvos(convos: [Convo], workKey: String) {
        for convo in convos {
            Shared.startWork(workKey)

            let convoWorkKey = Shared.startWorkGroup()

            deleteUserConvo(convoSenderId: convo.senderId, convoKey: convo.key, workKey: convoWorkKey)
            setReceiverDeletedProxyForConvo(convoKey: convo.key,
                                            convoReceiverId: convo.receiverId,
                                            convoReceiverProxyKey: convo.receiverProxyKey,
                                            workKey: convoWorkKey)

            Shared.shared.workGroup[convoWorkKey]?.notify(queue: .main) {
                Shared.finishWorkWithResult(Shared.shared.workResult[convoWorkKey] ?? false, workKey: workKey)
                Shared.finishWorkGroup(workKey: convoWorkKey)
            }
        }
    }

    private static func deleteUserConvo(convoSenderId: String, convoKey: String, workKey: String) {
        Shared.startWork(workKey)
        DB.delete(Path.Convos, convoSenderId, convoKey) { (success) in
            Shared.finishWorkWithResult(success, workKey: workKey)
        }
    }

    private static func setReceiverDeletedProxyForConvo(convoKey: String,
                                                        convoReceiverId: String,
                                                        convoReceiverProxyKey: String,
                                                        workKey: String) {
        Shared.startWork(workKey)
        DB.set([DB.Transaction(set: true, at: Path.Convos, convoReceiverId, convoKey, Path.ReceiverDeletedProxy),
                DB.Transaction(set: true, at: Path.Convos, convoReceiverProxyKey, convoKey, Path.ReceiverDeletedProxy)]) { (success) in
                    Shared.finishWorkWithResult(success, workKey: workKey)
        }
    }

    private static func adjustUserUnread(proxyUnread: Int, proxyOwnerId: String, workKey: String) {
        Shared.startWork(workKey)
        DB.increment(-proxyUnread, at: Path.UserInfo, proxyOwnerId, Path.Unread) { (success) in
            Shared.finishWorkWithResult(success, workKey: workKey)
        }
    }

    private static func decrementUserProxyCount(uid: String, completion: @escaping (Success) -> Void) {
        DB.increment(-1, at: Path.UserInfo, Shared.shared.uid, Path.ProxyCount) { (success) in
            completion(success)
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
