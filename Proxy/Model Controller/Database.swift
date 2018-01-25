import FirebaseDatabase
import GroupWork
import MessageKit

enum Result<T, Error> {
    case success(T)
    case failure(Error)
}

enum IncrementableUserProperty: String {
    case messagesReceived
    case messagesSent
    case proxiesInteractedWith
}

protocol Database {
    typealias ConvoCallback = (Result<Convo, Error>) -> Void
    typealias ErrorCallback = (Error?) -> Void
    typealias MessageCallback = (Result<(convo: Convo, message: Message), Error>) -> Void
    typealias ProxyCallback = (Result<Proxy, Error>) -> Void
    init(_ settings: [String: Any])
    func delete(_ proxy: Proxy, completion: @escaping ErrorCallback)
    func deleteUnreadMessage(_ message: Message, completion: @escaping ErrorCallback)
    func getConvo(key: String, ownerId: String, completion: @escaping ConvoCallback)
    func getProxy(key: String, completion: @escaping ProxyCallback)
    func getProxy(key: String, ownerId: String, completion: @escaping ProxyCallback)
    func makeProxy(ownerId: String, completion: @escaping ProxyCallback)
    func read(_ message: Message, at date: Date, completion: @escaping ErrorCallback)
    func sendMessage(sender: Proxy, receiver: Proxy, text: String, completion: @escaping MessageCallback)
    func sendMessage(convo: Convo, text: String, completion: @escaping MessageCallback)
    func setIcon(to icon: String, for proxy: Proxy, completion: @escaping ErrorCallback)
    func setNickname(to nickname: String, for proxy: Proxy, completion: @escaping ErrorCallback)
    func setReceiverNickname(to nickname: String, for convo: Convo, completion: @escaping ErrorCallback)
}

class Firebase: Database {
    private let generator: ProxyPropertyGenerating
    private let maxMessageSize: Int
    private let maxNameSize: Int
    private let makeProxyRetries: Int

    required init(_ settings: [String: Any] = [:]) {
        generator = settings["generator"] as? ProxyPropertyGenerating ?? ProxyPropertyGenerator()
        maxMessageSize = settings["maxMessageSize"] as? Int ?? Setting.maxMessageSize
        maxNameSize = settings["makeNameSize"] as? Int ?? Setting.maxNameSize
        makeProxyRetries = settings["makeProxyRetries"] as? Int ?? Setting.makeProxyRetries
    }

    func delete(_ proxy: Proxy, completion: @escaping ErrorCallback) {
        getConvosForProxy(key: proxy.key, ownerId: proxy.ownerId) { (convos) in
            guard let convos = convos else {
                completion(ProxyError.unknown)
                return
            }
            let work = GroupWork()
            work.delete(Child.proxies, proxy.ownerId, proxy.key)
            work.delete(Child.proxyNames, proxy.key)
            work.delete(convos)
            work.deleteUnreadMessages(for: proxy)
            work.setReceiverDeletedProxy(for: convos)
            work.allDone {
                completion(work.result ? nil : ProxyError.unknown)
            }
        }
    }

    func deleteUnreadMessage(_ message: Message, completion: @escaping ErrorCallback) {
        let work = GroupWork()
        work.delete(Child.userInfo, message.receiverId, Child.unreadMessages, message.messageId)
        work.delete(Child.convos, message.receiverId, message.parentConvoKey)
        work.allDone {
            completion(work.result ? nil : ProxyError.unknown)
        }
    }

    func getConvo(key: String, ownerId: String, completion: @escaping ConvoCallback) {
        FirebaseHelper.get(Child.convos, ownerId, key) { (data) in
            guard
                let data = data,
                let convo = Convo(data) else {
                    completion(.failure(ProxyError.unknown))
                    return
            }
            completion(.success(convo))
        }
    }

    func getProxy(key: String, completion: @escaping ProxyCallback) {
        FirebaseHelper.get(Child.proxyNames, key.lowercased().noWhiteSpaces) { (data) in
            guard
                let data = data,
                let proxy = Proxy(data) else {
                    completion(.failure(ProxyError.unknown))
                    return
            }
            self.getProxy(key: proxy.key, ownerId: proxy.ownerId, completion: completion)
        }
    }

    func getProxy(key: String, ownerId: String, completion: @escaping ProxyCallback) {
        FirebaseHelper.get(Child.proxies, ownerId, key) { (data) in
            guard
                let data = data,
                let proxy = Proxy(data) else {
                    completion(.failure(ProxyError.unknown))
                    return
            }
            completion(.success(proxy))
        }
    }

    func makeProxy(ownerId: String, completion: @escaping ProxyCallback) {
        makeProxy(ownerId: ownerId, attempt: 0, completion: completion)
    }

    private func makeProxy(ownerId: String, attempt: Int, completion: @escaping ProxyCallback) {
        guard let ref = FirebaseHelper.makeReference(Child.proxyNames) else {
            completion(.failure(ProxyError.unknown))
            return
        }
        let name = generator.randomProxyName
        let proxy = Proxy(icon: generator.randomIconName, name: name, ownerId: ownerId)
        let testKey = ref.childByAutoId().key
        FirebaseHelper.set(proxy.toDictionary(), at: Child.proxyNames, testKey) { [weak self] (success) in
            guard success else {
                completion(.failure(ProxyError.unknown))
                return
            }
            self?.getProxyNameCount(ref: ref, name: name) { (count) in
                FirebaseHelper.delete(Child.proxyNames, testKey) { _ in }
                guard let _self = self else {
                    return
                }
                if count == 1 {
                    let work = GroupWork()
                    work.set(proxy.toDictionary(), at: Child.proxies, proxy.ownerId, proxy.key)
                    work.set(proxy.toDictionary(), at: Child.proxyNames, proxy.key)
                    work.allDone {
                        completion(work.result ? .success(proxy) : .failure(ProxyError.unknown))
                    }
                } else {
                    if attempt < _self.makeProxyRetries {
                        self?.makeProxy(ownerId: ownerId, attempt: attempt + 1, completion: completion)
                    } else {
                        completion(.failure(ProxyError.unknown))
                    }
                }
            }
        }
    }

    private func getProxyNameCount(ref: DatabaseReference, name: String, completion: @escaping (UInt?) -> Void) {
        ref.queryOrdered(byChild: Child.name).queryEqual(toValue: name).observeSingleEvent(of: .value) { (data) in
            completion(data.childrenCount)
        }
    }

    func read(_ message: Message, at date: Date, completion: @escaping ErrorCallback) {
        let work = GroupWork()
        work.delete(Child.userInfo, message.receiverId, Child.unreadMessages, message.messageId)
        work.set(.dateRead(date), for: message)
        work.set(.hasUnreadMessage(false), uid: message.receiverId, convoKey: message.parentConvoKey)
        work.setHasUnreadMessageForProxy(uid: message.receiverId, key: message.receiverProxyKey)
        work.allDone {
            completion(work.result ? nil : ProxyError.unknown)
        }
    }

    func sendMessage(sender: Proxy, receiver: Proxy, text: String, completion: @escaping MessageCallback) {
        let convoKey = makeConvoKey(sender: sender, receiver: receiver)
        getConvo(key: convoKey, ownerId: sender.ownerId) { [weak self] (result) in
            switch result {
            case .failure:
                self?.makeConvo(convoKey: convoKey, sender: sender, receiver: receiver) { (result) in
                    switch result {
                    case .failure(let error):
                        completion(.failure(error))
                        return
                    case .success(let convo):
                        self?.sendMessage(convo: convo, text: text, completion: completion)
                    }
                }
            case .success(let convo):
                self?.sendMessage(convo: convo, text: text, completion: completion)
            }
        }
    }

    private func makeConvoKey(sender: Proxy, receiver: Proxy) -> String {
        return [sender.key, sender.ownerId, receiver.key, receiver.ownerId].sorted().joined()
    }

    private func makeConvo(convoKey: String, sender: Proxy, receiver: Proxy, completion: @escaping ConvoCallback) {
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
            completion(work.result ? .success(senderConvo) : .failure(ProxyError.unknown))
        }
    }

    func sendMessage(convo: Convo, text: String, completion: @escaping MessageCallback) {
        guard !convo.receiverDeletedProxy else {
            completion(.failure(ProxyError.receiverDeletedProxy))
            return
        }
        let trimmedText = text.trimmed
        guard trimmedText.count < maxMessageSize else {
            completion(.failure(ProxyError.inputTooLong))
            return
        }
        guard let ref = FirebaseHelper.makeReference(Child.messages, convo.key) else {
            completion(.failure(ProxyError.unknown))
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
                completion(.success((convo, message)))
            } else {
                completion(.failure(ProxyError.unknown))
            }
        }
    }

    func setIcon(to icon: String, for proxy: Proxy, completion: @escaping ErrorCallback) {
        getConvosForProxy(key: proxy.key, ownerId: proxy.ownerId) { (convos) in
            guard let convos = convos else {
                completion(ProxyError.unknown)
                return
            }
            let work = GroupWork()
            work.set(.icon(icon), for: proxy)
            work.setReceiverIcon(to: icon, for: convos)
            work.setSenderIcon(to: icon, for: convos)
            work.allDone {
                completion(work.result ? nil : ProxyError.unknown)
            }
        }
    }

    func setNickname(to nickname: String, for proxy: Proxy, completion: @escaping ErrorCallback) {
        getConvosForProxy(key: proxy.key, ownerId: proxy.ownerId) { (convos) in
            guard let convos = convos else {
                completion(ProxyError.unknown)
                return
            }
            let work = GroupWork()
            work.set(.nickname(nickname), for: proxy)
            work.setSenderNickname(to: nickname, for: convos)
            work.allDone {
                completion(work.result ? nil : ProxyError.unknown)
            }
        }
    }

    func setReceiverNickname(to nickname: String, for convo: Convo, completion: @escaping ErrorCallback) {
        guard nickname.count < maxNameSize else {
            completion(ProxyError.inputTooLong)
            return
        }
        let work = GroupWork()
        work.set(.receiverNickname(nickname), for: convo, asSender: true)
        work.allDone {
            completion(work.result ? nil : ProxyError.unknown)
        }
    }

    private func getConvosForProxy(key: String, ownerId: String, completion: @escaping ([Convo]?) -> Void) {
        FirebaseHelper.get(Child.convos, ownerId) { (data) in
            completion(data?.toConvosArray(uid: ownerId, proxyKey: key))
        }
    }
}

private extension String {
    var noWhiteSpaces: String {
        return components(separatedBy: .whitespacesAndNewlines).joined()
    }
}
