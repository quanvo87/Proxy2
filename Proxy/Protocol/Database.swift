import FirebaseDatabase
import GroupWork
import MessageKit
import WQNetworkActivityIndicator

// todo: move to stats
enum IncrementableUserProperty {
    case messagesReceived(Int)
    case messagesSent(Int)
    case proxiesInteractedWith(Int)

    enum Name: String {
        case messagesReceived
        case messagesSent
        case proxiesInteractedWith
    }

    var properties: (name: String, value: Int) {
        switch self {
        case .messagesReceived(let value):
            return (Name.messagesReceived.rawValue, value)
        case .messagesSent(let value):
            return (Name.messagesSent.rawValue, value)
        case .proxiesInteractedWith(let value):
            return (Name.proxiesInteractedWith.rawValue, value)
        }
    }
}

// todo: move soundOn to settings
enum SettableUserProperty {
    case contact(String)
    case registrationToken(String)
    case soundOn(Bool)

    enum Name: String {
        case contact
        case registrationToken
        case soundOn
    }

    var properties: (name: String, value: Any) {
        switch self {
        case .contact(let value):
            return (Name.contact.rawValue, value)
        case .registrationToken(let value):
            return (Name.registrationToken.rawValue, value)
        case .soundOn(let value):
            return (Name.soundOn.rawValue, value)
        }
    }
}

protocol Database {
    typealias ConvoCallback = (Result<Convo, Error>) -> Void
    typealias DataCallback = (Result<DataSnapshot, Error>) -> Void
    typealias ErrorCallback = (Error?) -> Void
    typealias MessageCallback = (Result<(convo: Convo, message: Message), Error>) -> Void
    typealias ProxyCallback = (Result<Proxy, Error>) -> Void
    func delete(_ proxy: Proxy, completion: @escaping ErrorCallback)
    func delete(_ userProperty: SettableUserProperty, for uid: String, completion: @escaping ErrorCallback)
    func getConvo(convoKey: String, ownerId: String, completion: @escaping ConvoCallback)
    func getProxy(proxyKey: String, completion: @escaping ProxyCallback)
    func getProxy(proxyKey: String, ownerId: String, completion: @escaping ProxyCallback)
    func get(_ userProperty: SettableUserProperty, for uid: String, completion: @escaping DataCallback)
    func makeProxy(currentProxyCount: Int, ownerId: String, completion: @escaping ProxyCallback)
    func read(_ message: Message, at date: Date, completion: @escaping ErrorCallback)
    func sendMessage(sender: Proxy, receiver: Proxy, text: String, completion: @escaping MessageCallback)
    func sendMessage(convo: Convo, text: String, completion: @escaping MessageCallback)
    func setIcon(to icon: String, for proxy: Proxy, completion: @escaping ErrorCallback)
    func setNickname(to nickname: String, for proxy: Proxy, completion: @escaping ErrorCallback)
    func setReceiverNickname(to nickname: String, for convo: Convo, completion: @escaping ErrorCallback)
    func set(_ userProperty: SettableUserProperty, for uid: String, completion: @escaping ErrorCallback)
}

class Firebase: Database {
    private let generator: ProxyPropertyGenerating
    private let makeProxyRetries: Int
    private let maxMessageSize: Int
    private let maxNameSize: Int
    private let maxProxyCount: Int
    private var isMakingProxy = false

    // swiftlint:disable line_length
    init(_ options: [String: Any] = [:]) {
        generator = options[DatabaseOption.generator.name] as? ProxyPropertyGenerating ?? DatabaseOption.generator.value
        makeProxyRetries = options[DatabaseOption.makeProxyRetries.name] as? Int ?? DatabaseOption.makeProxyRetries.value
        maxMessageSize = options[DatabaseOption.maxMessageSize.name] as? Int ?? DatabaseOption.maxMessageSize.value
        maxNameSize = options[DatabaseOption.maxNameSize.name] as? Int ?? DatabaseOption.maxNameSize.value
        maxProxyCount = options[DatabaseOption.maxProxyCount.name] as? Int ?? DatabaseOption.maxProxyCount.value
    }
    // swiftlint:enable line_length

    static func getPath(uid: String, userProperty: SettableUserProperty) -> [String] {
        var path = [uid]
        switch userProperty {
        case .contact(let contactUid):
            path += [Child.contacts, contactUid]
        case .registrationToken(let registrationToken):
            path += [Child.registrationTokens, registrationToken]
        default:
            path += [userProperty.properties.name]
        }
        return path
    }

    func delete(_ proxy: Proxy, completion: @escaping ErrorCallback) {
        Firebase.getConvosForProxy(key: proxy.key, ownerId: proxy.ownerId) { result in
            switch result {
            case .failure(let error):
                completion(error)
            case .success(let convos):
                let work = GroupWork()
                work.delete(convos)
                work.delete(proxy)
                work.deleteProxyKey(proxyKey: proxy.key)
                work.deleteUnreadMessages(for: proxy)
                work.set(.receiverDeletedProxy(true), for: convos, asSender: false)
                work.allDone {
                    completion(Firebase.getError(work.result))
                }
            }
        }
    }

    func delete(_ userProperty: SettableUserProperty, for uid: String, completion: @escaping ErrorCallback) {
        let work = GroupWork()
        work.delete(userProperty, for: uid)
        work.allDone {
            completion(Firebase.getError(work.result))
        }
    }

    func getConvo(convoKey: String, ownerId: String, completion: @escaping ConvoCallback) {
        Shared.firebaseHelper.get(Child.convos, ownerId, convoKey) { result in
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
        Shared.firebaseHelper.get(
            Child.proxyKeys,
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
        Shared.firebaseHelper.get(Child.proxies, ownerId, proxyKey) { result in
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

    func get(_ userProperty: SettableUserProperty, for uid: String, completion: @escaping DataCallback) {
        let rest = Firebase.getPath(uid: uid, userProperty: userProperty)
        Shared.firebaseHelper.get(Child.users, rest) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let data):
                completion(.success(data))
            }
        }
    }

    func makeProxy(currentProxyCount: Int, ownerId: String, completion: @escaping ProxyCallback) {
        Haptic.playSuccess()
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
            self?.isMakingProxy = false
            WQNetworkActivityIndicator.shared.hide()
            completion(result)
        }
    }

    func read(_ message: Message, at date: Date, completion: @escaping ErrorCallback) {
        let work = GroupWork()
        work.deleteUnreadMessage(message)
        work.set(.dateRead(date), for: message)
        work.set(.hasUnreadMessage(false), uid: message.receiverId, convoKey: message.parentConvoKey)
        work.allDone {
            work.setHasUnreadMessageForProxy(uid: message.receiverId, key: message.receiverProxyKey)
            work.allDone {
                completion(Firebase.getError(work.result))
            }
        }
    }

    func sendMessage(sender: Proxy, receiver: Proxy, text: String, completion: @escaping MessageCallback) {
        let trimmedText = text.trimmed
        guard trimmedText.count < maxMessageSize else {
            completion(.failure(ProxyError.inputTooLong))
            return
        }
        let convoKey = Firebase.makeConvoKey(sender: sender, receiver: receiver)
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

    func sendMessage(convo: Convo, text: String, completion: @escaping MessageCallback) {
        WQNetworkActivityIndicator.shared.show()
        _sendMessage(convo: convo, text: text) { result in
            WQNetworkActivityIndicator.shared.hide()
            completion(result)
        }
    }

    func setIcon(to icon: String, for proxy: Proxy, completion: @escaping ErrorCallback) {
        Firebase.getConvosForProxy(key: proxy.key, ownerId: proxy.ownerId) { result in
            switch result {
            case .failure(let error):
                completion(error)
            case .success(let convos):
                let work = GroupWork()
                work.set(.icon(icon), for: proxy)
                work.set(.receiverIcon(icon), for: convos, asSender: false)
                work.set(.senderIcon(icon), for: convos, asSender: true)
                work.allDone {
                    completion(Firebase.getError(work.result))
                }
            }
        }
    }

    func setNickname(to nickname: String, for proxy: Proxy, completion: @escaping ErrorCallback) {
        Firebase.getConvosForProxy(key: proxy.key, ownerId: proxy.ownerId) { result in
            switch result {
            case .failure(let error):
                completion(error)
            case .success(let convos):
                let work = GroupWork()
                work.set(.nickname(nickname), for: proxy)
                work.set(.senderNickname(nickname), for: convos, asSender: true)
                work.allDone {
                    completion(Firebase.getError(work.result))
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
            completion(Firebase.getError(work.result))
        }
    }

    func set(_ property: SettableUserProperty, for uid: String, completion: @escaping ErrorCallback) {
        let work = GroupWork()
        work.set(property, for: uid)
        work.allDone {
            completion(Firebase.getError(work.result))
        }
    }
}

private extension Firebase {
    static func getConvosForProxy(key: String,
                                  ownerId: String,
                                  completion: @escaping (Result<[Convo], Error>) -> Void) {
        Shared.firebaseHelper.get(Child.convos, ownerId) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let data):
                completion(.success(data.asConvosArray(proxyKey: key)))
            }
        }
    }

    static func getError(_ workResult: Bool) -> Error? {
        return workResult ? nil : ProxyError.unknown
    }

    static func makeConvoKey(sender: Proxy, receiver: Proxy) -> String {
        return [sender.key, sender.ownerId, receiver.key, receiver.ownerId].sorted().joined()
    }

    func makeConvo(convoKey: String, sender: Proxy, receiver: Proxy, completion: @escaping ConvoCallback) {
        get(.contact(receiver.ownerId), for: sender.ownerId) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
                return
            case .success(let data):
                guard !data.exists() else {
                    completion(.failure(ProxyError.alreadyChattingWithUser))
                    return
                }
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
                work.increment(.proxiesInteractedWith(1), for: receiver.ownerId)
                work.increment(.proxiesInteractedWith(1), for: sender.ownerId)
                work.set(.contact(receiver.ownerId), for: sender.ownerId)
                work.set(.contact(sender.ownerId), for: receiver.ownerId)
                work.set(senderConvo, asSender: true)
                work.set(receiverConvo, asSender: true)
                work.allDone {
                    completion(work.result ? .success(senderConvo) : .failure(ProxyError.unknown))
                }
            }
        }
    }

    func makeProxy(ownerId: String, attempt: Int, completion: @escaping ProxyCallback) {
        let name = generator.randomProxyName
        let proxy = Proxy(icon: generator.randomIconName, name: name, ownerId: ownerId)
        let work = GroupWork()
        work.setProxyKey(proxy)
        work.allDone { [weak self] in
            if work.result {
                work.set(proxy)
                work.allDone {
                    if work.result {
                        completion(.success(proxy))
                    } else {
                        completion(.failure(ProxyError.unknown))
                    }
                }
            } else {
                if let makeProxyRetries = self?.makeProxyRetries, attempt < makeProxyRetries {
                    self?.makeProxy(ownerId: ownerId, attempt: attempt + 1, completion: completion)
                } else {
                    completion(.failure(ProxyError.unknown))
                }
            }
        }
    }

    func _sendMessage(convo: Convo, text: String, completion: @escaping MessageCallback) {
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
            let ref = try Shared.firebaseHelper.makeReference(Child.messages, convo.key)
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
            let currentTime = Date().timeIntervalSince1970
            let work = GroupWork()
            work.set(message)
            work.increment(.messagesReceived(1), for: convo.receiverId)
            work.increment(.messagesSent(1), for: convo.senderId)
            work.set(.timestamp(currentTime), for: convo, asSender: true)
            work.set(.timestamp(currentTime), forProxyIn: convo, asSender: true)
            work.updateReceiverForMessageReceived(convo: convo, currentTime: currentTime, message: message)
            switch message.data {
            case .text(let text):
                work.set(.lastMessage("You: \(text)"), for: convo, asSender: true)
                work.set(.lastMessage("You: \(text)"), forProxyIn: convo, asSender: true)
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
}
