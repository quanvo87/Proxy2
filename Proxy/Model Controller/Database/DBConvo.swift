import FirebaseDatabase
import GroupWork
import UIKit

struct DBConvo {
    static func deleteConvo(_ convo: Convo, completion: @escaping (Success) -> Void) {
        let work = GroupWork()
        work.delete(convo, asSender: true)
        work.increment(by: -1, forProperty: .convoCount, forProxyInConvo: convo, asSender: true)
        work.allDone {
            completion(work.result)
        }
    }

    static func getConvo(withKey key: String, belongingTo uid: String, completion: @escaping (Convo?) -> Void) {
        DB.get(Child.convos, uid, key) { (data) in
            completion(Convo(data?.value as AnyObject))
        }
    }

    static func getConvos(forProxy proxy: Proxy, filtered: Bool, completion: @escaping ([Convo]?) -> Void) {
        DB.get(Child.convos, proxy.key) { (data) in
            completion(data?.toConvosArray(filtered: filtered))
        }
    }

    static func getConvos(forUser uid: String, filtered: Bool, completion: @escaping ([Convo]?) -> Void) {
        DB.get(Child.convos, uid) { (data) in
            completion(data?.toConvosArray(filtered: filtered))
        }
    }

    static func getUnreadMessages(for convo: Convo, completion: @escaping ([Message]?) -> Void) {
        guard let ref = DB.makeReference(Child.userInfo, convo.receiverId, Child.unreadMessages) else {
            completion(nil)
            return
        }

        ref.queryOrdered(byChild: "parentConvo").queryEqual(toValue: convo.key).observeSingleEvent(of: .value, with: { (data) in
            completion(data.toMessagesArray())
        })
    }

    // TODO: have to mark all the messages as read?
    static func leaveConvo(_ convo: Convo, completion: @escaping (Success) -> Void) {
        let work = GroupWork()
        work.deleteUnreadMessages(for: convo)
        work.increment(by: -1, forProperty: .convoCount, forProxyInConvo: convo, asSender: true)
        work.set(.receiverLeftConvo(true), forConvo: convo, asSender: false)
        work.set(.senderLeftConvo(true), forConvo: convo, asSender: true)
        work.allDone {
            work.setHasUnreadMessageForProxy(key: convo.receiverProxyKey, ownerId: convo.receiverId)
            work.allDone {
                completion(work.result)
            }
        }
    }

    static func makeConvo(sender: Proxy, receiver: Proxy, completion: @escaping (Convo?) -> Void) {
        DB.get(Child.userInfo, receiver.ownerId, Child.blockedUsers, sender.ownerId) { (data) in
            let senderIsBlocked = data?.value as? Bool ?? false
            let convoKey = makeConvoKey(senderProxy: sender, receiverProxy: receiver)

            var senderConvo = Convo()
            senderConvo.key = convoKey
            senderConvo.receiverIcon = receiver.icon
            senderConvo.receiverId = receiver.ownerId
            senderConvo.receiverProxyKey = receiver.key
            senderConvo.receiverProxyName = receiver.name
            senderConvo.senderId = sender.ownerId
            senderConvo.senderProxyKey = sender.key
            senderConvo.senderProxyName = sender.name
            senderConvo.senderIsBlocked = senderIsBlocked

            var receiverConvo = Convo()
            receiverConvo.key = convoKey
            receiverConvo.receiverIcon = sender.icon
            receiverConvo.receiverId = sender.ownerId
            receiverConvo.receiverProxyKey = sender.key
            receiverConvo.receiverProxyName = sender.name
            receiverConvo.receiverIsBlocked = senderIsBlocked
            receiverConvo.senderId = receiver.ownerId
            receiverConvo.senderProxyKey = receiver.key
            receiverConvo.senderProxyName = receiver.name

            let work = GroupWork()
            work.increment(by: 1, forProperty: .convoCount, forProxy: receiver)
            work.increment(by: 1, forProperty: .convoCount, forProxy: sender)
            work.increment(by: 1, forProperty: .proxiesInteractedWith, forUser: receiver.ownerId)
            work.increment(by: 1, forProperty: .proxiesInteractedWith, forUser: sender.ownerId)
            work.set(receiverConvo, asSender: true)
            work.set(senderConvo, asSender: true)
            work.allDone {
                completion(work.result ? senderConvo : nil)
            }
        }
    }

    static func makeConvoKey(senderProxy: Proxy, receiverProxy: Proxy) -> String {
        return [senderProxy.key, senderProxy.ownerId, receiverProxy.key, receiverProxy.ownerId].sorted().joined()
    }

    static func makeConvoTitle(_ convo: Convo) -> NSAttributedString {
        let grayAttribute = [NSAttributedStringKey.foregroundColor: UIColor.gray]
        let receiver = NSMutableAttributedString(string: (convo.receiverNickname == "" ? convo.receiverProxyName : convo.receiverNickname) + ", ")
        let sender = NSMutableAttributedString(string: convo.senderNickname == "" ? convo.senderProxyName : convo.senderNickname, attributes: grayAttribute)
        receiver.append(sender)
        return receiver
    }

    static func receiverIsBlocked(_ convo: Convo, completion: @escaping (Bool) -> Void) {
        DB.get(Child.convos, convo.senderId, convo.key, Child.receiverIsBlocked) { (data) in
            completion(data?.value as? Bool ?? false)
        }
    }

    static func senderLeftConvo(_ convo: Convo, completion: @escaping (Bool) -> Void) {
        DB.get(Child.convos, convo.senderId, convo.key, Child.senderLeftConvo) { (data) in
            completion(data?.value as? Bool ?? false)
        }
    }

    static func setReceiverNickname(to nickname: String, forConvo convo: Convo, completion: @escaping (Success) -> Void) {
        let work = GroupWork()
        work.set(.receiverNickname(nickname), forConvo: convo, asSender: true)
        work.allDone {
            completion(work.result)
        }
    }

    static func userIsPresent(user uid: String, inConvoWithKey convoKey: String, completion: @escaping (Bool) -> Void) {
        DB.get(Child.userInfo, uid, Child.isPresent, convoKey, Child.isPresent) { (data) in
            completion(data?.value as? Bool ?? false)
        }
    }
}

extension DataSnapshot {
    func toConvosArray(filtered: Bool) -> [Convo] {
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

extension GroupWork {
    func delete(_ convo: Convo, asSender: Bool) {
        let (ownerId, proxyKey) = GroupWork.getOwnerIdAndProxyKey(fromConvo: convo, asSender: asSender)
        delete(at: Child.convos, ownerId, convo.key)
        delete(at: Child.convos, proxyKey, convo.key)
    }

    func set(_ convo: Convo, asSender: Bool) {
        let (ownerId, proxyKey) = GroupWork.getOwnerIdAndProxyKey(fromConvo: convo, asSender: asSender)
        set(convo.toDictionary(), at: Child.convos, ownerId, convo.key)
        set(convo.toDictionary(), at: Child.convos, proxyKey, convo.key)
    }

    func set(_ property: SettableConvoProperty, forConvo convo: Convo, asSender: Bool) {
        let (ownerId, proxyKey) = GroupWork.getOwnerIdAndProxyKey(fromConvo: convo, asSender: asSender)
        set(property.properties.value, at: Child.convos, ownerId, convo.key, property.properties.name)
        set(property.properties.value, at: Child.convos, proxyKey, convo.key, property.properties.name)
    }

    func set(_ property: SettableConvoProperty, forConvoWithKey key: String, ownerId: String, proxyKey: String) {
        set(property.properties.value, at: Child.convos, ownerId, key, property.properties.name)
        set(property.properties.value, at: Child.convos, proxyKey, key, property.properties.name)
    }
}

extension GroupWork {
    func deleteUnreadMessages(for convo: Convo) {
        start()

        DBConvo.getUnreadMessages(for: convo) { (messages) in
            guard let messages = messages else {
                self.finish(withResult: false)
                return
            }

            for message in messages {
                self.delete(at: Child.userInfo, convo.senderId, Child.unreadMessages, message.key)
            }

            self.finish(withResult: true)
        }
    }
}
