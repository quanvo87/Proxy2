import GroupWork
import MessageKit

extension DB {
    typealias SendMessageCallback = (Result<(message: Message, convo: Convo), ProxyError>) -> Void

    static func deleteUnreadMessage(_ message: Message, completion: @escaping (Bool) -> Void) {
        let work = GroupWork()
        work.delete(Child.userInfo, message.receiverId, Child.unreadMessages, message.messageId)
        work.delete(Child.convos, message.receiverId, message.parentConvoKey)
        work.allDone {
            completion(work.result)
        }
    }

    static func read(_ message: Message, date: Date = Date(), completion: @escaping (Bool) -> Void) {
        let work = GroupWork()
        work.delete(Child.userInfo, message.receiverId, Child.unreadMessages, message.messageId)
        work.set(.dateRead(date), for: message)
        work.set(.hasUnreadMessage(false), uid: message.receiverId, convoKey: message.parentConvoKey)
        work.setHasUnreadMessageForProxy(uid: message.receiverId, key: message.receiverProxyKey)
        work.allDone {
            completion(work.result)
        }
    }

    static func sendMessage(sender: Proxy, receiver: Proxy, text: String, completion: @escaping SendMessageCallback) {
        let convoKey = makeConvoKey(sender: sender, receiver: receiver)
        getConvo(uid: sender.ownerId, key: convoKey) { (convo) in
            if let convo = convo {
                sendMessage(convo: convo, text: text, completion: completion)
            } else {
                makeConvo(convoKey: convoKey, sender: sender, receiver: receiver, completion: { (convo) in
                    guard let convo = convo else {
                        completion(.failure(.unknown))
                        return
                    }
                    sendMessage(convo: convo, text: text, completion: completion)
                })
            }
        }
    }

    static func sendMessage(convo: Convo, text: String, completion: @escaping SendMessageCallback) {
        guard !convo.receiverDeletedProxy else {
            completion(.failure(.receiverDeletedProxy))
            return
        }
        let trimmedText = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard trimmedText.count < Setting.maxMessageSize else {
            completion(.failure(.inputTooLong))
            return
        }
        guard let ref = makeReference(Child.messages, convo.key) else {
            completion(.failure(.unknown))
            return
        }
        updateReceiverDeletedProxy(convo: convo)
        let message = Message(sender: Sender(id: convo.senderId,
                                             displayName: convo.senderProxyName),
                              messageId: ref.childByAutoId().key,
                              data: .text(trimmedText),
                              dateRead: Date.distantPast,
                              parentConvoKey: convo.key,
                              receiverId: convo.receiverId,
                              receiverProxyKey: convo.receiverProxyKey,
                              senderProxyKey: convo.senderProxyKey)
        let work = GroupWork()
        work.set(message.toDictionary(), at: Child.messages, message.parentConvoKey, message.messageId)
        let currentTime = Date().timeIntervalSince1970
        // Receiver updates
        work.increment(1, property: .messagesReceived, uid: convo.receiverId)
        work.set(message.toDictionary(), at: Child.userInfo, message.receiverId, Child.unreadMessages, message.messageId)
        if !convo.receiverDeletedProxy {
            work.set(.hasUnreadMessage(true), for: convo, asSender: false)
            work.set(.hasUnreadMessage(true), uid: message.receiverId, proxyKey: message.receiverProxyKey)
            work.set(.timestamp(currentTime), for: convo, asSender: false)
            work.set(.timestamp(currentTime), forProxyIn: convo, asSender: false)
            switch message.data {
            case .text(let s):
                work.set(.lastMessage(s), for: convo, asSender: false)
                work.set(.lastMessage(s), forProxyIn: convo, asSender: false)
            default:
                break
            }
        }
        // Sender updates
        work.increment(1, property: .messagesSent, uid: convo.senderId)
        work.set(.timestamp(currentTime), for: convo, asSender: true)
        work.set(.timestamp(currentTime), forProxyIn: convo, asSender: true)
        switch message.data {
        case .text(let s):
            work.set(.lastMessage("You: \(s)"), for: convo, asSender: true)
            work.set(.lastMessage("You: \(s)"), forProxyIn: convo, asSender: true)
        default:
            break
        }
        work.allDone {
            if work.result {
                completion(.success((message, convo)))
            } else {
                completion(.failure(.unknown))
            }
        }
    }

    private static func makeConvoKey(sender: Proxy, receiver: Proxy) -> String {
        return [sender.key, sender.ownerId, receiver.key, receiver.ownerId].sorted().joined()
    }

    private static func makeConvo(convoKey: String, sender: Proxy, receiver: Proxy, completion: @escaping (Convo?) -> Void) {
        let senderConvo = Convo(key: convoKey, receiverIcon: receiver.icon, receiverId: receiver.ownerId, receiverProxyKey: receiver.key, receiverProxyName: receiver.name, senderId: sender.ownerId, senderProxyKey: sender.key, senderProxyName: sender.name)
        let receiverConvo = Convo(key: convoKey, receiverIcon: sender.icon, receiverId: sender.ownerId, receiverProxyKey: sender.key, receiverProxyName: sender.name, senderId: receiver.ownerId, senderProxyKey: receiver.key, senderProxyName: receiver.name)
        let work = GroupWork()
        work.increment(1, property: .proxiesInteractedWith, uid: receiver.ownerId)
        work.increment(1, property: .proxiesInteractedWith, uid: sender.ownerId)
        work.set(receiverConvo, asSender: true)
        work.set(senderConvo, asSender: true)
        work.allDone {
            completion(work.result ? senderConvo : nil)
        }
    }

    private static func updateReceiverDeletedProxy(convo: Convo) {
        getConvo(uid: convo.receiverId, key: convo.key) { (receiverConvo) in
            if receiverConvo == nil {
                let work = GroupWork()
                work.set(.receiverDeletedProxy(true), for: convo, asSender: true)
                work.allDone {}
            }
        }
    }
}

extension GroupWork {
    func set(_ property: SettableMessageProperty, for message: Message) {
        switch property {
        case .dateRead(let date):
            set(date.timeIntervalSince1970, at: Child.messages, message.parentConvoKey, message.messageId, property.properties.name)
        }
    }

    func setHasUnreadMessageForProxy(uid: String, key: String) {
        start()
        GroupWork.getUnreadMessagesForProxy(uid: uid, key: key) { (messages) in
            if let messageCount = messages?.count, messageCount <= 0 {
                self.set(.hasUnreadMessage(false), uid: uid, proxyKey: key)
            }
            self.finish(withResult: true)
        }
    }
}
