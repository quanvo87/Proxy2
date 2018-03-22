import GroupWork

extension GroupWork {
    func delete(_ first: String, _ rest: String...) {
        start()
        Constant.firebaseHelper.delete(first, rest) { [weak self] error in
            self?.finish(withResult: error == nil)
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
        GroupWork.getUnreadMessagesForProxy(uid: proxy.ownerId, key: proxy.key) { [weak self] result in
            switch result {
            case .failure:
                self?.finish(withResult: false)
            case .success(let messages):
                messages.forEach {
                    self?.delete(Child.users, $0.receiverId, Child.unreadMessages, $0.messageId)
                }
                self?.finish(withResult: true)
            }
        }
    }

    static func getOwnerIdAndProxyKey(convo: Convo, asSender: Bool) -> (ownerId: String, proxyKey: String) {
        return asSender ? (convo.senderId, convo.senderProxyKey) : (convo.receiverId, convo.receiverProxyKey)
    }

    static func getUnreadMessagesForProxy(uid: String,
                                          key: String,
                                          completion: @escaping (Result<[Message], Error>) -> Void) {
        do {
            try Constant.firebaseHelper.makeReference(Child.users, uid, Child.unreadMessages)
                .queryEqual(toValue: key)
                .queryOrdered(byChild: Child.receiverProxyKey)
                .observeSingleEvent(of: .value) { data in
                    completion(.success(data.asMessagesArray))
            }
        } catch {
            completion(.failure(error))
        }
    }

    func increment(_ amount: Int, at first: String, _ rest: String...) {
        start()
        Constant.firebaseHelper.increment(by: amount, at: first, rest) { [weak self] error in
            self?.finish(withResult: error == nil)
        }
    }

    func increment(_ amount: Int, property: IncrementableUserProperty, uid: String) {
        increment(amount, at: Child.users, uid, property.rawValue)
    }

    func set(_ value: Any, at first: String, _ rest: String...) {
        start()
        Constant.firebaseHelper.set(value, at: first, rest) { [weak self] error in
            self?.finish(withResult: error == nil)
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
            set(
                date.timeIntervalSince1970,
                at: Child.messages,
                message.parentConvoKey,
                message.messageId,
                property.properties.name
            )
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
        GroupWork.getUnreadMessagesForProxy(uid: uid, key: key) { [weak self] result in
            switch result {
            case .failure:
                self?.finish(withResult: false)
            case .success(let messages):
                if messages.count < 1 {
                    self?.set(.hasUnreadMessage(false), uid: uid, proxyKey: key)
                }
                self?.finish(withResult: true)
            }
        }
    }

    func setReceiverConvo(_ convo: Convo, database: Database = Constant.database) {
        start()
        Constant.firebaseHelper.set(
            convo.toDictionary(),
            at: Child.convos,
            convo.senderId,
            convo.key
        ) { [weak self] error in
            database.getProxy(proxyKey: convo.senderProxyKey, ownerId: convo.senderId) { result in
                switch result {
                case .failure:
                    Constant.firebaseHelper.delete(Child.convos, convo.senderId, convo.key) { _ in }
                default:
                    break
                }
                self?.finish(withResult: error == nil)
            }
        }
    }

    func setReceiverDeletedProxy(for convos: [Convo], database: Database = Constant.database) {
        for convo in convos {
            start()
            Constant.firebaseHelper.set(
                true,
                at: Child.convos,
                convo.receiverId,
                convo.key,
                Child.receiverDeletedProxy
            ) { [weak self] error in
                database.getConvo(convoKey: convo.key, ownerId: convo.receiverId) { result in
                    switch result {
                    case .failure:
                        Constant.firebaseHelper.delete(Child.convos, convo.receiverId, convo.key) { _ in }
                    default:
                        break
                    }
                    self?.finish(withResult: error == nil)
                }
            }
        }
    }

    func setReceiverIcon(to icon: String, for convos: [Convo]) {
        for convo in convos {
            set(.receiverIcon(icon), for: convo, asSender: false)
        }
    }

    func setReceiverMessageValues(convo: Convo,
                                  currentTime: Double,
                                  message: Message,
                                  database: Database = Constant.database) {
        guard !convo.receiverDeletedProxy else {
            return
        }
        switch message.data {
        case .text(let text):
            start()
            Constant.firebaseHelper.set(
                message.toDictionary(),
                at: Child.users,
                message.receiverId,
                Child.unreadMessages,
                message.messageId
            ) { [weak self] error in
                database.getProxy(proxyKey: message.receiverProxyKey, ownerId: message.receiverId) { result in
                    switch result {
                    case .failure:
                        Constant.firebaseHelper.delete(
                            Child.users,
                            message.receiverId,
                            Child.unreadMessages,
                            message.messageId
                        ) { _ in }
                        let work = GroupWork()
                        work.set(.receiverDeletedProxy(true), for: convo, asSender: true)
                        work.allDone {}
                    default:
                        break
                    }
                    self?.finish(withResult: error == nil)
                }
            }
            let convoUpdates: [String: Any] = [
                Child.hasUnreadMessage: true,
                Child.lastMessage: text,
                Child.timestamp: currentTime
            ]
            start()
            try? Constant.firebaseHelper.makeReference(Child.convos, convo.receiverId, convo.key)
                .updateChildValues(convoUpdates) { [weak self] error, _ in
                    self?.finish(withResult: error == nil)
                    database.getConvo(convoKey: convo.key, ownerId: convo.receiverId) { result in
                        switch result {
                        case .failure:
                            Constant.firebaseHelper.delete(Child.convos, convo.receiverId, convo.key) { _ in }
                        default:
                            break
                        }
                    }
            }
            let proxyUpdates: [String: Any] = [
                Child.hasUnreadMessage: true,
                Child.lastMessage: text,
                Child.timestamp: currentTime
            ]
            start()
            try? Constant.firebaseHelper.makeReference(Child.proxies, convo.receiverId, convo.receiverProxyKey)
                .updateChildValues(proxyUpdates) { [weak self] error, _ in
                    self?.finish(withResult: error == nil)
                    database.getProxy(proxyKey: message.receiverProxyKey, ownerId: message.receiverId) { result in
                        switch result {
                        case .failure:
                            Constant.firebaseHelper.delete(
                                Child.users,
                                message.receiverId,
                                Child.unreadMessages,
                                message.messageId
                            ) { _ in }
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
