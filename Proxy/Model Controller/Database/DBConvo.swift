import FirebaseDatabase
import GroupWork
import UIKit

extension DB {
    static func getConvo(withKey key: String, belongingTo uid: String, completion: @escaping (Convo?) -> Void) {
        get(Child.convos, uid, key) { (data) in
            guard let data = data else {
                completion(nil)
                return
            }
            completion(Convo(data))
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
