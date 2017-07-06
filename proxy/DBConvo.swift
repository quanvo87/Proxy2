//
//  ConvosManager.swift
//  proxy
//
//  Created by Quan Vo on 6/9/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import FirebaseDatabase

struct DBConvo {}

extension DBConvo {
    static func getConvoKey(senderProxy: Proxy, receiverProxy: Proxy) -> String {
        return [senderProxy.key, senderProxy.ownerId, receiverProxy.key, receiverProxy.ownerId].sorted().joined()
    }

    static func createConvo(sender: Proxy, receiver: Proxy, completion: @escaping (Convo?) -> Void) {
        DB.get(Path.Blocked, receiver.ownerId, sender.ownerId) { (snapshot) in
            var senderConvo = Convo()
            var receiverConvo = Convo()
            let convoKey = getConvoKey(senderProxy: sender, receiverProxy: receiver)
            let senderIsBlocking = snapshot?.childrenCount == 1

            senderConvo.key = convoKey
            senderConvo.senderId = sender.ownerId
            senderConvo.senderProxyKey = sender.key
            senderConvo.senderProxyName = sender.name
            senderConvo.receiverId = receiver.ownerId
            senderConvo.receiverProxyKey = receiver.key
            senderConvo.receiverProxyName = receiver.name
            senderConvo.icon = receiver.icon
            senderConvo.receiverIsBlocking = senderIsBlocking
            let senderConvoJSON = senderConvo.toJSON()

            receiverConvo.key = convoKey
            receiverConvo.senderId = receiver.ownerId
            receiverConvo.senderProxyKey = receiver.key
            receiverConvo.senderProxyName = receiver.name
            receiverConvo.receiverId = sender.ownerId
            receiverConvo.receiverProxyKey = sender.key
            receiverConvo.receiverProxyName = sender.name
            receiverConvo.icon = sender.icon
            receiverConvo.senderIsBlocking = senderIsBlocking
            let receiverConvoJSON = receiverConvo.toJSON()

            DB.set([DB.Transaction(set: senderConvoJSON, at: Path.Convos, senderConvo.senderId, senderConvo.key),
                    DB.Transaction(set: senderConvoJSON, at: Path.Convos, senderConvo.senderProxyKey, senderConvo.key),
                    DB.Transaction(set: receiverConvoJSON, at: Path.Convos, receiverConvo.senderId, receiverConvo.key),
                    DB.Transaction(set: receiverConvoJSON, at: Path.Convos, receiverConvo.senderProxyKey, receiverConvo.key)]) { (success) in
                        completion(success ? senderConvo : nil)
            }
        }
    }
}

extension DBConvo {
    static func getConvo(withKey key: String, belongingTo uid: String, completion: @escaping (Convo?) -> Void) {
        DB.get(Path.Convos, uid, key) { (snapshot) in
            completion(Convo(snapshot?.value as AnyObject))
        }
    }

    static func getConvos(forProxy proxy: Proxy, filtered: Bool, completion: @escaping ([Convo]?) -> Void) {
        DB.get(Path.Convos, proxy.key) { (snapshot) in
            completion(snapshot?.toConvos(filtered: filtered))
        }
    }

    static func getConvos(forUser uid: String, filtered: Bool, completion: @escaping ([Convo]?) -> Void) {
        DB.get(Path.Convos, uid) { (snapshot) in
            completion(snapshot?.toConvos(filtered: filtered))
        }
    }
}

extension DBConvo {
    static func setNickname(_ nickname: String, forReceiverInConvo convo: Convo, completion: @escaping (Success) -> Void) {
        DB.set([DB.Transaction(set: nickname, at: Path.Convos, convo.senderId, convo.key, Path.ReceiverNickname),
                DB.Transaction(set: nickname, at: Path.Convos, convo.senderProxyKey, convo.key, Path.ReceiverNickname)]) { (success) in
                    completion(success)
        }
    }

    static func leaveConvo(_ convo: Convo, completion: @escaping (Success) -> Void) {
        var allSuccess = true
        let leaveConvoDone = DispatchGroup()

        for _ in 1...4 {
            leaveConvoDone.enter()
        }

        DB.set([DB.Transaction(set: true, at: Path.Convos, convo.senderId, convo.key, Path.SenderLeftConvo),
                DB.Transaction(set: true, at: Path.Convos, convo.senderProxyKey, convo.key, Path.SenderLeftConvo),
                DB.Transaction(set: true, at: Path.Convos, convo.receiverId, convo.key, Path.ReceiverLeftConvo),
                DB.Transaction(set: true, at: Path.Convos, convo.receiverProxyKey, convo.key, Path.ReceiverLeftConvo)]) { (success) in
                    allSuccess &= allSuccess
                    leaveConvoDone.leave()
        }

        DB.increment(-1, at: Path.Proxies, convo.senderId, convo.senderProxyKey, Path.Convos) { (success) in
            allSuccess &= success
            leaveConvoDone.leave()
        }

        DB.increment(-convo.unread, at: Path.UserInfo, convo.senderId, Path.Unread) { (success) in
            allSuccess &= success
            leaveConvoDone.leave()
        }

        DB.increment(-convo.unread, at: Path.Proxies, convo.senderId, convo.senderProxyKey, Path.Unread) { (success) in
            allSuccess &= success
            leaveConvoDone.leave()
        }

        leaveConvoDone.notify(queue: .main) {
            completion(allSuccess)
        }
    }

    // TODO: - only need to delete sender's copies
    static func deleteConvo(_ convo: Convo, completion: @escaping (Success) -> Void) {
        var allSuccess = true

        let deleteConvoDone = DispatchGroup()
        for _ in 1...4 {
            deleteConvoDone.enter()
        }

        DB.delete(Path.Convos, convo.senderId, convo.key) { (success) in
            allSuccess &= success
            deleteConvoDone.leave()
        }

        DB.delete(Path.Convos, convo.senderProxyKey, convo.key) { (success) in
            allSuccess &= success
            deleteConvoDone.leave()
        }

        DB.delete(Path.Convos, convo.receiverId, convo.key) { (success) in
            allSuccess &= success
            deleteConvoDone.leave()
        }

        DB.delete(Path.Convos, convo.receiverProxyKey, convo.key) { (success) in
            allSuccess &= success
            deleteConvoDone.leave()
        }

        deleteConvoDone.notify(queue: .main) {
            completion(allSuccess)
        }
    }
}

extension DBConvo {
    static func makeConvoTitle(receiverNickname: String, receiverName: String, senderNickname: String, senderName: String) -> NSAttributedString {
        let grayAttribute = [NSAttributedStringKey.foregroundColor: UIColor.gray]
        let first = NSMutableAttributedString(string: (receiverNickname == "" ? receiverName : receiverNickname) + ", ")
        let second = NSMutableAttributedString(string: senderNickname == "" ? senderName : senderNickname,
                                               attributes: grayAttribute)
        first.append(second)
        return first
    }
}

extension DBConvo {
    static func userIsPresent(uid: String, inConvoWithKey convoKey: String, completion: @escaping (Bool) -> Void) {
        DB.get(Path.Present, convoKey, uid, Path.Present) { (snapshot) in
            completion(snapshot?.value as? Bool ?? false)
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
