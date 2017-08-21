import FirebaseDatabase

struct DBConvo {
    static func deleteConvo(_ convo: Convo, completion: @escaping (Success) -> Void) {
        let key = AsyncWorkGroupKey()

        key.deleteProxyConvo(convo)
        key.deleteUserConvo(convo)

        key.increment(by: -1, forProperty: .convos, forSenderProxyInConvo: convo)

        key.notify {
            completion(key.workResult)
            key.finishWorkGroup()
        }
    }

    static func getConvo(withKey key: String, belongingTo uid: String, completion: @escaping (Convo?) -> Void) {
        DB.get(Path.Convos, uid, key) { (data) in
            completion(Convo(data?.value as AnyObject))
        }
    }

    static func getConvos(forProxy proxy: Proxy, filtered: Bool, completion: @escaping ([Convo]?) -> Void) {
        DB.get(Path.Convos, proxy.key) { (data) in
            completion(data?.toConvos(filtered: filtered))
        }
    }

    static func getConvos(forUser uid: String, filtered: Bool, completion: @escaping ([Convo]?) -> Void) {
        DB.get(Path.Convos, uid) { (data) in
            completion(data?.toConvos(filtered: filtered))
        }
    }

    static func leaveConvo(_ convo: Convo, completion: @escaping (Success) -> Void) {
        let key = AsyncWorkGroupKey()
        key.incrementUnread(by: -convo.unread, forUser: convo.senderId)

        key.set(.receiverLeftConvo(true), forConvo: convo, asSender: false)
        key.set(.senderLeftConvo(true), forConvo: convo, asSender: true)
        key.increment(by: -1, forProperty: .convos, forSenderProxyInConvo: convo)
        key.increment(by: -convo.unread, forProperty: .unread, forSenderProxyInConvo: convo)

        key.notify {
            completion(key.workResult)
            key.finishWorkGroup()
        }
    }

    static func makeConvo(senderProxy: Proxy, receiverProxy: Proxy, completion: @escaping (Convo?) -> Void) {
        DB.get(Path.UserInfo, receiverProxy.ownerId, Path.Blocked, senderProxy.ownerId) { (data) in
            let senderIsBlocked = data?.value as? Bool ?? false
            let convoKey = makeConvoKey(senderProxy: senderProxy, receiverProxy: receiverProxy)

            var senderConvo = Convo()
            senderConvo.key = convoKey
            senderConvo.senderId = senderProxy.ownerId
            senderConvo.senderProxyKey = senderProxy.key
            senderConvo.senderProxyName = senderProxy.name
            senderConvo.receiverId = receiverProxy.ownerId
            senderConvo.receiverProxyKey = receiverProxy.key
            senderConvo.receiverProxyName = receiverProxy.name
            senderConvo.icon = receiverProxy.icon
            senderConvo.senderIsBlocked = senderIsBlocked

            var receiverConvo = Convo()
            receiverConvo.key = convoKey
            receiverConvo.senderId = receiverProxy.ownerId
            receiverConvo.senderProxyKey = receiverProxy.key
            receiverConvo.senderProxyName = receiverProxy.name
            receiverConvo.receiverId = senderProxy.ownerId
            receiverConvo.receiverProxyKey = senderProxy.key
            receiverConvo.receiverProxyName = senderProxy.name
            receiverConvo.icon = senderProxy.icon
            receiverConvo.receiverIsBlocked = senderIsBlocked

            let key = AsyncWorkGroupKey()
            key.incrementProxiesInteractedWith(forUser: senderProxy.ownerId)
            key.incrementProxiesInteractedWith(forUser: receiverProxy.ownerId)
            key.setProxyConvo(senderConvo)
            key.setProxyConvo(receiverConvo)
            key.setUserConvo(receiverConvo)
            key.setUserConvo(senderConvo)

            key.increment(by: 1, forProperty: .convos, forProxy: senderProxy)
            key.increment(by: 1, forProperty: .convos, forProxy: receiverProxy)

            key.notify {
                completion(key.workResult ? senderConvo : nil)
                key.finishWorkGroup()
            }
        }
    }

    static func makeConvoKey(senderProxy: Proxy, receiverProxy: Proxy) -> String {
        return [senderProxy.key, senderProxy.ownerId, receiverProxy.key, receiverProxy.ownerId].sorted().joined()
    }

    static func makeConvoTitle(receiverNickname: String, receiverName: String, senderNickname: String, senderName: String) -> NSAttributedString {
        let grayAttribute = [NSAttributedStringKey.foregroundColor: UIColor.gray]
        let receiver = NSMutableAttributedString(string: (receiverNickname == "" ? receiverName : receiverNickname) + ", ")
        let sender = NSMutableAttributedString(string: senderNickname == "" ? senderName : senderNickname, attributes: grayAttribute)
        receiver.append(sender)
        return receiver
    }

    static func setNickname(to nickname: String, forReceiverInConvo convo: Convo, completion: @escaping (Success) -> Void) {
        let key = AsyncWorkGroupKey()
        key.set(.receiverNickname(nickname), forConvo: convo, asSender: true)
        key.notify {
            completion(key.workResult)
            key.finishWorkGroup()
        }
    }

    static func userIsPresent(user uid: String, inConvoWithKey convoKey: String, completion: @escaping (Bool) -> Void) {
        DB.get(Path.UserInfo, uid, Path.Present, convoKey, Path.Present) { (data) in
            completion(data?.value as? Bool ?? false)
        }
    }
}

extension DataSnapshot {
    func toConvos(filtered: Bool) -> [Convo] {
        var convos = [Convo]()
        for child in self.children {
            if let convo = Convo((child as? DataSnapshot)?.value as AnyObject) {
                if filtered {
                    if !convo.senderLeftConvo && !convo.receiverIsBlocked {
                        convos.append(convo)
                    }
                } else {
                    convos.append(convo)
                }
            }
        }
        return convos
    }
}

extension AsyncWorkGroupKey {
    func deleteProxyConvo(_ convo: Convo) {
        startWork()
        DB.delete(Path.Convos, convo.senderProxyKey, convo.key) { (success) in
            self.finishWork(withResult: success)
        }
    }

    func deleteUserConvo(_ convo: Convo) {
        startWork()
        DB.delete(Path.Convos, convo.senderId, convo.key) { (success) in
            self.finishWork(withResult: success)
        }
    }

    func incrementProxiesInteractedWith(forUser uid: String) {
        startWork()
        DB.increment(by: 1, at: Path.UserInfo, uid, Path.ProxiesInteractedWith) { (success) in
            self.finishWork(withResult: success)
        }
    }

    func incrementUnread(by amount: Int, forUser uid: String) {
        increment(by: amount, at: Path.UserInfo, uid, Path.Unread)
    }

    func setProxyConvo(_ convo: Convo) {
        startWork()
        DB.set(convo.toJSON(), at: Path.Convos, convo.senderProxyKey, convo.key) { (success) in
            self.finishWork(withResult: success)
        }
    }

    func setUserConvo(_ convo: Convo) {
        startWork()
        DB.set(convo.toJSON(), at: Path.Convos, convo.senderId, convo.key) { (success) in
            self.finishWork(withResult: success)
        }
    }
}
