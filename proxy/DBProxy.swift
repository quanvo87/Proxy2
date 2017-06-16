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
        if Shared.shared.proxyInfoIsLoaded {
            completion?(true)
            return
        }
        loadProxyNameWords()
        loadIconNames()
        Shared.shared.proxyInfoLoaded.notify(queue: .main, execute: {
            if Shared.shared.proxyInfoIsLoaded {
                completion?(true)
                return
            }
            completion?(false)
        })

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
    static func createProxy(completion: @escaping (Result) -> Void) {
        loadProxyInfo { (success) in
            guard success else {
                completion(.failure(ProxyError.unknown))
                return
            }
            DB.get(Path.Proxies, Shared.shared.uid) { (snapshot) in
                guard snapshot?.childrenCount ?? 0 <= 50 else {
                    completion(.failure(ProxyError.proxyLimitReached))
                    return
                }
                Shared.shared.isCreatingProxy = true
                createProxyHelper(completion: completion)
            }
        }
    }

    private static func createProxyHelper(completion: @escaping (Result) -> Void) {
        guard let ref = DB.ref(Path.Proxies, Path.Key) else {
            completion(.failure(ProxyError.unknown))
            return
        }
        let autoId = ref.childByAutoId().key
        let name = makeProxyName()
        let key = name.lowercased()
        let globalProxy = GlobalProxy(key: key, ownerId: Shared.shared.uid).toJSON()

        DB.set(key, children: Path.Proxies, Path.Key, autoId) { (success) in
            guard success else {
                completion(.failure(ProxyError.unknown))
                return
            }
            ref.queryOrdered(byChild: Path.Key).queryEqual(toValue: key).observeSingleEvent(of: .value, with: { (snapshot) in
                DB.delete(Path.Proxies, Path.Key, autoId, completion: { (success) in
                    guard success else {
                        completion(.failure(ProxyError.unknown))
                        return
                    }

                    if !Shared.shared.isCreatingProxy {
                        return
                    }

                    if snapshot.childrenCount == 1 {
                        Shared.shared.isCreatingProxy = false

                        let userProxy = Proxy(name: name, ownerId: Shared.shared.uid, icon: getRandomIconName()).toJSON()

                        DB.set([(DB.path(Path.Proxies, Path.Name, key), true),
                                (DB.path(Path.Proxies, Path.Key, key), globalProxy),
                                (DB.path(Path.Proxies, Shared.shared.uid, key), userProxy)]) { (success) in
                                    completion(success ? .success(userProxy) : .failure(ProxyError.unknown))
                        }
                    } else {
                        createProxyHelper(completion: completion)
                    }
                })
            })
        }
    }

    private static func makeProxyName() -> String {
        let randomAdj = Int(arc4random_uniform(UInt32(Shared.shared.adjectives.count)))
        let randomNoun = Int(arc4random_uniform(UInt32(Shared.shared.nouns.count)))
        let adj = Shared.shared.adjectives[randomAdj].lowercased().capitalized
        let noun = Shared.shared.nouns[randomNoun].lowercased().capitalized
        let num = String(Int(arc4random_uniform(9)) + 1)
        return adj + noun + num
    }

    private static func getRandomIconName() -> String {
        let random = Int(arc4random_uniform(UInt32(Shared.shared.iconNames.count)))
        return Shared.shared.iconNames[random] + ".png"
    }

    static func cancelCreatingProxy() {
        Shared.shared.isCreatingProxy = false
    }
}

extension DBProxy {
    static func getProxy(key: String, completion: @escaping (Result) -> Void) {
        DB.get(Path.Proxies, Path.Key, key) { (snapshot) in
            guard let snapshot = snapshot else {
                completion(.failure(ProxyError.proxyNotFound))
                return
            }
            guard let globalProxy = GlobalProxy(snapshot.value as AnyObject) else {
                completion(.failure(ProxyError.unknown))
                return
            }
            getProxy(key: globalProxy.key, ownerId: globalProxy.ownerId, completion: completion)
        }
    }

    static func getProxy(key: String, ownerId: String, completion: @escaping (Result) -> Void) {
        DB.get(Path.Proxies, ownerId, key) { (snapshot) in
            guard let snapshot = snapshot else {
                completion(.failure(ProxyError.proxyNotFound))
                return
            }
            guard let proxy = Proxy(snapshot.value as AnyObject) else {
                completion(.failure(ProxyError.unknown))
                return
            }
            completion(.success(proxy))
        }
    }
}

extension DBProxy {
    static func setIcon(_ icon: String, forProxy proxy: Proxy, completion: @escaping (Success) -> Void) {
        DB.set(icon, children: Path.Proxies, proxy.ownerId, proxy.key, Path.Icon) { (success) in
            guard success else {
                completion(false)
                return
            }
            DBConvo.getConvos(forProxy: proxy, completion: { (convos) in
                guard let convos = convos else {
                    completion(false)
                    return
                }
                let group = DispatchGroup()
                for convo in convos {
                    group.enter()
                    DB.set([(DB.path(Path.Convos, convo.receiverId, convo.key, Path.Icon), icon),
                            (DB.path(Path.Convos, convo.receiverProxyKey, convo.key, Path.Icon), icon)], completion: { (success) in
                                guard success else {
                                    completion(false)
                                    return
                                }
                                group.leave()
                    })
                }
                group.notify(queue: .main, execute: {
                    completion(true)
                })
            })
        }
    }

    static func setNickname(_ nickname: String, forProxy proxy: Proxy, completion: @escaping (Success) -> Void) {
        DB.set(nickname, children: Path.Proxies, proxy.ownerId, proxy.key, Path.SenderNickname) { (success) in
            guard success else {
                completion(false)
                return
            }
            DBConvo.getConvos(forProxy: proxy, completion: { (convos) in
                guard let convos = convos else {
                    completion(false)
                    return
                }
                let group = DispatchGroup()
                for convo in convos {
                    group.enter()
                    DB.set([(DB.path(Path.Convos, convo.senderId, convo.key, Path.SenderNickname), nickname),
                            (DB.path(Path.Convos, convo.senderProxyKey, convo.key), nickname)], completion: { (success) in
                                guard success else {
                                    completion(false)
                                    return
                                }
                                group.leave()
                    })
                }
                group.notify(queue: .main, execute: {
                    completion(true)
                })
            })
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
        DB.delete(Path.Proxies, Path.Name, proxy.key) { (success) in
            guard success else {
                completion(false)
                return
            }
        }
        DB.delete(Path.Proxies, Path.Key, proxy.key) { (success) in
            guard success else {
                completion(false)
                return
            }
        }
        DB.delete(Path.Proxies, proxy.ownerId, proxy.key) { (success) in
            guard success else {
                completion(false)
                return
            }
        }
        DB.increment(-proxy.unread, children: Path.Unread, proxy.ownerId, Path.Unread) { (success) in
            guard success else {
                completion(false)
                return
            }
        }
        let convosDone = DispatchGroup()
        for convo in convos {
            convosDone.enter()
            let convoDone = DispatchGroup()
            for _ in 1...3 {
                convoDone.enter()
            }
            DB.delete(Path.Convos, convo.senderId, convo.key, completion: { (success) in
                guard success else {
                    completion(false)
                    return
                }
                convoDone.leave()
            })
            DB.delete(Path.Convos, convo.senderProxyKey, convo.key, completion: { (success) in
                guard success else {
                    completion(false)
                    return
                }
                convoDone.leave()
            })
            DB.set([(DB.path(Path.Convos, convo.receiverId, convo.key, Path.ReceiverDeletedProxy), true),
                    (DB.path(Path.Convos, convo.receiverProxyKey, convo.key, Path.ReceiverDeletedProxy), true)], completion: { (success) in
                        guard success else {
                            completion(false)
                            return
                        }
                        convoDone.leave()
            })
            convoDone.notify(queue: .main, execute: {
                convosDone.leave()
            })
        }
        convosDone.notify(queue: .main) { 
            completion(true)
        }
    }
}
