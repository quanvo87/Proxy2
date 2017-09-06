import FirebaseDatabase

struct DBMessage {
    typealias SendMessageCallback = ((message: Message, convo: Convo)?) -> Void

    static func read(_ message: Message, atDate date: Double = Date().timeIntervalSince1970, completion: @escaping (Success) -> Void) {
        let key = AsyncWorkGroupKey()
        key.delete(at: Child.UserInfo, message.receiverId, Child.unreadMessages, message.key)
        key.set(.dateRead(date), forMessage: message)
        key.set(.hasUnreadMessage(false), forConvoWithKey: message.parentConvo, ownerId: message.receiverId, proxyKey: message.receiverProxyKey)
        key.set(.read(true), forMessage: message)
        key.notify {
            key.setHasUnreadMessageForProxy(key: message.receiverProxyKey, ownerId: message.receiverId)
            key.notify {
                completion(key.workResult)
                key.finishWorkGroup()
            }
        }
    }

    static func sendMessage(from senderProxy: Proxy, to receiverProxy: Proxy, withText text: String, completion: @escaping SendMessageCallback) {
        let convoKey = DBConvo.makeConvoKey(senderProxy: senderProxy, receiverProxy: receiverProxy)

        DBConvo.getConvo(withKey: convoKey, belongingTo: senderProxy.ownerId) { (senderConvo) in
            if let senderConvo = senderConvo {
                sendMessage(text: text, mediaType: "", senderConvo: senderConvo, completion: completion)
            } else {
                DBConvo.makeConvo(sender: senderProxy, receiver: receiverProxy) { (convo) in
                    guard let senderConvo = convo else {
                        completion(nil)
                        return
                    }
                    sendMessage(text: text, mediaType: "", senderConvo: senderConvo, completion: completion)
                }
            }
        }
    }

    private static func sendMessage(text: String, mediaType: String, senderConvo: Convo, completion: @escaping SendMessageCallback) {
        guard let ref = DB.makeReference(Child.Messages, senderConvo.key) else {
            completion(nil)
            return
        }

        DBConvo.userIsPresent(user: senderConvo.receiverId, inConvoWithKey: senderConvo.key) { (receiverIsPresent) in
            let key = AsyncWorkGroupKey()
            let currentTime = Date().timeIntervalSince1970

            // Write message
            let dateRead = receiverIsPresent ? currentTime : 0.0
            let messageKey = ref.childByAutoId().key
            let message = Message(dateCreated: currentTime,
                                  dateRead: dateRead,
                                  key: messageKey,
                                  mediaType: mediaType,
                                  parentConvo: senderConvo.key,
                                  read: receiverIsPresent,
                                  receiverId: senderConvo.receiverId,
                                  receiverProxyKey: senderConvo.receiverProxyKey,
                                  senderId: senderConvo.senderId,
                                  text: text)
            key.set(message.toDictionary(), at: Child.Messages, message.parentConvo, message.key)

            // Receiver updates
            key.increment(by: 1, forProperty: .messagesReceived, forUser: senderConvo.receiverId)

            if !senderConvo.receiverDeletedProxy && !senderConvo.senderIsBlocked {
                key.set(.lastMessage(text), forProxyInConvo: senderConvo, asSender: false)
                key.set(.timestamp(currentTime), forProxyInConvo: senderConvo, asSender: false)

                if !receiverIsPresent {
                    key.set(.hasUnreadMessage(true), forProxyWithKey: message.receiverProxyKey, proxyOwner: message.receiverId)
                    key.set(message.toDictionary(), at: Child.UserInfo, message.receiverId, Child.unreadMessages, message.key)
                }
            }

            if !senderConvo.receiverDeletedProxy {
                key.set(.lastMessage(text), forConvo: senderConvo, asSender: false)
                key.set(.timestamp(currentTime), forConvo: senderConvo, asSender: false)

                if !receiverIsPresent {
                    key.set(.hasUnreadMessage(true), forConvo: senderConvo, asSender: false)
                }
            }

            if senderConvo.receiverLeftConvo {
                key.increment(by: 1, forProperty: .convoCount, forProxyInConvo: senderConvo, asSender: false)
                key.set(.receiverLeftConvo(false), forConvo: senderConvo, asSender: true)
                key.set(.senderLeftConvo(false), forConvo: senderConvo, asSender: false)
            }
            
            // Sender updates
            key.increment(by: 1, forProperty: .messagesSent, forUser: senderConvo.senderId)
            key.set(.lastMessage("You: \(text)"), forConvo: senderConvo, asSender: true)
            key.set(.lastMessage("You: \(text)"), forProxyInConvo: senderConvo, asSender: true)
            key.set(.timestamp(currentTime), forConvo: senderConvo, asSender: true)
            key.set(.timestamp(currentTime), forProxyInConvo: senderConvo, asSender: true)

            if senderConvo.senderLeftConvo {
                key.increment(by: 1, forProperty: .convoCount, forProxyInConvo: senderConvo, asSender: true)
                key.set(.receiverLeftConvo(false), forConvo: senderConvo, asSender: false)
                key.set(.senderLeftConvo(false), forConvo: senderConvo, asSender: true)
            }

            key.notify {
                defer {
                    key.finishWorkGroup()
                }

                guard key.workResult else {
                    completion(nil)
                    return
                }

                DBConvo.getConvo(withKey: senderConvo.key, belongingTo: senderConvo.senderId) { (convo) in
                    guard let convo = convo else {
                        completion(nil)
                        return
                    }
                    completion((message, convo))
                }
            }
        }
    }

    static func setMedia(for message: Message, mediaType: String, mediaURL: String, completion: @escaping (Success) -> Void) {
        let key = AsyncWorkGroupKey()
        key.set(.mediaType(mediaType), forMessage: message)
        key.set(.mediaURL(mediaURL), forMessage: message)
        key.notify {
            completion(key.workResult)
            key.finishWorkGroup()
        }
    }
}

extension DataSnapshot {
    func toMessagesArray() -> [Message] {
        var messages = [Message]()
        for child in self.children {
            if let message = Message((child as? DataSnapshot)?.value as AnyObject) {
                messages.append(message)
            }
        }
        return messages
    }
}

extension AsyncWorkGroupKey {
    func set(_ property: SettableMessageProperty, forMessage message: Message) {
        set(property.properties.value, at: Child.Messages, message.parentConvo, message.key, property.properties.name)
    }

    func setHasUnreadMessageForProxy(key: String, ownerId: String) {
        startWork()

        DBProxy.getUnreadMessagesForProxy(owner: ownerId, key: key) { (messages) in
            if let messageCount = messages?.count, messageCount <= 0 {
                self.set(.hasUnreadMessage(false), forProxyWithKey: key, proxyOwner: ownerId)
            }

            self.finishWork()
        }
    }
}
