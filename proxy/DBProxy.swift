//
//  DBProxy.swift
//  proxy
//
//  Created by Quan Vo on 6/12/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import FirebaseStorage

struct DBProxy {}

extension DBProxy {
    static func loadProxyInfo(completion: ((Success) -> Void)? = nil) {
        if  Shared.shared.adjectives.isEmpty ||
            Shared.shared.nouns.isEmpty ||
            Shared.shared.iconNames.isEmpty
        {
            loadProxyNameWords()
            loadIconNames()
            Shared.shared.proxyInfoLoaded.notify(queue: DispatchQueue.main, execute: {
                if  Shared.shared.adjectives.isEmpty ||
                    Shared.shared.nouns.isEmpty ||
                    Shared.shared.iconNames.isEmpty {
                    completion?(false)
                    return
                }
                completion?(true)
            })
        } else {
            completion?(true)
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
                    DB.assertionFailure(error)
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
                    DB.assertionFailure(error)
                    return
            }
            Shared.shared.iconNames = iconsNames
        }
    }
}

extension DBProxy {
    static func createProxy(completion: @escaping (Result) -> Void) {
        loadProxyInfo { (success) in
            guard success else {
                completion(Result.failure(ProxyError.unknown))
                assertionFailure()
                return
            }
            DB.get(Path.Proxies, Shared.shared.uid) { (snapshot) in
                guard let snapshot = snapshot else {
                    completion(Result.failure(ProxyError.unknown))
                    assertionFailure()
                    return
                }
                guard snapshot.childrenCount <= 50 else {
                    completion(Result.failure(ProxyError.proxyLimitReached))
                    return
                }
                Shared.shared.isCreatingProxy = true
                createProxyHelper(completion: completion)
            }
        }
    }

    private static func createProxyHelper(completion: @escaping (Result) -> Void) {
        guard let ref = DB.ref(Path.Proxies, Path.Key) else {
            completion(Result.failure(ProxyError.unknown))
            assertionFailure()
            return
        }
        let autoId = ref.childByAutoId().key
        let name = makeRandomProxyName()
        let key = name.lowercased()
        let globalProxy = GlobalProxy(key: key, ownerId: Shared.shared.uid).toJSON()

        DB.set(key, children: Path.Proxies, Path.Key, autoId) { (success) in
            guard success else {
                completion(Result.failure(ProxyError.unknown))
                assertionFailure()
                return
            }
            ref.queryOrdered(byChild: Path.Key).queryEqual(toValue: key).observeSingleEvent(of: .value, with: { (snapshot) in
                DB.delete(Path.Proxies, Path.Key, autoId, completion: { (success) in
                    guard success else {
                        completion(Result.failure(ProxyError.unknown))
                        assertionFailure()
                        return
                    }
                })

                if !Shared.shared.isCreatingProxy {
                    return
                }

                if snapshot.childrenCount == 1 {
                    Shared.shared.isCreatingProxy = false

                    let userProxy = Proxy(name: name, ownerId: Shared.shared.uid, icon: getRandomIconName()).toJSON()

                    DB.set([DB.path(Path.Proxies, Path.Name, key): true,
                            DB.path(Path.Proxies, Path.Key, key): globalProxy,
                            DB.path(Path.Proxies, Shared.shared.uid, key): userProxy], completion: { (success) in
                                guard success else {
                                    completion(Result.failure(ProxyError.unknown))
                                    assertionFailure()
                                    return
                                }
                                completion(Result.success(userProxy))
                    })
                } else {
                    createProxyHelper(completion: completion)
                }
            })
        }
    }

    private static func makeRandomProxyName() -> String {
        let adjsCount = UInt32(Shared.shared.adjectives.count)
        let nounsCount = UInt32(Shared.shared.nouns.count)
        let adj = Shared.shared.adjectives[Int(arc4random_uniform(adjsCount))].lowercased().capitalized
        let noun = Shared.shared.nouns[Int(arc4random_uniform(nounsCount))].lowercased().capitalized
        let num = String(Int(arc4random_uniform(9)) + 1)
        return adj + noun + num
    }

    private static func getRandomIconName() -> String {
        let count = UInt32(Shared.shared.iconNames.count)
        return Shared.shared.iconNames[Int(arc4random_uniform(count))] + ".png"
    }

    static func cancelCreatingProxy() {
        Shared.shared.isCreatingProxy = false
    }
}

extension DBProxy {
    static func getProxy(key: String, completion: @escaping (Result) -> Void) {
        DB.get(Path.Proxies, Path.Key, key) { (snapshot) in
            guard let snapshot = snapshot else {
                completion(Result.failure(ProxyError.proxyNotFound))
                return
            }
            guard let globalProxy = GlobalProxy(snapshot.value as AnyObject) else {
                completion(Result.failure(ProxyError.unknown))
                assertionFailure()
                return
            }
            getProxy(key: globalProxy.key, ownerId: globalProxy.ownerId, completion: completion)
        }
    }

    static func getProxy(key: String, ownerId: String, completion: @escaping (Result) -> Void) {
        DB.get(Path.Proxies, ownerId, key) { (snapshot) in
            guard
                let snapshot = snapshot,
                let proxy = Proxy(snapshot.value as AnyObject) else {
                    completion(Result.failure(ProxyError.unknown))
                    assertionFailure()
                    return
            }
            completion(Result.success(proxy))
        }
    }
}

extension DBProxy {
    static func setNickname(_ nickname: String, forProxy proxy: Proxy, completion: (Success) -> Void) {
        
    }

    static func deleteProxy(_ proxy: Proxy, completion: (Success) -> Void) {

    }

    static func deleteProxy(_ proxy: Proxy, withConvos convos: [Convo], completion: (Success) -> Void) {

    }
}
