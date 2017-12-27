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

    static func getConvos(forProxy proxy: Proxy, completion: @escaping ([Convo]?) -> Void) {
        DB.get(Child.convos, proxy.key) { (data) in
            completion(data?.toConvosArray())
        }
    }

    static func getConvos(forUser uid: String, completion: @escaping ([Convo]?) -> Void) {
        DB.get(Child.convos, uid) { (data) in
            completion(data?.toConvosArray())
        }
    }

    static func getUnreadMessages(for convo: Convo, completion: @escaping ([Message]?) -> Void) {
        guard let ref = DB.makeReference(Child.userInfo, convo.receiverId, Child.unreadMessages) else {
            completion(nil)
            return
        }
        ref.queryOrdered(byChild: Child.parentConvoKey).queryEqual(toValue: convo.key).observeSingleEvent(of: .value, with: { (data) in
            completion(data.toMessagesArray())
        })
    }

    static func makeConvo(sender: Proxy, receiver: Proxy, completion: @escaping (Convo?) -> Void) {
        let convoKey = makeConvoKey(senderProxy: sender, receiverProxy: receiver)
        let senderConvo = Convo(key: convoKey, receiverId: receiver.ownerId, receiverProxyKey: receiver.key, receiverProxyName: receiver.name, senderId: sender.ownerId, senderProxyKey: sender.key, senderProxyName: sender.name, receiverIcon: receiver.icon)
        let receiverConvo = Convo(key: convoKey, receiverId: sender.ownerId, receiverProxyKey: sender.key, receiverProxyName: sender.name, senderId: receiver.ownerId, senderProxyKey: receiver.key, senderProxyName: receiver.name, receiverIcon: sender.icon)
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

    static func setReceiverNickname(to nickname: String, forConvo convo: Convo, completion: @escaping (ProxyError?) -> Void) {
        guard nickname.count < Setting.maxNameSize else {
            completion(.inputTooLong)
            return
        }
        let work = GroupWork()
        work.set(.receiverNickname(nickname), forConvo: convo, asSender: true)
        work.allDone {
            completion(work.result ? nil : .unknown)
        }
    }
}

extension DataSnapshot {
    func toConvosArray() -> [Convo] {
        var convos = [Convo]()
        for child in self.children {
            if let convo = Convo((child as? DataSnapshot)?.value as AnyObject) {
                convos.append(convo)
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
                self.delete(at: Child.userInfo, convo.senderId, Child.unreadMessages, message.messageId)
            }

            self.finish(withResult: true)
        }
    }
}
