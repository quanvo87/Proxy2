struct DBMessage {
    typealias SendMessageCallback = (convo: Convo, message: Message)?

    static func sendMessage(from senderProxy: Proxy, to receiverProxy: Proxy, withText text: String, completion: @escaping (SendMessageCallback) -> Void) {
        let convoKey = DBConvo.makeConvoKey(senderProxy: senderProxy, receiverProxy: receiverProxy)

        DBConvo.getConvo(withKey: convoKey, belongingTo: senderProxy.ownerId) { (senderConvo) in
            if let senderConvo = senderConvo {
                sendMessage(text: text, mediaType: "", senderConvo: senderConvo, completion: completion)
            } else {
                DBConvo.makeConvo(senderProxy: senderProxy, receiverProxy: receiverProxy) { (senderConvo) in
                    guard let senderConvo = senderConvo else {
                        completion(nil)
                        return
                    }
                    sendMessage(text: text, mediaType: "", senderConvo: senderConvo, completion: completion)
                }
            }
        }
    }

    // TODO: - make mediaType an enum
    private static func sendMessage(text: String, mediaType: String, senderConvo: Convo, completion: @escaping (SendMessageCallback) -> Void) {
        guard let ref = DB.ref(Path.Messages, senderConvo.key) else {
            completion(nil)
            return
        }

        DBConvo.userIsPresent(user: senderConvo.receiverId, inConvoWithKey: senderConvo.key) { (receiverIsPresent) in
            let key = AsyncWorkGroupKey()
            let currentTime = Date().timeIntervalSince1970

            // Sender updates
            key.incrementMessagesSent(forUser: senderConvo.senderId)

            key.set(.message("You: \(text)"), forConvo: senderConvo, asSender: true)
            key.set(.message("You: \(text)"), forSenderProxyInConvo: senderConvo)
            key.set(.timestamp(currentTime), forConvo: senderConvo, asSender: true)
            key.set(.timestamp(currentTime), forSenderProxyInConvo: senderConvo)

            if senderConvo.senderLeftConvo {
                key.increment(by: 1, forProperty: .convos, forSenderProxyInConvo: senderConvo)
                key.set(.receiverLeftConvo(false), forConvo: senderConvo, asSender: false)
                key.set(.senderLeftConvo(false), forConvo: senderConvo, asSender: true)
            }

            // Receiver updates
            key.incrementMessagesReceived(forUser: senderConvo.receiverId)

            if !senderConvo.receiverDeletedProxy && !senderConvo.senderIsBlocked {
                key.set(.message(text), forReceiverProxyInConvo: senderConvo)
                key.set(.timestamp(currentTime), forReceiverProxyInConvo: senderConvo)

                if !receiverIsPresent {
                    key.incrementUnread(forReceiverOfConvo: senderConvo)
                    key.increment(by: 1, forProperty: .unread, forReceiverProxyInConvo: senderConvo)
                }
            }

            if !senderConvo.receiverDeletedProxy {
                key.set(.message(text), forConvo: senderConvo, asSender: false)
                key.set(.timestamp(currentTime), forConvo: senderConvo, asSender: false)

                if !receiverIsPresent {
                    key.increment(by: 1, forProperty: .unread, forConvo: senderConvo, asSender: false)
                }
            }

            if senderConvo.receiverLeftConvo {
                key.increment(by: 1, forProperty: .convos, forReceiverProxyInConvo: senderConvo)
                key.set(.receiverLeftConvo(false), forConvo: senderConvo, asSender: true)
                key.set(.senderLeftConvo(false), forConvo: senderConvo, asSender: false)
            }

            // Write message
            let messageKey = ref.childByAutoId().key
            let dateRead = receiverIsPresent ? currentTime : 0.0
            let message = Message(dateCreated: currentTime,
                                  dateRead: dateRead,
                                  key: messageKey,
                                  mediaType: mediaType,
                                  parentConvo: senderConvo.key,
                                  read: receiverIsPresent,
                                  senderId: senderConvo.senderId,
                                  text: text)
            key.setMessage(message)

            key.notify {
                if key.workResult {
                    DBConvo.getConvo(withKey: senderConvo.key, belongingTo: senderConvo.senderId) { (convo) in
                        if let convo = convo {
                            completion((convo, message))
                        } else {
                            completion(nil)
                        }
                    }
                } else {
                    completion(nil)
                }

                key.finishWorkGroup()
            }
        }
    }
}

extension AsyncWorkGroupKey {
    func incrementMessagesReceived(by amount: Int = 1, forUser uid: String) {
        increment(by: amount, at: Path.UserInfo, uid, Path.MessagesReceived)
    }

    func incrementMessagesSent(by amount: Int = 1, forUser uid: String) {
        increment(by: amount, at: Path.UserInfo, uid, Path.MessagesSent)
    }

    func incrementUnread(by amount: Int = 1, forReceiverOfConvo convo: Convo) {
        increment(by: amount, at: Path.UserInfo, convo.receiverId, Path.Unread)
    }

    func setMessage(_ message: Message) {
        set(message.toDictionary(), at: Path.Messages, message.parentConvo, message.key)
    }
}
