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
    static func createProxy(randomProxyName: String = DBProxy.randomProxyName,
                            retry: Bool = true,
                            completion: @escaping (Result<Proxy, ProxyError>) -> Void) {
        loadProxyInfo { (success) in
            guard success else {
                completion(.failure(.unknown))
                return
            }
            DB.get(Path.Proxies, Shared.shared.uid) { (snapshot) in
                guard snapshot?.childrenCount ?? 0 <= Settings.MaxAllowedProxies else {
                    completion(.failure(.proxyLimitReached))
                    return
                }
                Shared.shared.isCreatingProxy = true
                createProxyHelper(randomProxyName: randomProxyName,
                                  retry: retry,
                                  completion: completion)
            }
        }
    }

    private static func createProxyHelper(randomProxyName: String = DBProxy.randomProxyName,
                                          retry: Bool = true,
                                          completion: @escaping (Result<Proxy, ProxyError>) -> Void) {
        guard
            let proxyKeysRef = DB.ref(Path.ProxyKeys) else {
                Shared.shared.isCreatingProxy = false
                completion(.failure(.unknown))
                return
        }
        let autoId = proxyKeysRef.childByAutoId().key
        let name = randomProxyName
        let key = name.lowercased()
        let proxyKey = [Path.Key: key]

        DB.set(proxyKey, children: Path.ProxyKeys, autoId) { (success) in
            guard success else {
                Shared.shared.isCreatingProxy = false
                completion(.failure(.unknown))
                return
            }
            proxyKeysRef.queryOrdered(byChild: Path.Key).queryEqual(toValue: key).observeSingleEvent(of: .value, with: { (snapshot) in
                DB.delete(Path.ProxyKeys, autoId) { (success) in
                    guard success else {
                        Shared.shared.isCreatingProxy = false
                        completion(.failure(.unknown))
                        return
                    }

                    guard Shared.shared.isCreatingProxy else {
                        return
                    }

                    if snapshot.childrenCount == 1 {
                        Shared.shared.isCreatingProxy = false

                        let proxyOwner = ProxyOwner(key: key, ownerId: Shared.shared.uid).toJSON()
                        let userProxy = Proxy(name: name, ownerId: Shared.shared.uid, icon: randomIconName)

                        DB.set([(DB.path(Path.ProxyKeys, key), proxyKey),
                                (DB.path(Path.ProxyOwners, key), proxyOwner),
                                (DB.path(Path.Proxies, Shared.shared.uid, key), userProxy.toJSON())]) { (success) in
                                    completion(success ? .success(userProxy) : .failure(.unknown))
                        }
                    } else {
                        if retry {
                            createProxyHelper(randomProxyName: randomProxyName,
                                              completion: completion)
                        } else {
                            completion(.failure(.unknown))
                        }
                    }
                }
            })
        }
    }

    private static var randomProxyName: String {
        guard Shared.shared.proxyInfoIsLoaded else {
            return "proxy info not loaded"
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
            return "proxy info not loaded"
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
            guard
                let snapshot = snapshot,
                let proxyOwner = ProxyOwner(snapshot.value as AnyObject) else {
                    completion(nil)
                    return
            }
            getProxy(key: proxyOwner.key, ownerId: proxyOwner.ownerId, completion: completion)
        }
    }

    static func getProxy(key: String, ownerId: String, completion: @escaping (Proxy?) -> Void) {
        DB.get(Path.Proxies, ownerId, key) { (snapshot) in
            guard
                let snapshot = snapshot,
                let proxy = Proxy(snapshot.value as AnyObject) else {
                    completion(nil)
                    return
            }
            completion(proxy)
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

        DB.set(icon, children: Path.Proxies, proxy.ownerId, proxy.key, Path.Icon) { (success) in
            allSuccess &= success
            setIconDone.leave()
        }

        DBConvo.getConvos(forProxy: proxy) { (convos) in
            guard let convos = convos else {
                completion(false)
                return
            }

            let setIconForConvoDone = DispatchGroup()

            for convo in convos {
                setIconForConvoDone.enter()
                DB.set([(DB.path(Path.Convos, convo.receiverId, convo.key, Path.Icon), icon),
                        (DB.path(Path.Convos, convo.receiverProxyKey, convo.key, Path.Icon), icon)]) { (success) in
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

        DB.set(nickname, children: Path.Proxies, proxy.ownerId, proxy.key, Path.Nickname) { (success) in
            allSuccess &= success
            setNicknameDone.leave()
        }

        DBConvo.getConvos(forProxy: proxy) { (convos) in
            guard let convos = convos else {
                completion(false)
                return
            }

            let setNicknameForConvoDone = DispatchGroup()

            for convo in convos {
                setNicknameForConvoDone.enter()
                DB.set([(DB.path(Path.Convos, convo.senderId, convo.key, Path.SenderNickname), nickname),
                        (DB.path(Path.Convos, convo.senderProxyKey, convo.key), nickname)]) { (success) in
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

    static func deleteProxy(_ proxy: Proxy, completion: @escaping (Success) -> Void) {
        DBConvo.getConvos(forProxy: proxy) { (convos) in
            guard let convos = convos else {
                completion(false)
                return
            }
            deleteProxy(proxy, withConvos: convos, completion: completion)
        }
    }

    static func deleteProxy(_ proxy: Proxy, withConvos convos: [Convo], completion: @escaping (Success) -> Void) {
        DBProxy.getProxy(key: proxy.key, ownerId: proxy.ownerId) { (proxy) in
            guard let proxy = proxy else {
                completion(false)
                return
            }
            
            var allSuccess = true

            let deleteFinished = DispatchGroup()

            for _ in 1...4 {
                deleteFinished.enter()
            }

            DB.delete(Path.ProxyKeys, proxy.key) { (success) in
                allSuccess &= success
                deleteFinished.leave()
            }

            DB.delete(Path.ProxyOwners, proxy.key) { (success) in
                allSuccess &= success
                deleteFinished.leave()
            }

            DB.delete(Path.Proxies, proxy.ownerId, proxy.key) { (success) in
                allSuccess &= success
                deleteFinished.leave()
            }

            DB.increment(-proxy.unread, children: Path.Unread, proxy.ownerId, Path.Unread) { (success) in
                allSuccess &= success
                deleteFinished.leave()
            }

            for convo in convos {
                deleteFinished.enter()

                let deleteConvoFinished = DispatchGroup()

                for _ in 1...3 {
                    deleteConvoFinished.enter()
                }

                DB.delete(Path.Convos, convo.senderId, convo.key) { (success) in
                    allSuccess &= success
                    deleteConvoFinished.leave()
                }

                DB.delete(Path.Convos, convo.senderProxyKey, convo.key) { (success) in
                    allSuccess &= success
                    deleteConvoFinished.leave()
                }

                DB.set([(DB.path(Path.Convos, convo.receiverId, convo.key, Path.ReceiverDeletedProxy), true),
                        (DB.path(Path.Convos, convo.receiverProxyKey, convo.key, Path.ReceiverDeletedProxy), true)]) { (success) in
                            allSuccess &= success
                            deleteConvoFinished.leave()
                }

                deleteConvoFinished.notify(queue: .main) {
                    deleteFinished.leave()
                }
            }

            deleteFinished.notify(queue: .main) {
                completion(allSuccess)
            }
        }
    }
}

extension DataSnapshot {
    func toProxies() -> [Proxy] {
        var proxies = [Proxy]()
        for child in self.children {
            if  let snapshot = child as? DataSnapshot,
                let proxy = Proxy(snapshot.value as AnyObject) {
                proxies.append(proxy)
            }
        }
        return proxies
    }
}
