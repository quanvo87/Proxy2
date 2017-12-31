import FirebaseDatabase
import GroupWork
import UIKit

extension DB {
    static func deleteConvo(_ convo: Convo, completion: @escaping (Success) -> Void) {
        let work = GroupWork()
        work.delete(convo, asSender: true)
        work.allDone {
            completion(work.result)
        }
    }

    static func getConvo(withKey key: String, belongingTo uid: String, completion: @escaping (Convo?) -> Void) {
        get(Child.convos, uid, key) { (data) in
            guard let data = data else {
                completion(nil)
                return
            }
            completion(Convo(data: data, ref: makeReference(Child.convos, uid)))
        }
    }

    static func getConvos(forProxy proxy: Proxy, completion: @escaping ([Convo]?) -> Void) {
        get(Child.convos, proxy.key) { (data) in
            completion(data?.toConvosArray(makeReference(Child.convos, proxy.key)))
        }
    }

    static func makeConvo(convoKey: String, sender: Proxy, receiver: Proxy, completion: @escaping (Convo?) -> Void) {
        let senderConvo = Convo(key: convoKey, receiverIcon: receiver.icon, receiverId: receiver.ownerId, receiverProxyKey: receiver.key, receiverProxyName: receiver.name, senderId: sender.ownerId, senderProxyKey: sender.key, senderProxyName: sender.name)
        let receiverConvo = Convo(key: convoKey, receiverIcon: sender.icon, receiverId: sender.ownerId, receiverProxyKey: sender.key, receiverProxyName: sender.name, senderId: receiver.ownerId, senderProxyKey: receiver.key, senderProxyName: receiver.name)
        let work = GroupWork()
        work.increment(by: 1, forProperty: .proxiesInteractedWith, forUser: receiver.ownerId)
        work.increment(by: 1, forProperty: .proxiesInteractedWith, forUser: sender.ownerId)
        work.set(receiverConvo, asSender: true)
        work.set(senderConvo, asSender: true)
        work.allDone {
            completion(work.result ? senderConvo : nil)
        }
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
