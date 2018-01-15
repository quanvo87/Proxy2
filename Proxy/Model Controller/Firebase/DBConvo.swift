import FirebaseDatabase
import GroupWork
import UIKit

extension DB {
    static func delete(_ convo: Convo, asSender: Bool, completion: @escaping (Bool) -> Void) {
        let work = GroupWork()
        work.delete(convo, asSender: asSender)
        work.allDone {
            completion(work.result)
        }
    }

    static func getConvo(uid: String, key: String, completion: @escaping (Convo?) -> Void) {
        get(Child.convos, uid, key) { (data) in
            guard let data = data else {
                completion(nil)
                return
            }
            completion(Convo(data))
        }
    }

    static func setReceiverNickname(to nickname: String, for convo: Convo, completion: @escaping (ProxyError?) -> Void) {
        guard nickname.count < Setting.maxNameSize else {
            completion(.inputTooLong)
            return
        }
        let work = GroupWork()
        work.set(.receiverNickname(nickname), for: convo, asSender: true)
        work.allDone {
            completion(work.result ? nil : .unknown)
        }
    }
}

extension GroupWork {
    func delete(_ convo: Convo, asSender: Bool) {
        let (ownerId, _) = GroupWork.getOwnerIdAndProxyKey(convo: convo, asSender: asSender)
        delete(Child.convos, ownerId, convo.key)
    }

    func set(_ convo: Convo, asSender: Bool) {
        let (ownerId, _) = GroupWork.getOwnerIdAndProxyKey(convo: convo, asSender: asSender)
        set(convo.toDictionary(), at: Child.convos, ownerId, convo.key)
    }

    func set(_ property: SettableConvoProperty, for convo: Convo, asSender: Bool) {
        let (ownerId, _) = GroupWork.getOwnerIdAndProxyKey(convo: convo, asSender: asSender)
        set(property.properties.value, at: Child.convos, ownerId, convo.key, property.properties.name)
    }

    func set(_ property: SettableConvoProperty, uid: String, convoKey: String) {
        set(property.properties.value, at: Child.convos, uid, convoKey, property.properties.name)
    }
}
