import FirebaseDatabase
import GroupWork
import MessageKit
import WQNetworkActivityIndicator

enum IncrementableUserProperty: String {
    case messagesReceived
    case messagesSent
    case proxiesInteractedWith
}

enum SettableUserProperty {
    case registrationToken(String)
    case soundOn(Bool)

    var properties: (name: String, value: Any) {
        switch self {
        case .registrationToken(let value):
            return ("registrationToken", value)
        case .soundOn(let value):
            return (Constant.soundOn, value)
        }
    }
}

protocol Database {
    typealias ConvoCallback = (Result<Convo, Error>) -> Void
    typealias DataCallback = (Result<DataSnapshot, Error>) -> Void
    typealias ErrorCallback = (Error?) -> Void
    typealias MessageCallback = (Result<(convo: Convo, message: Message), Error>) -> Void
    typealias ProxyCallback = (Result<Proxy, Error>) -> Void
    init(_ options: [String: Any])
    func delete(userProperty: SettableUserProperty, for uid: String, completion: @escaping ErrorCallback)
    func deleteProxy(_ proxy: Proxy, completion: @escaping ErrorCallback)
    func get(userProperty: SettableUserProperty, for uid: String, completion: @escaping DataCallback)
    func getConvo(convoKey: String, ownerId: String, completion: @escaping ConvoCallback)
    func getProxy(proxyKey: String, completion: @escaping ProxyCallback)
    func getProxy(proxyKey: String, ownerId: String, completion: @escaping ProxyCallback)
    func makeProxy(currentProxyCount: Int, ownerId: String, completion: @escaping ProxyCallback)
    func read(_ message: Message, at date: Date, completion: @escaping ErrorCallback)
    func sendMessage(sender: Proxy, receiver: Proxy, text: String, completion: @escaping MessageCallback)
    func sendMessage(convo: Convo, text: String, completion: @escaping MessageCallback)
    func set(userProperty: SettableUserProperty, for uid: String, completion: @escaping ErrorCallback)
    func setIcon(to icon: String, for proxy: Proxy, completion: @escaping ErrorCallback)
    func setNickname(to nickname: String, for proxy: Proxy, completion: @escaping ErrorCallback)
    func setReceiverNickname(to nickname: String, for convo: Convo, completion: @escaping ErrorCallback)
}

class Firebase: Database {
    private let generator: ProxyPropertyGenerating
    private let makeProxyRetries: Int
    private let maxMessageSize: Int
    private let maxNameSize: Int
    private let maxProxyCount: Int
    private var isMakingProxy = false

    // swiftlint:disable line_length
    required init(_ options: [String: Any] = [:]) {
        generator = options[DatabaseOption.generator.name] as? ProxyPropertyGenerating ?? DatabaseOption.generator.value
        makeProxyRetries = options[DatabaseOption.makeProxyRetries.name] as? Int ?? DatabaseOption.makeProxyRetries.value
        maxMessageSize = options[DatabaseOption.maxMessageSize.name] as? Int ?? DatabaseOption.maxMessageSize.value
        maxNameSize = options[DatabaseOption.maxNameSize.name] as? Int ?? DatabaseOption.maxNameSize.value
        maxProxyCount = options[DatabaseOption.maxProxyCount.name] as? Int ?? DatabaseOption.maxProxyCount.value
    }
    // swiftlint:enable line_length

    func delete(userProperty: SettableUserProperty, for uid: String, completion: @escaping ErrorCallback) {
        switch userProperty {
        case .registrationToken(let registrationToken):
            Constant.firebaseHelper.delete(Child.users, uid, Child.registrationTokens, registrationToken) { error in
                completion(error)
            }
        default:
            Constant.firebaseHelper.delete(Child.users, uid, userProperty.properties.name) { error in
                completion(error)
            }
        }
    }

    func deleteProxy(_ proxy: Proxy, completion: @escaping ErrorCallback) {
        getConvosForProxy(key: proxy.key, ownerId: proxy.ownerId) { result in
            switch result {
            case .failure(let error):
                completion(error)
            case .success(let convos):
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
    }

    func get(userProperty: SettableUserProperty, for uid: String, completion: @escaping DataCallback) {
        Constant.firebaseHelper.get(Child.users, uid, userProperty.properties.name) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let data):
                completion(.success(data))
            }
        }
    }

    func getConvo(convoKey: String, ownerId: String, completion: @escaping ConvoCallback) {
        Constant.firebaseHelper.get(Child.convos, ownerId, convoKey) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let data):
                do {
                    completion(.success(try Convo(data)))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }

    func getProxy(proxyKey: String, completion: @escaping ProxyCallback) {
        Constant.firebaseHelper.get(
            Child.proxyNames,
            proxyKey.lowercased().withoutWhiteSpacesAndNewLines) { [weak self] result in
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let data):
                    do {
                        let proxy = try Proxy(data)
                        self?.getProxy(proxyKey: proxy.key, ownerId: proxy.ownerId, completion: completion)
                    } catch {
                        completion(.failure(error))
                    }
                }
        }
    }

    func getProxy(proxyKey: String, ownerId: String, completion: @escaping ProxyCallback) {
        Constant.firebaseHelper.get(Child.proxies, ownerId, proxyKey) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let data):
                do {
                    completion(.success(try Proxy(data)))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }

    func makeProxy(currentProxyCount: Int, ownerId: String, completion: @escaping ProxyCallback) {
        Haptic.makeSuccess()
        guard !isMakingProxy else {
            return
        }
        guard currentProxyCount < maxProxyCount else {
            completion(.failure(ProxyError.tooManyProxies))
            return
        }
        isMakingProxy = true
        WQNetworkActivityIndicator.shared.show()
        makeProxy(ownerId: ownerId, attempt: 0) { [weak self] result in
            WQNetworkActivityIndicator.shared.hide()
            self?.isMakingProxy = false
            completion(result)
        }
    }

    private func makeProxy(ownerId: String, attempt: Int, completion: @escaping ProxyCallback) {
        let name = generator.randomProxyName
        let proxy = Proxy(icon: generator.randomIconName, name: name, ownerId: ownerId)
        Constant.firebaseHelper.set(proxy.toDictionary(), at: Child.proxyNames, proxy.key) { [weak self] error in
            if let error = error {
                if let makeProxyRetries = self?.makeProxyRetries, attempt < makeProxyRetries {
                    self?.makeProxy(ownerId: ownerId, attempt: attempt + 1, completion: completion)
                } else {
                    completion(.failure(error))
                }
            } else {
                Constant.firebaseHelper.set(
                    proxy.toDictionary(),
                    at: Child.proxies,
                    proxy.ownerId,
                    proxy.key) { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(proxy))
                        }
                }
            }
        }
    }

    func read(_ message: Message, at date: Date, completion: @escaping ErrorCallback) {
        let work = GroupWork()
        work.delete(Child.users, message.receiverId, Child.unreadMessages, message.messageId)
        work.set(.dateRead(date), for: message)
        work.set(.hasUnreadMessage(false), uid: message.receiverId, convoKey: message.parentConvoKey)
        work.allDone {
            work.setHasUnreadMessageForProxy(uid: message.receiverId, key: message.receiverProxyKey)
            work.allDone {
                completion(work.result ? nil : ProxyError.unknown)
            }
        }
    }

    func sendMessage(sender: Proxy, receiver: Proxy, text: String, completion: @escaping MessageCallback) {
        let trimmedText = text.trimmed
        guard trimmedText.count < maxMessageSize else {
            completion(.failure(ProxyError.inputTooLong))
            return
        }
        let convoKey = makeConvoKey(sender: sender, receiver: receiver)
        getConvo(convoKey: convoKey, ownerId: sender.ownerId) { [weak self] result in
            switch result {
            case .failure:
                self?.makeConvo(convoKey: convoKey, sender: sender, receiver: receiver) { result in
                    switch result {
                    case .failure(let error):
                        completion(.failure(error))
                        return
                    case .success(let convo):
                        self?.sendMessage(convo: convo, text: trimmedText, completion: completion)
                    }
                }
            case .success(let convo):
                self?.sendMessage(convo: convo, text: trimmedText, completion: completion)
            }
        }
    }

    private func makeConvoKey(sender: Proxy, receiver: Proxy) -> String {
        return [sender.key, sender.ownerId, receiver.key, receiver.ownerId].sorted().joined()
    }

    private func makeConvo(convoKey: String, sender: Proxy, receiver: Proxy, completion: @escaping ConvoCallback) {
        let senderConvo = Convo(
            key: convoKey,
            receiverIcon: receiver.icon,
            receiverId: receiver.ownerId,
            receiverProxyKey: receiver.key,
            receiverProxyName: receiver.name,
            senderIcon: sender.icon,
            senderId: sender.ownerId,
            senderProxyKey: sender.key,
            senderProxyName: sender.name
        )
        let receiverConvo = Convo(
            key: convoKey,
            receiverIcon: sender.icon,
            receiverId: sender.ownerId,
            receiverProxyKey: sender.key,
            receiverProxyName: sender.name,
            senderIcon: receiver.icon,
            senderId: receiver.ownerId,
            senderProxyKey: receiver.key,
            senderProxyName: receiver.name
        )
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
        WQNetworkActivityIndicator.shared.show()
        _sendMessage(convo: convo, text: text) { result in
            WQNetworkActivityIndicator.shared.hide()
            completion(result)
        }
    }

    private func _sendMessage(convo: Convo, text: String, completion: @escaping MessageCallback) {
        guard !convo.receiverDeletedProxy else {
            completion(.failure(ProxyError.receiverDeletedProxy))
            return
        }
        let trimmedText = text.trimmed
        guard trimmedText.count < maxMessageSize else {
            completion(.failure(ProxyError.inputTooLong))
            return
        }
        do {
            let ref = try Constant.firebaseHelper.makeReference(Child.messages, convo.key)
            let message = Message(
                sender: Sender(id: convo.senderId, displayName: convo.senderProxyName),
                messageId: ref.childByAutoId().key,
                data: .text(trimmedText),
                dateRead: Date.distantPast,
                parentConvoKey: convo.key,
                receiverId: convo.receiverId,
                receiverProxyKey: convo.receiverProxyKey,
                senderProxyKey: convo.senderProxyKey
            )
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
        } catch {
            completion(.failure(error))
        }
    }

    func set(userProperty: SettableUserProperty, for uid: String, completion: @escaping ErrorCallback) {
        switch userProperty {
        case .registrationToken(let registrationToken):
            Constant.firebaseHelper.set(
                true,
                at: Child.users, uid, Child.registrationTokens, registrationToken) { error in
                    completion(error)
            }
        default:
            Constant.firebaseHelper.set(
                userProperty.properties.value,
                at: Child.users,
                uid,
                userProperty.properties.name) { error in
                    completion(error)
            }
        }
    }

    func setIcon(to icon: String, for proxy: Proxy, completion: @escaping ErrorCallback) {
        getConvosForProxy(key: proxy.key, ownerId: proxy.ownerId) { result in
            switch result {
            case .failure(let error):
                completion(error)
            case .success(let convos):
                let work = GroupWork()
                work.set(.icon(icon), for: proxy)
                work.setReceiverIcon(to: icon, for: convos)
                work.setSenderIcon(to: icon, for: convos)
                work.allDone {
                    completion(work.result ? nil : ProxyError.unknown)
                }
            }
        }
    }

    func setNickname(to nickname: String, for proxy: Proxy, completion: @escaping ErrorCallback) {
        getConvosForProxy(key: proxy.key, ownerId: proxy.ownerId) { result in
            switch result {
            case .failure(let error):
                completion(error)
            case .success(let convos):
                let work = GroupWork()
                work.set(.nickname(nickname), for: proxy)
                work.setSenderNickname(to: nickname, for: convos)
                work.allDone {
                    completion(work.result ? nil : ProxyError.unknown)
                }
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

    private func getConvosForProxy(key: String,
                                   ownerId: String,
                                   completion: @escaping (Result<[Convo], Error>) -> Void) {
        Constant.firebaseHelper.get(Child.convos, ownerId) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let data):
                completion(.success(data.asConvosArray(proxyKey: key)))
            }
        }
    }
}
