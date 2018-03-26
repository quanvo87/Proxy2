import GroupWork

extension GroupWork {
    static func getOwnerIdAndProxyKey(convo: Convo, asSender: Bool) -> (ownerId: String, proxyKey: String) {
        return asSender ? (convo.senderId, convo.senderProxyKey) : (convo.receiverId, convo.receiverProxyKey)
    }

    func deleteAllMessagesForConvo(convoKey: String) {
        delete(Child.messages, convoKey)
    }

    func delete(_ convo: Convo, asSender: Bool) {
        let (ownerId, _) = GroupWork.getOwnerIdAndProxyKey(convo: convo, asSender: asSender)
        delete(Child.convos, ownerId, convo.key)
    }

    func delete(_ convos: [Convo]) {
        convos.forEach {
            delete($0, asSender: true)
            delete(.contact($0.receiverId), for: $0.senderId)
            delete(.contact($0.senderId), for: $0.receiverId)
            if $0.receiverDeletedProxy {
                deleteAllMessagesForConvo(convoKey: $0.key)
            }
        }
    }

    func delete(_ proxy: Proxy) {
        delete(Child.proxies, proxy.ownerId, proxy.key)
    }

    func deleteProxyKey(proxyKey: String) {
        delete(Child.proxyKeys, proxyKey)
    }

    func deleteUnreadMessage(_ message: Message) {
        delete(Child.users, message.receiverId, Child.unreadMessages, message.messageId)
    }

    func deleteUnreadMessages(for proxy: Proxy) {
        start()
        GroupWork.getUnreadMessagesForProxy(uid: proxy.ownerId, key: proxy.key) { [weak self] result in
            switch result {
            case .failure:
                self?.finish(withResult: false)
            case .success(let messages):
                messages.forEach {
                    self?.deleteUnreadMessage($0)
                }
                self?.finish(withResult: true)
            }
        }
    }

    func delete(_ userProperty: SettableUserProperty, for uid: String) {
        let path = Firebase.getPath(uid: uid, userProperty: userProperty)
        delete(Child.users, path)
    }

    func increment(_ property: IncrementableUserProperty, for uid: String) {
        increment(property.properties.value, at: Child.users, uid, property.properties.name)
    }

    func set(_ convo: Convo, asSender: Bool) {
        let (ownerId, _) = GroupWork.getOwnerIdAndProxyKey(convo: convo, asSender: asSender)
        set(convo.asDictionary, at: Child.convos, ownerId, convo.key)
    }

    func set(_ message: Message) {
        set(message.asDictionary, at: Child.messages, message.parentConvoKey, message.messageId)
    }

    func set(_ proxy: Proxy) {
        set(proxy.asDictionary, at: Child.proxies, proxy.ownerId, proxy.key)
    }

    func setProxyKey(_ proxy: Proxy) {
        set(proxy.asDictionary, at: Child.proxyKeys, proxy.key)
    }

    func set(_ property: SettableConvoProperty, for convo: Convo, asSender: Bool) {
        let (ownerId, _) = GroupWork.getOwnerIdAndProxyKey(convo: convo, asSender: asSender)
        set(property, uid: ownerId, convoKey: convo.key)
    }

    func set(_ property: SettableConvoProperty, for convos: [Convo], asSender: Bool) {
        convos.forEach { [weak self] in
            self?.set(property, for: $0, asSender: asSender)
        }
    }

    func set(_ property: SettableConvoProperty, uid: String, convoKey: String) {
        set(property.properties.value, at: Child.convos, uid, convoKey, property.properties.name)
    }

    func set(_ property: SettableMessageProperty, for message: Message) {
        var value: Any
        switch property {
        case .dateRead(let date):
            value = date.timeIntervalSince1970
        }
        set(value, at: Child.messages, message.parentConvoKey, message.messageId, property.properties.name)
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

    func set(_ property: SettableUserProperty, for uid: String) {
        var value: Any
        switch property {
        case .contact, .registrationToken:
            value = true
        default:
            value = property.properties.value
        }
        let rest = Firebase.getPath(uid: uid, userProperty: property)
        set(value, at: Child.users, rest)
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

    func updateReceiverForMessageReceived(convo: Convo, currentTime: Double, message: Message) {
        guard !convo.receiverDeletedProxy else {
            return
        }
        setUnreadMessage(message)
        switch message.data {
        case .text(let text):
            updateReceiverConvoForMessageReceived(convo: convo, currentTime: currentTime, text: text)
            updateReceiverProxyForMessageReceived(convo: convo, currentTime: currentTime, text: text)
        default:
            break
        }
    }
}

private extension GroupWork {
    static func getUnreadMessagesForProxy(uid: String,
                                          key: String,
                                          completion: @escaping (Result<[Message], Error>) -> Void) {
        do {
            try Shared.firebaseHelper.makeReference(Child.users, uid, Child.unreadMessages)
                .queryEqual(toValue: key)
                .queryOrdered(byChild: Child.receiverProxyKey)
                .observeSingleEvent(of: .value) { data in
                    completion(.success(data.asMessagesArray))
            }
        } catch {
            completion(.failure(error))
        }
    }

    func delete(_ first: String, _ rest: String...) {
        delete(first, rest)
    }

    func delete(_ first: String, _ rest: [String]) {
        start()
        Shared.firebaseHelper.delete(first, rest) { [weak self] error in
            self?.finish(withResult: error == nil)
        }
    }

    func increment(_ amount: Int, at first: String, _ rest: String...) {
        start()
        Shared.firebaseHelper.increment(by: amount, at: first, rest) { [weak self] error in
            self?.finish(withResult: error == nil)
        }
    }

    func set(_ value: Any, at first: String, _ rest: String...) {
        set(value, at: first, rest)
    }

    func set(_ value: Any, at first: String, _ rest: [String]) {
        start()
        Shared.firebaseHelper.set(value, at: first, rest) { [weak self] error in
            self?.finish(withResult: error == nil)
        }
    }

    func setUnreadMessage(_ message: Message) {
        set(message.asDictionary, at: Child.users, message.receiverId, Child.unreadMessages, message.messageId)
    }

    func updateReceiverConvoForMessageReceived(convo: Convo, currentTime: Double, text: String) {
        let convoUpdates: [String: Any] = [
            Child.hasUnreadMessage: true,
            Child.lastMessage: text,
            Child.timestamp: currentTime
        ]
        start()
        try? Shared.firebaseHelper.makeReference(Child.convos, convo.receiverId, convo.key)
            .updateChildValues(convoUpdates) { [weak self] error, _ in
                self?.finish(withResult: error == nil)
        }
    }

    func updateReceiverProxyForMessageReceived(convo: Convo, currentTime: Double, text: String) {
        let proxyUpdates: [String: Any] = [
            Child.hasUnreadMessage: true,
            Child.lastMessage: text,
            Child.timestamp: currentTime
        ]
        start()
        try? Shared.firebaseHelper.makeReference(Child.proxies, convo.receiverId, convo.receiverProxyKey)
            .updateChildValues(proxyUpdates) { [weak self] error, _ in
                self?.finish(withResult: error == nil)
        }
    }
}
