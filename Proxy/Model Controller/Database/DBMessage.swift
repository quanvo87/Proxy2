import GroupWork
import MessageKit

extension FirebaseHelper {
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
                makeConvo(convoKey: convoKey, sender: sender, receiver: receiver) { (convo) in
                    guard let convo = convo else {
                        completion(.failure(.unknown))
                        return
                    }
                    sendMessage(convo: convo, text: text, completion: completion)
                }
            }
        }
    }

    static func sendMessage(convo: Convo, text: String, completion: @escaping SendMessageCallback) {
        guard !convo.receiverDeletedProxy else {
            completion(.failure(.receiverDeletedProxy))
            return
        }
        let trimmedText = text.trimmed
        guard trimmedText.count < Setting.maxMessageSize else {
            completion(.failure(.inputTooLong))
            return
        }
        guard let ref = makeReference(Child.messages, convo.key) else {
            completion(.failure(.unknown))
            return
        }
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
        work.setReceiverMessageValues(convo: convo, currentTime: currentTime, message: message)
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
        let senderConvo = Convo(key: convoKey,
                                receiverIcon: receiver.icon,
                                receiverId: receiver.ownerId,
                                receiverProxyKey: receiver.key,
                                receiverProxyName: receiver.name,
                                senderIcon: sender.icon,
                                senderId: sender.ownerId,
                                senderProxyKey: sender.key,
                                senderProxyName: sender.name)
        let receiverConvo = Convo(key: convoKey,
                                  receiverIcon: sender.icon,
                                  receiverId: sender.ownerId,
                                  receiverProxyKey: sender.key,
                                  receiverProxyName: sender.name,
                                  senderIcon: receiver.icon,
                                  senderId: receiver.ownerId,
                                  senderProxyKey: receiver.key,
                                  senderProxyName: receiver.name)
        let work = GroupWork()
        work.increment(1, property: .proxiesInteractedWith, uid: receiver.ownerId)
        work.increment(1, property: .proxiesInteractedWith, uid: sender.ownerId)
        work.set(senderConvo, asSender: true)
        work.setReceiverConvo(receiverConvo)
        work.allDone {
            completion(work.result ? senderConvo : nil)
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

    func setReceiverConvo(_ convo: Convo) {
        start()
        FirebaseHelper.set(convo.toDictionary(), at: Child.convos, convo.senderId, convo.key) { (success) in
            self.finish(withResult: success)
//            Database.getProxy(uid: convo.senderId, key: convo.senderProxyKey) { (proxy) in
//                if proxy == nil {
//                    DB.delete(convo, asSender: true) {_ in }
//                }
//            }
        }
    }

    func setReceiverMessageValues(convo: Convo, currentTime: Double, message: Message) {
        guard !convo.receiverDeletedProxy else {
            return
        }
        switch message.data {
        case .text(let text):
            start()
            FirebaseHelper.set(message.toDictionary(), at: Child.userInfo, message.receiverId, Child.unreadMessages, message.messageId) { (success) in
                self.finish(withResult: success)
//                Database.getProxy(uid: message.receiverId, key: message.receiverProxyKey) { (proxy) in
//                    if proxy == nil {
//                        DB.delete(Child.userInfo, message.receiverId, Child.unreadMessages, message.messageId) { _ in }
//                        let work = GroupWork()
//                        work.set(.receiverDeletedProxy(true), for: convo, asSender: true)
//                        work.allDone {}
//                    }
//                }
            }
            let convoUpdates: [String: Any] = [Child.hasUnreadMessage: true,
                                               Child.lastMessage: text,
                                               Child.timestamp: currentTime]
            start()
            FirebaseHelper.makeReference(Child.convos, convo.receiverId, convo.key)?
                .updateChildValues(convoUpdates) { (error, _) in
                    self.finish(withResult: error == nil)
                    FirebaseHelper.getConvo(uid: convo.receiverId, key: convo.key) { (receiverConvo) in
                        if receiverConvo == nil {
                            FirebaseHelper.delete(Child.convos, convo.receiverId, convo.key) { _ in }
                        }
                    }
            }
            let proxyUpdates: [String: Any] = [Child.hasUnreadMessage: true,
                                               Child.lastMessage: text,
                                               Child.timestamp: currentTime]
            start()
            FirebaseHelper.makeReference(Child.proxies, convo.receiverId, convo.receiverProxyKey)?
                .updateChildValues(proxyUpdates) { (error, _) in
                    self.finish(withResult: error == nil)
//                    Database.getProxy(uid: convo.receiverId, key: convo.receiverProxyKey) { (proxy) in
//                        if proxy == nil {
//                            DB.delete(Child.proxies, convo.receiverId, convo.receiverProxyKey) { _ in }
//                            let work = GroupWork()
//                            work.set(.receiverDeletedProxy(true), for: convo, asSender: true)
//                            work.allDone {}
//                        }
//                    }
            }
        default:
            break
        }
    }
}
