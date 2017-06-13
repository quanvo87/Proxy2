//
//  DBProxy.swift
//  proxy
//
//  Created by Quan Vo on 6/12/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import FirebaseStorage

struct DBProxy {
    static func loadProxyInfo() {
        Shared.shared.proxyInfoLoaded.enter()
        Shared.shared.proxyInfoLoaded.enter()
        loadProxyNameWords()
        loadIconNames()
    }

    static func loadProxyNameWords() {
        Storage.storage().reference(forURL: URLs.Storage + "/app").child("words.json").getData(maxSize: 1 * 1024 * 1024) { (data, error) in
            guard
                error == nil,
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []),
                let dictionary = json as? [String: Any],
                let adjectives = dictionary["adjectives"] as? [String],
                let nouns = dictionary["nouns"] as? [String]
                else {
                    loadProxyNameWords()
                    return
            }
            Shared.shared.adjectives = adjectives
            Shared.shared.nouns = nouns
            Shared.shared.proxyInfoLoaded.leave()
        }
    }

    static func loadIconNames() {
        Storage.storage().reference(forURL: URLs.Storage + "/app").child("iconNames.json").getData(maxSize: 1 * 1024 * 1024) { (data, error) in
            guard
                error == nil,
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []),
                let dictionary = json as? [String: Any],
                let iconsNames = dictionary["iconNames"] as? [String] else {
                    loadIconNames()
                    return
            }
            Shared.shared.iconNames = iconsNames
            Shared.shared.proxyInfoLoaded.leave()
        }
    }

    static func createProxy(completion: @escaping (Result) -> Void) {
        Shared.shared.proxyInfoLoaded.notify(queue: DispatchQueue.main) {
            DB.get(Path.Proxies, Shared.shared.uid) { (snapshot) in
                guard let snapshot = snapshot else {
                    completion(Result.failure(ProxyError.failedToCreateProxy))
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

    static func createProxyHelper(completion: @escaping (Result) -> Void) {
        guard let ref = DB.ref(Path.Proxies, Path.Names) else {
            completion(Result.failure(ProxyError.failedToCreateProxy))
            return
        }
        let autoId = ref.childByAutoId().key
        let name = makeRandomProxyName()
        let key = name.lowercased()
        let globalProxy = GlobalProxy(key: key, owner: Shared.shared.uid).toJSON()

        DB.set(globalProxy, pathNodes: Path.Proxies, Path.Names, autoId) { (success) in
            guard success else {
                completion(Result.failure(ProxyError.failedToCreateProxy))
                return
            }
            ref.queryOrdered(byChild: Path.Key).queryEqual(toValue: key).observeSingleEvent(of: .value, with: { (snapshot) in
                DB.delete(Path.Proxies, Path.Names, autoId, completion: { (success) in
                    assert(success)
                })

                if !Shared.shared.isCreatingProxy {
                    return
                }

                if snapshot.childrenCount == 1 {
                    Shared.shared.isCreatingProxy = false

                    let userProxy = Proxy(name: name, ownerId: Shared.shared.uid, icon: getRandomIconName()).toJSON()

                    DB.set([DB.path(Path.Proxies, Path.Names, key): globalProxy,
                            DB.path(Path.Proxies, Shared.shared.uid, key): userProxy], completion: { (success) in
                                completion(success ?
                                    Result.success(userProxy) :
                                    Result.failure(ProxyError.failedToCreateProxy))
                    })
                } else {
                    createProxyHelper(completion: completion)
                }
            })
        }
    }

    static func makeRandomProxyName() -> String {
        let adjsCount = UInt32(Shared.shared.adjectives.count)
        let nounsCount = UInt32(Shared.shared.nouns.count)
        let adj = Shared.shared.adjectives[Int(arc4random_uniform(adjsCount))].lowercased().capitalized
        let noun = Shared.shared.nouns[Int(arc4random_uniform(nounsCount))].lowercased().capitalized
        let num = String(Int(arc4random_uniform(9)) + 1)
        return adj + noun + num
    }

    static func getRandomIconName() -> String {
        let count = UInt32(Shared.shared.iconNames.count)
        return Shared.shared.iconNames[Int(arc4random_uniform(count))]
    }
}
