import GroupWork
import FirebaseHelper

extension GroupWork {
    func delete(_ first: String, _ rest: String...) {
        start()
        FirebaseHelper.main.delete(first, rest) { (error) in
            self.finish(withResult: error == nil)
        }
    }

    func delete(_ convo: Convo, asSender: Bool) {
        let (ownerId, _) = GroupWork.getOwnerIdAndProxyKey(convo: convo, asSender: asSender)
        delete(Child.convos, ownerId, convo.key)
    }

    func delete(_ convos: [Convo]) {
        for convo in convos {
            delete(Child.convos, convo.senderId, convo.key)
            if convo.receiverDeletedProxy {
                delete(Child.messages, convo.key)
            }
        }
    }

    func deleteUnreadMessages(for proxy: Proxy) {
        start()
        GroupWork.getUnreadMessagesForProxy(uid: proxy.ownerId, key: proxy.key) { (result) in
            switch result {
            case .failure:
                self.finish(withResult: false)
            case .success(let messages):
                messages.forEach {
                    self.delete(Child.userInfo, $0.receiverId, Child.unreadMessages, $0.messageId)
                }
                self.finish(withResult: true)
            }
        }
    }

    static func getOwnerIdAndProxyKey(convo: Convo, asSender: Bool) -> (ownerId: String, proxyKey: String) {
        return
            asSender ?
                (convo.senderId, convo.senderProxyKey) :
                (convo.receiverId, convo.receiverProxyKey)
    }

    static func getUnreadMessagesForProxy(uid: String, key: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        do {
            try FirebaseHelper.main.makeReference(Child.userInfo, uid, Child.unreadMessages)
                .queryOrdered(byChild: Child.receiverProxyKey)
                .queryEqual(toValue: key).observeSingleEvent(of: .value) { (data) in
                    completion(.success(data.toMessagesArray))
            }
        } catch {
            completion(.failure(error))
        }
    }

    func increment(_ amount: Int, at first: String, _ rest: String...) {
        start()
        FirebaseHelper.main.increment(by: amount, at: first, rest) { (error) in
            self.finish(withResult: error == nil)
        }
    }

    func increment(_ amount: Int, property: IncrementableUserProperty, uid: String) {
        increment(amount, at: Child.userInfo, uid, property.rawValue)
    }

    func set(_ value: Any, at first: String, _ rest: String...) {
        start()
        FirebaseHelper.main.set(value, at: first, rest) { (error) in
            self.finish(withResult: error == nil)
        }
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

    func set(_ property: SettableMessageProperty, for message: Message) {
        switch property {
        case .dateRead(let date):
            set(date.timeIntervalSince1970, at: Child.messages, message.parentConvoKey, message.messageId, property.properties.name)
        }
    }

    func set(_ property: SettableProxyProperty, for proxy: Proxy) {
        set(property, uid: proxy.ownerId, proxyKey: proxy.key)
    }

    func set(_ property: SettableProxyProperty, forProxyIn convo: Convo, asSender: Bool) {
        let (ownerId, proxyKey) = GroupWork.getOwnerIdAndProxyKey(convo: convo, asSender: asSender)
        set(property, uid: ownerId, proxyKey: proxyKey)
    }

    func set(_ property: SettableProxyProperty, uid: String, proxyKey: String) {
        set(property.properties.value, at: Child.proxies, uid, proxyKey, property.properties.name)
    }

    func setHasUnreadMessageForProxy(uid: String, key: String) {
        start()
        GroupWork.getUnreadMessagesForProxy(uid: uid, key: key) { (result) in
            switch result {
            case .failure:
                self.finish(withResult: false)
            case .success(let messages):
                if messages.count < 1 {
                    self.set(.hasUnreadMessage(false), uid: uid, proxyKey: key)
                }
                self.finish(withResult: true)
            }
        }
    }

    func setReceiverConvo(_ convo: Convo, database: Database = Firebase()) {
        start()
        FirebaseHelper.main.set(convo.toDictionary(), at: Child.convos, convo.senderId, convo.key) { (error) in
            self.finish(withResult: error == nil)
            database.getProxy(key: convo.senderProxyKey, ownerId: convo.senderId) { (result) in
                switch result {
                case .failure:
                    FirebaseHelper.main.delete(Child.convos, convo.senderId, convo.key) { _ in }
                default:
                    break
                }
            }
        }
    }

    func setReceiverDeletedProxy(for convos: [Convo], database: Database = Firebase()) {
        for convo in convos {
            start()
            FirebaseHelper.main.set(true, at: Child.convos, convo.receiverId, convo.key, Child.receiverDeletedProxy) { (error) in
                self.finish(withResult: error == nil)
                database.getConvo(key: convo.key, ownerId: convo.receiverId) { (result) in
                    switch result {
                    case .failure:
                        FirebaseHelper.main.delete(Child.convos, convo.receiverId, convo.key) { _ in }
                    default:
                        break
                    }
                }
            }
        }
    }

    func setReceiverIcon(to icon: String, for convos: [Convo]) {
        for convo in convos {
            set(.receiverIcon(icon), for: convo, asSender: false)
        }
    }

    func setReceiverMessageValues(convo: Convo, currentTime: Double, message: Message, database: Database = Firebase()) {
        guard !convo.receiverDeletedProxy else {
            return
        }
        switch message.data {
        case .text(let text):
            start()
            FirebaseHelper.main.set(message.toDictionary(), at: Child.userInfo, message.receiverId, Child.unreadMessages, message.messageId) { (error) in
                self.finish(withResult: error == nil)
                database.getProxy(key: message.receiverProxyKey, ownerId: message.receiverId) { (result) in
                    switch result {
                    case .failure:
                        FirebaseHelper.main.delete(Child.userInfo, message.receiverId, Child.unreadMessages, message.messageId) { _ in }
                        let work = GroupWork()
                        work.set(.receiverDeletedProxy(true), for: convo, asSender: true)
                        work.allDone {}
                    default:
                        break
                    }
                }
            }
            let convoUpdates: [String: Any] = [Child.hasUnreadMessage: true,
                                               Child.lastMessage: text,
                                               Child.timestamp: currentTime]
            start()
            try? FirebaseHelper.main.makeReference(Child.convos, convo.receiverId, convo.key)
                .updateChildValues(convoUpdates) { (error, _) in
                    self.finish(withResult: error == nil)
                    database.getConvo(key: convo.key, ownerId: convo.receiverId) { (result) in
                        switch result {
                        case .failure:
                            FirebaseHelper.main.delete(Child.convos, convo.receiverId, convo.key) { _ in }
                        default:
                            break
                        }
                    }
            }
            let proxyUpdates: [String: Any] = [Child.hasUnreadMessage: true,
                                               Child.lastMessage: text,
                                               Child.timestamp: currentTime]
            start()
            try? FirebaseHelper.main.makeReference(Child.proxies, convo.receiverId, convo.receiverProxyKey)
                .updateChildValues(proxyUpdates) { (error, _) in
                    self.finish(withResult: error == nil)
                    database.getProxy(key: message.receiverProxyKey, ownerId: message.receiverId) { (result) in
                        switch result {
                        case .failure:
                            FirebaseHelper.main.delete(Child.userInfo, message.receiverId, Child.unreadMessages, message.messageId) { _ in }
                            let work = GroupWork()
                            work.set(.receiverDeletedProxy(true), for: convo, asSender: true)
                            work.allDone {}
                        default:
                            break
                        }
                    }
            }
        default:
            break
        }
    }

    func setSenderIcon(to icon: String, for convos: [Convo]) {
        for convo in convos {
            set(.senderIcon(icon), for: convo, asSender: true)
        }
    }

    func setSenderNickname(to nickname: String, for convos: [Convo]) {
        for convo in convos {
            set(.senderNickname(nickname), for: convo, asSender: true)
        }
    }
}
