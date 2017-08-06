import FirebaseDatabase

struct DBConvo {
    static func deleteConvo(_ convo: Convo, completion: @escaping (Success) -> Void) {
        let workKey = AsyncWorkGroupKey()
        workKey.decrementConvoCount(forSenderProxyOfConvo: convo)
        workKey.deleteProxyConvo(convo)
        workKey.deleteUserConvo(convo)
        workKey.notify {
            completion(workKey.workResult)
            workKey.finishWorkGroup()
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
        let workKey = AsyncWorkGroupKey()
        workKey.decrementConvoCount(forSenderProxyOfConvo: convo)
        workKey.decrementUnread(forSenderOfConvo: convo)
        workKey.decrementUnread(forSenderProxyOfConvo: convo)
        workKey.setReceiverLeftConvo(forReceiverInConvo: convo)
        workKey.setReceiverLeftConvo(forReceiverProxyInConvo: convo)
        workKey.setSenderLeftConvo(forSenderInConvo: convo)
        workKey.setSenderLeftConvo(forSenderProxyInConvo: convo)
        workKey.notify {
            completion(workKey.workResult)
            workKey.finishWorkGroup()
        }
    }

    static func makeConvo(senderProxy: Proxy, receiverProxy: Proxy, completion: @escaping (Convo?) -> Void) {
        DB.get(Path.UserInfo, receiverProxy.ownerId, Path.Blocked, senderProxy.ownerId, Path.Blocked) { (data) in
            let senderIsBlocking = data?.childrenCount == 1
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
            senderConvo.receiverIsBlocking = senderIsBlocking

            var receiverConvo = Convo()
            receiverConvo.key = convoKey
            receiverConvo.senderId = receiverProxy.ownerId
            receiverConvo.senderProxyKey = receiverProxy.key
            receiverConvo.senderProxyName = receiverProxy.name
            receiverConvo.receiverId = senderProxy.ownerId
            receiverConvo.receiverProxyKey = senderProxy.key
            receiverConvo.receiverProxyName = senderProxy.name
            receiverConvo.icon = senderProxy.icon
            receiverConvo.senderIsBlocking = senderIsBlocking

            let workKey = AsyncWorkGroupKey()
            workKey.incrementConvoCount(forProxy: senderProxy)
            workKey.incrementConvoCount(forProxy: receiverProxy)
            workKey.setProxyConvo(senderConvo)
            workKey.setProxyConvo(receiverConvo)
            workKey.setUserConvo(receiverConvo)
            workKey.setUserConvo(senderConvo)
            workKey.notify {
                completion(workKey.workResult ? senderConvo : nil)
                workKey.finishWorkGroup()
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


    static func setNickname(_ nickname: String, forReceiverInConvo convo: Convo, completion: @escaping (Success) -> Void) {
        let workKey = AsyncWorkGroupKey()
        workKey.setNickname(nickname, forReceiverInUserConvo: convo)
        workKey.setNickname(nickname, forReceiverInProxyConvo: convo)
        workKey.notify {
            completion(workKey.workResult)
            workKey.finishWorkGroup()
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
                    if !convo.senderLeftConvo && !convo.senderIsBlocking {
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
    func decrementConvoCount(forSenderProxyOfConvo convo: Convo) {
        startWork()
        DB.increment(-1, at: Path.Proxies, convo.senderId, convo.senderProxyKey, Path.Convos) { (success) in
            self.finishWork(withResult: success)
        }
    }

    func decrementUnread(forSenderOfConvo convo: Convo) {
        startWork()
        DB.increment(-convo.unread, at: Path.UserInfo, convo.senderId, Path.Unread) { (success) in
            self.finishWork(withResult: success)
        }
    }

    func decrementUnread(forSenderProxyOfConvo convo: Convo) {
        startWork()
        DB.increment(-convo.unread, at: Path.Proxies, convo.senderId, convo.senderProxyKey, Path.Unread) { (success) in
            self.finishWork(withResult: success)
        }
    }

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

    func incrementConvoCount(forProxy proxy: Proxy) {
        startWork()
        DB.increment(1, at: Path.Proxies, proxy.ownerId, proxy.key, Path.Convos) { (success) in
            self.finishWork(withResult: success)
        }
    }

    func setNickname(_ nickname: String, forReceiverInProxyConvo convo: Convo) {
        startWork()
        DB.set(nickname, at: Path.Convos, convo.senderProxyKey, convo.key, Path.ReceiverNickname) { (success) in
            self.finishWork(withResult: success)
        }
    }

    func setNickname(_ nickname: String, forReceiverInUserConvo convo: Convo) {
        startWork()
        DB.set(nickname, at: Path.Convos, convo.senderId, convo.key, Path.ReceiverNickname) { (success) in
            self.finishWork(withResult: success)
        }
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

    func setReceiverLeftConvo(forReceiverProxyInConvo convo: Convo) {
        startWork()
        DB.set(true, at: Path.Convos, convo.receiverProxyKey, convo.key, Path.ReceiverLeftConvo) { (success) in
            self.finishWork(withResult: success)
        }
    }

    func setReceiverLeftConvo(forReceiverInConvo convo: Convo) {
        startWork()
        DB.set(true, at: Path.Convos, convo.receiverId, convo.key, Path.ReceiverLeftConvo) { (success) in
            self.finishWork(withResult: success)
        }
    }

    func setSenderLeftConvo(forSenderProxyInConvo convo: Convo) {
        startWork()
        DB.set(true, at: Path.Convos, convo.senderProxyKey, convo.key, Path.SenderLeftConvo) { (success) in
            self.finishWork(withResult: success)
        }
    }

    func setSenderLeftConvo(forSenderInConvo convo: Convo) {
        startWork()
        DB.set(true, at: Path.Convos, convo.senderId, convo.key, Path.SenderLeftConvo) { (success) in
            self.finishWork(withResult: success)
        }
    }
}
