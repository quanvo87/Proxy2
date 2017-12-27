import FirebaseDatabase
import GroupWork
import MessageKit

struct DBMessage {
    typealias SendMessageCallback = (Result<(message: Message, convo: Convo), ProxyError>) -> Void

    static func read(_ message: Message, atDate date: Date = Date(), completion: @escaping (Success) -> Void) {
        let work = GroupWork()
        work.delete(at: Child.userInfo, message.receiverId, Child.unreadMessages, message.messageId)
        work.set(.dateRead(date), forMessage: message)
        work.set(.hasUnreadMessage(false), forConvoWithKey: message.parentConvoKey, ownerId: message.receiverId, proxyKey: message.receiverProxyKey)
        work.setHasUnreadMessageForProxy(key: message.receiverProxyKey, ownerId: message.receiverId)
        work.allDone {
            completion(work.result)
        }
    }

    static func sendMessage(senderProxy: Proxy, receiverProxy: Proxy, text: String, completion: @escaping SendMessageCallback) {
        guard text.count < Setting.maxMessageSize else {
            completion(.failure(.inputTooLong))
            return
        }

        let convoKey = DBConvo.makeConvoKey(senderProxy: senderProxy, receiverProxy: receiverProxy)

        DBConvo.getConvo(withKey: convoKey, belongingTo: senderProxy.ownerId) { (senderConvo) in
            if let senderConvo = senderConvo {
                sendMessage(text: text, senderConvo: senderConvo, completion: completion)
            } else {
                DBConvo.makeConvo(sender: senderProxy, receiver: receiverProxy) { (convo) in
                    guard let senderConvo = convo else {
                        completion(.failure(.unknown))
                        return
                    }
                    sendMessage(text: text, senderConvo: senderConvo, completion: completion)
                }
            }
        }
    }

    static func sendMessage(text: String, senderConvo: Convo, completion: @escaping SendMessageCallback) {
        guard text.count < Setting.maxMessageSize else {
            completion(.failure(.inputTooLong))
            return
        }

        guard let ref = DB.makeReference(Child.messages, senderConvo.key) else {
            completion(.failure(.unknown))
            return
        }

        let message = Message(sender: Sender(id: senderConvo.senderId,
                                             displayName: senderConvo.senderProxyName),
                              messageId: ref.childByAutoId().key,
                              data: .text(text),
                              dateRead: Date.distantPast,
                              parentConvoKey: senderConvo.key,
                              receiverId: senderConvo.receiverId,
                              receiverProxyKey: senderConvo.receiverProxyKey)

        let work = GroupWork()

        work.set(message.toDictionary(), at: Child.messages, message.parentConvoKey, message.messageId)
        work.set(message.toDictionary(), at: Child.userInfo, message.receiverId, Child.unreadMessages, message.messageId)

        let currentTime = Date().timeIntervalSince1970

        // Receiver updates
        work.increment(by: 1, forProperty: .messagesReceived, forUser: senderConvo.receiverId)
        work.set(.hasUnreadMessage(true), forConvo: senderConvo, asSender: false)
        work.set(.hasUnreadMessage(true), forProxyWithKey: message.receiverProxyKey, proxyOwner: message.receiverId)
        work.set(.lastMessage(text), forConvo: senderConvo, asSender: false)
        work.set(.lastMessage(text), forProxyInConvo: senderConvo, asSender: false)
        work.set(.timestamp(currentTime), forConvo: senderConvo, asSender: false)
        work.set(.timestamp(currentTime), forProxyInConvo: senderConvo, asSender: false)

        // Sender updates
        work.increment(by: 1, forProperty: .messagesSent, forUser: senderConvo.senderId)
        work.set(.lastMessage("You: \(text)"), forConvo: senderConvo, asSender: true)
        work.set(.lastMessage("You: \(text)"), forProxyInConvo: senderConvo, asSender: true)
        work.set(.timestamp(currentTime), forConvo: senderConvo, asSender: true)
        work.set(.timestamp(currentTime), forProxyInConvo: senderConvo, asSender: true)

        work.allDone {
            if work.result {
                completion(.success((message, senderConvo)))
            } else {
                completion(.failure(.unknown))
            }
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

extension GroupWork {
    func set(_ property: SettableMessageProperty, forMessage message: Message) {
        switch property {
        case .dateRead(let date):
            set(date.timeIntervalSince1970, at: Child.messages, message.parentConvoKey, message.messageId, property.properties.name)
        }
    }

    func setHasUnreadMessageForProxy(key: String, ownerId: String) {
        start()
        DBProxy.getUnreadMessagesForProxy(owner: ownerId, key: key) { (messages) in
            if let messageCount = messages?.count, messageCount <= 0 {
                self.set(.hasUnreadMessage(false), forProxyWithKey: key, proxyOwner: ownerId)
            }
            self.finish(withResult: true)
        }
    }
}
