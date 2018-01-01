import GroupWork
import MessageKit

extension DB {
    typealias SendMessageCallback = (Result<(message: Message, convo: Convo), ProxyError>) -> Void

    static func deleteUnreadMessage(_ message: Message, completion: @escaping (Bool) -> Void) {
        let work = GroupWork()
        work.delete(at: Child.userInfo, message.receiverId, Child.unreadMessages, message.messageId)
        work.delete(at: Child.convos, message.receiverId, message.parentConvoKey)
        work.delete(at: Child.convos, message.receiverProxyKey, message.parentConvoKey)
        work.allDone {
            completion(work.result)
        }
    }

    static func read(_ message: Message, atDate date: Date = Date(), completion: @escaping (Bool) -> Void) {
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
        let convoKey = makeConvoKey(senderProxy: senderProxy, receiverProxy: receiverProxy)
        getConvo(withKey: convoKey, belongingTo: senderProxy.ownerId) { (senderConvo) in
            if let senderConvo = senderConvo {
                sendMessage(senderConvo: senderConvo, text: text, completion: completion)
            } else {
                makeConvo(convoKey: convoKey, sender: senderProxy, receiver: receiverProxy, completion: { (convo) in
                    guard let convo = convo else {
                        completion(.failure(.unknown))
                        return
                    }
                    sendMessage(senderConvo: convo, text: text, completion: completion)
                })
            }
        }
    }

    static func sendMessage(senderConvo: Convo, text: String, completion: @escaping SendMessageCallback) {
        guard text.count < Setting.maxMessageSize else {
            completion(.failure(.inputTooLong))
            return
        }
        guard let ref = makeReference(Child.messages, senderConvo.key) else {
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
        let currentTime = Date().timeIntervalSince1970
        // Receiver updates
        work.increment(by: 1, forProperty: .messagesReceived, forUser: senderConvo.receiverId)
        work.set(message.toDictionary(), at: Child.userInfo, message.receiverId, Child.unreadMessages, message.messageId)
        if !senderConvo.receiverDeletedProxy {
            work.set(.hasUnreadMessage(true), forConvo: senderConvo, asSender: false)
            work.set(.hasUnreadMessage(true), forProxyWithKey: message.receiverProxyKey, proxyOwner: message.receiverId)
            work.set(.timestamp(currentTime), forConvo: senderConvo, asSender: false)
            work.set(.timestamp(currentTime), forProxyInConvo: senderConvo, asSender: false)
            switch message.data {
            case .text(let s):
                work.set(.lastMessage(s), forConvo: senderConvo, asSender: false)
                work.set(.lastMessage(s), forProxyInConvo: senderConvo, asSender: false)
            default:
                break
            }
        }
        // Sender updates
        work.increment(by: 1, forProperty: .messagesSent, forUser: senderConvo.senderId)
        work.set(.timestamp(currentTime), forConvo: senderConvo, asSender: true)
        work.set(.timestamp(currentTime), forProxyInConvo: senderConvo, asSender: true)
        switch message.data {
        case .text(let s):
            work.set(.lastMessage("You: \(s)"), forConvo: senderConvo, asSender: true)
            work.set(.lastMessage("You: \(s)"), forProxyInConvo: senderConvo, asSender: true)
        default:
            break
        }
        work.allDone {
            if work.result {
                completion(.success((message, senderConvo)))
            } else {
                completion(.failure(.unknown))
            }
        }
    }

    private static func makeConvoKey(senderProxy: Proxy, receiverProxy: Proxy) -> String {
        return [senderProxy.key, senderProxy.ownerId, receiverProxy.key, receiverProxy.ownerId].sorted().joined()
    }

    private static func makeConvo(convoKey: String, sender: Proxy, receiver: Proxy, completion: @escaping (Convo?) -> Void) {
        let senderConvo = Convo(key: convoKey, receiverIcon: receiver.icon, receiverId: receiver.ownerId, receiverProxyKey: receiver.key, receiverProxyName: receiver.name, senderId: sender.ownerId, senderProxyKey: sender.key, senderProxyName: sender.name)
        let receiverConvo = Convo(key: convoKey, receiverIcon: sender.icon, receiverId: sender.ownerId, receiverProxyKey: sender.key, receiverProxyName: sender.name, senderId: receiver.ownerId, senderProxyKey: receiver.key, senderProxyName: receiver.name)
        let work = GroupWork()
        work.increment(by: 1, forProperty: .proxiesInteractedWith, forUser: receiver.ownerId)
        work.increment(by: 1, forProperty: .proxiesInteractedWith, forUser: sender.ownerId)
        work.set(receiverConvo, asSender: true)
        work.set(senderConvo, asSender: true)
        work.allDone {
            completion(work.result ? senderConvo : nil)
        }
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
        GroupWork.getUnreadMessagesForProxy(ownerId: ownerId, proxyKey: key) { (messages) in
            if let messageCount = messages?.count, messageCount <= 0 {
                self.set(.hasUnreadMessage(false), forProxyWithKey: key, proxyOwner: ownerId)
            }
            self.finish(withResult: true)
        }
    }
}
