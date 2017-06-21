//
//  ConvosManager.swift
//  proxy
//
//  Created by Quan Vo on 6/9/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import FirebaseDatabase

struct DBConvo {
    static func getConvoKey(senderProxy: Proxy, receiverProxy: Proxy) -> String {
        return [senderProxy.key, senderProxy.ownerId, receiverProxy.key, receiverProxy.ownerId].sorted().joined()
    }

    static func createConvo(sender: Proxy, receiver: Proxy, convoKey: String, text: String, completion: @escaping (Convo?) -> Void) {
        DB.get(Path.Blocked, receiver.ownerId, sender.ownerId) { (snapshot) in
            var senderConvo = Convo()
            var receiverConvo = Convo()
            let senderBlocked = snapshot?.childrenCount == 1

            senderConvo.key = convoKey
            senderConvo.senderId = sender.ownerId
            senderConvo.senderProxyKey = sender.key
            senderConvo.senderProxyName = sender.name
            senderConvo.receiverId = receiver.ownerId
            senderConvo.receiverProxyKey = receiver.key
            senderConvo.receiverProxyName = receiver.name
            senderConvo.icon = receiver.icon
            senderConvo.receiverIsBlocking = senderBlocked
            let senderConvoJSON = senderConvo.toJSON()

            receiverConvo.key = convoKey
            receiverConvo.senderId = receiver.ownerId
            receiverConvo.senderProxyKey = receiver.key
            receiverConvo.senderProxyName = receiver.name
            receiverConvo.receiverId = sender.ownerId
            receiverConvo.receiverProxyKey = sender.key
            receiverConvo.receiverProxyName = sender.name
            receiverConvo.icon = sender.icon
            receiverConvo.senderIsBlocking = senderBlocked
            let receiverConvoJSON = receiverConvo.toJSON()

            DB.set([(DB.path(Path.Convos, senderConvo.senderId, senderConvo.key), senderConvoJSON),
                    (DB.path(Path.Convos, senderConvo.senderProxyKey, senderConvo.key), senderConvoJSON),
                    (DB.path(Path.Convos, receiverConvo.senderId, receiverConvo.key), receiverConvoJSON),
                    (DB.path(Path.Convos, receiverConvo.senderProxyKey, receiverConvo.key), receiverConvoJSON)]) { (success) in
                        completion(success == true ? senderConvo : nil)
            }
        }
    }

    static func getConvo(withKey key: String, uid: String, completion: @escaping (Convo?) -> Void) {
        DB.get(Path.Convos, uid, key) { (snapshot) in
            completion(Convo(snapshot?.value as AnyObject))
        }
    }

    static func getConvos(forProxy proxy: Proxy, completion: @escaping ([Convo]?) -> Void) {
        DB.get(Path.Convos, proxy.key) { (snapshot) in
            completion(snapshot?.toConvos())
        }
    }

    static func getConvos(forUser uid: String, completion: @escaping ([Convo]?) -> Void) {
        DB.get(Path.Convos, uid) { (snapshot) in
            completion(snapshot?.toConvos())
        }
    }

    static func makeConvoTitle(receiverNickname: String, receiverName: String, senderNickname: String, senderName: String) -> NSAttributedString {
        let grayAttribute = [NSForegroundColorAttributeName: UIColor.gray]
        var first: NSMutableAttributedString
        var second: NSMutableAttributedString
        let comma = ", "
        if receiverNickname == "" {
            first = NSMutableAttributedString(string: receiverName + comma)
        } else {
            first = NSMutableAttributedString(string: receiverNickname + comma)
        }
        if senderNickname == "" {
            second = NSMutableAttributedString(string: senderName, attributes: grayAttribute)
        } else {
            second = NSMutableAttributedString(string: senderNickname, attributes: grayAttribute)
        }
        first.append(second)
        return first
    }

    static func setNickname(_ nickname: String, forReceiverInConvo convo: Convo, completion: @escaping (Success) -> Void) {
        DB.set([(DB.path(Path.Convos, convo.senderId, convo.key, Path.ReceiverNickname), nickname),
                (DB.path(Path.Convos, convo.senderProxyKey, convo.key, Path.ReceiverNickname), nickname)]) { (success) in
                    completion(success)
        }
    }
    
    static func userIsPresent(uid: String, inConvoWithKey convoKey: String, completion: @escaping (Bool) -> Void) {
        DB.get(Path.Present, convoKey, uid, Path.Present) { (snapshot) in
            completion(snapshot?.value as? Bool ?? false)
        }
    }

    static func leaveConvo(_ convo: Convo, completion: @escaping (Success) -> Void) {
        var allSuccess = true
        let leaveConvoDone = DispatchGroup()

        for _ in 1...4 {
            leaveConvoDone.enter()
        }

        DB.set([(DB.path(Path.Convos, convo.senderId, convo.key, Path.SenderLeftConvo), true),
                (DB.path(Path.Convos, convo.senderProxyKey, convo.key, Path.SenderLeftConvo), true),
                (DB.path(Path.Convos, convo.receiverId, convo.key, Path.ReceiverLeftConvo), true),
                (DB.path(Path.Convos, convo.receiverProxyKey, convo.key, Path.ReceiverLeftConvo), true)]) { (success) in
                    allSuccess &= success
                    leaveConvoDone.leave()
        }

        DB.increment(-1, children: Path.Proxies, convo.senderId, convo.senderProxyKey) { (success) in
            allSuccess &= success
            leaveConvoDone.leave()
        }

        DB.increment(-convo.unread, children: Path.Unread, convo.senderId, Path.Unread) { (success) in
            allSuccess &= success
            leaveConvoDone.leave()
        }

        DB.increment(-convo.unread, children: Path.Proxies, convo.senderId, convo.senderProxyKey, Path.Unread) { (success) in
            allSuccess &= success
            leaveConvoDone.leave()
        }

        leaveConvoDone.notify(queue: .main) { 
            completion(allSuccess)
        }
    }
}

extension DataSnapshot {
    func toConvos() -> [Convo] {
        var convos = [Convo]()
        for child in self.children {
            if  let snapshot = child as? DataSnapshot,
                let convo = Convo(snapshot.value as AnyObject),
                !convo.senderLeftConvo && !convo.senderIsBlocking {
                convos.append(convo)
            }
        }
        return convos
    }
}
