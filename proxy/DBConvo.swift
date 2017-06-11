//
//  ConvosManager.swift
//  proxy
//
//  Created by Quan Vo on 6/9/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import FirebaseDatabase

struct DBConvo {
    // TODO: - extension?
    static func getConvoKey(senderProxyKey: String, senderOwnerId: String, receiverProxyKey: String, receiverOwnerId: String) -> String {
        return [senderProxyKey, senderOwnerId, receiverProxyKey, receiverOwnerId].sorted().joined(separator: "")
    }

    // TODO: - make proxies interacted with and others a calculated var...store this in an array for each user and count that array
    static func createConvo(sender: Proxy, receiver: Proxy, convoKey: String, text: String, completion: @escaping (Convo?) -> Void) {
        DB.get(Path.Blocked, receiver.ownerId, sender.ownerId) { (snapshot) in
            guard let snapshot = snapshot else {
                completion(nil)
                return
            }
            var senderConvo = Convo()
            var receiverConvo = Convo()
            let senderBlocked = snapshot.childrenCount == 1

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

            DB.set([DB.path(Path.Convos, senderConvo.senderId, senderConvo.key): senderConvoJSON,
                    DB.path(Path.Convos, senderConvo.senderProxyKey, senderConvo.key): senderConvoJSON,
                    DB.path(Path.Convos, receiverConvo.senderId, receiverConvo.key): receiverConvoJSON,
                    DB.path(Path.Convos, receiverConvo.senderProxyKey, receiverConvo.key): receiverConvoJSON], completion: { (success) in
                        completion(success == true ? senderConvo : nil)
            })
        }
    }

    static func getConvo(withKey key: String, belongingToUserId user: String, completion: @escaping (Convo?) -> Void) {
        DB.get(Path.Convos, user, key) { (snapshot) in
            completion(try? Convo(snapshot?.value as AnyObject))
        }
    }

    static func getConvos(for proxy: Proxy, completion: @escaping ([Convo]?) -> Void) {
        DB.get(Path.Convos, proxy.key) { (snapshot) in
            completion(snapshot?.toConvos())
        }
    }

    static func getConvos(forUserId user: String, completion: @escaping ([Convo]?) -> Void) {
        DB.get(Path.Convos, user) { (snapshot) in
            completion(snapshot?.toConvos())
        }
    }

    // TODO: - extension?
    static func getConvoTitle(receiverNickname: String, receiverName: String, senderNickname: String, senderName: String) -> NSAttributedString {
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

    // TODO: - make transaction and return error
    //    static func setNickname(_ nickname: String, forReceiverInConvo convo: Convo, completion: @escaping (Error?) -> Void) {
    //        DB.set(nickname, pathNodes: Path.Convos, convo.senderId, convo.key, Path.ReceiverNickname)
    //        DB.set(nickname, pathNodes: Path.Convos, convo.senderProxyKey, convo.key, Path.ReceiverNickname)
    //    }
    //
    //    static func userIsPresent(userId: String, inConvoWithKey convo: String, completion: @escaping (Bool) -> Void) {
    //        DB.get(Path.Present, convo, userId, Path.Present) { (snapshot) in
    //            completion(snapshot?.value as? Bool ?? false)
    //        }
    //    }
    //
    //    // TODO: - make unread a calculated var?
    //    static func leaveConvo(_ convo: Convo) {
    //        DB.set(true, pathNodes: Path.Convos, convo.senderId, convo.key, Path.SenderLeftConvo)
    //        DB.set(true, pathNodes: Path.Convos, convo.senderProxyKey, convo.key, Path.SenderLeftConvo)
    //        DB.set(true, pathNodes: Path.Convos, convo.receiverId, convo.key, Path.ReceiverLeftConvo)
    //        DB.set(true, pathNodes: Path.Convos, convo.receiverProxyKey, convo.key, Path.ReceiverLeftConvo)
    //        DB.set(0, pathNodes: Path.Convos, convo.senderId, convo.key, Path.Unread)
    //        DB.set(0, pathNodes: Path.Convos, convo.senderProxyKey, convo.key, Path.Unread)
    //        DB.increment(-1, pathNodes: Path.Proxies, convo.senderId, convo.senderProxyKey, Path.Convos)
    //        DB.increment(-convo.unread, pathNodes: Path.Unread, convo.senderId, Path.Unread)
    //        DB.increment(-convo.unread, pathNodes: Path.Proxies, convo.senderId, convo.senderProxyKey, Path.Unread)
    //    }
}
