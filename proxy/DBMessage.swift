struct DBMessage {
    typealias SendMessageCallback = ((message: Message, convo: Convo)?) -> Void

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

            // Receiver updates
            key.increment(by: 1, forProperty: .messagesReceived, forUser: senderConvo.receiverId)

            if !senderConvo.receiverDeletedProxy && !senderConvo.senderIsBlocked {
                key.set(.lastMessage(text), forProxyInConvo: senderConvo, asSender: false)
                key.set(.timestamp(currentTime), forProxyInConvo: senderConvo, asSender: false)

                if !receiverIsPresent {
                    key.increment(by: 1, forProperty: .unreadCount, forProxyInConvo: senderConvo, asSender: false)
                    key.increment(by: 1, forProperty: .unreadCount, forUser: senderConvo.receiverId)
                }
            }

            if !senderConvo.receiverDeletedProxy {
                key.set(.lastMessage(text), forConvo: senderConvo, asSender: false)
                key.set(.timestamp(currentTime), forConvo: senderConvo, asSender: false)

                if !receiverIsPresent {
                    key.increment(by: 1, forProperty: .unreadCount, forConvo: senderConvo, asSender: false)
                }
            }

            if senderConvo.receiverLeftConvo {
                key.increment(by: 1, forProperty: .convoCount, forProxyInConvo: senderConvo, asSender: false)
                key.set(.receiverLeftConvo(false), forConvo: senderConvo, asSender: true)
                key.set(.senderLeftConvo(false), forConvo: senderConvo, asSender: false)
            }

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

    static func setRead(forMessage message: Message, atDate date: Double = Date().timeIntervalSince1970, completion: @escaping (Success) -> Void) {
        let key = AsyncWorkGroupKey()
        key.increment(by: -1, forProperty: .unreadCount, forConvoWithKey: message.parentConvo, ownerId: message.receiverId, proxyKey: message.receiverProxyKey)
        key.increment(by: -1, forProperty: .unreadCount, forProxyWithKey: message.receiverProxyKey, ownerId: message.receiverId)
        key.increment(by: -1, forProperty: .unreadCount, forUser: message.receiverId)
        key.set(.dateRead(date), forMessage: message)
        key.set(.read(true), forMessage: message)
        key.notify {
            completion(key.workResult)
            key.finishWorkGroup()
        }
    }
}
