import FirebaseDatabase
import FirebaseHelper
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

struct DatabaseOptions {
    static let generator = (name: "generator", value: ProxyPropertyGenerator())
    static let makeProxyRetries = (name: "makeProxyRetries", value: 50)
    static let maxMessageSize = (name: "maxMessageSize", value: 20000)
    static let maxNameSize = (name: "maxNameSize", value: 50)
    static let maxProxyCount = (name: "maxProxyCount", value: 30)
}

protocol Database {
    typealias ConvoCallback = (Result<Convo, Error>) -> Void
    typealias ErrorCallback = (Error?) -> Void
    typealias MessageCallback = (Result<(convo: Convo, message: Message), Error>) -> Void
    typealias ProxyCallback = (Result<Proxy, Error>) -> Void
    init(_ options: [String: Any])
    func deleteProxy(_ proxy: Proxy, completion: @escaping ErrorCallback)
    func getConvo(convoKey: String, ownerId: String, completion: @escaping ConvoCallback)
    func getProxy(proxyKey: String, completion: @escaping ProxyCallback)
    func getProxy(proxyKey: String, ownerId: String, completion: @escaping ProxyCallback)
    func makeProxy(currentProxyCount: Int, ownerId: String, completion: @escaping ProxyCallback)
    func read(_ message: Message, at date: Date, completion: @escaping ErrorCallback)
    func sendMessage(sender: Proxy, receiver: Proxy, text: String, completion: @escaping MessageCallback)
    func sendMessage(convo: Convo, text: String, completion: @escaping MessageCallback)
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

    required init(_ options: [String: Any] = [:]) {
        generator = options[DatabaseOptions.generator.name] as? ProxyPropertyGenerating ?? DatabaseOptions.generator.value
        makeProxyRetries = options[DatabaseOptions.makeProxyRetries.name] as? Int ?? DatabaseOptions.makeProxyRetries.value
        maxMessageSize = options[DatabaseOptions.maxMessageSize.name] as? Int ?? DatabaseOptions.maxMessageSize.value
        maxNameSize = options[DatabaseOptions.maxNameSize.name] as? Int ?? DatabaseOptions.maxNameSize.value
        maxProxyCount = options[DatabaseOptions.maxProxyCount.name] as? Int ?? DatabaseOptions.maxProxyCount.value
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

    func getConvo(convoKey: String, ownerId: String, completion: @escaping ConvoCallback) {
        FirebaseHelper.main.get(Child.convos, ownerId, convoKey) { result in
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
        FirebaseHelper.main.get(Child.proxyNames, proxyKey.lowercased().noWhiteSpaces) { [weak self] result in
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
        FirebaseHelper.main.get(Child.proxies, ownerId, proxyKey) { result in
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
        guard !isMakingProxy else {
            return
        }
        guard currentProxyCount < maxProxyCount else {
            completion(.failure(ProxyError.tooManyProxies))
            return
        }
        isMakingProxy = true
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        makeProxy(ownerId: ownerId, attempt: 0) { [weak self] result in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            self?.isMakingProxy = false
            completion(result)
        }
    }

    private func makeProxy(ownerId: String, attempt: Int, completion: @escaping ProxyCallback) {
        do {
            let ref = try FirebaseHelper.main.makeReference(Child.proxyNames)
            let name = generator.randomProxyName
            let proxy = Proxy(icon: generator.randomIconName, name: name, ownerId: ownerId)
            let testKey = ref.childByAutoId().key
            FirebaseHelper.main.set(proxy.toDictionary(), at: Child.proxyNames, testKey) { [weak self] error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                self?.getProxyNameCount(ref: ref, name: name) { count in
                    FirebaseHelper.main.delete(Child.proxyNames, testKey) { _ in }
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
        } catch {
            completion(.failure(error))
        }
    }

    private func getProxyNameCount(ref: DatabaseReference, name: String, completion: @escaping (UInt?) -> Void) {
        ref.queryOrdered(byChild: Child.name).queryEqual(toValue: name).observeSingleEvent(of: .value) { data in
            completion(data.childrenCount)
        }
    }

    func read(_ message: Message, at date: Date, completion: @escaping ErrorCallback) {
        let work = GroupWork()
        work.delete(Child.userInfo, message.receiverId, Child.unreadMessages, message.messageId)
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
        do {
            let ref = try FirebaseHelper.main.makeReference(Child.messages, convo.key)
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
        } catch {
            completion(.failure(error))
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

    private func getConvosForProxy(key: String, ownerId: String, completion: @escaping (Result<[Convo], Error>) -> Void) {
        FirebaseHelper.main.get(Child.convos, ownerId) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let data):
                completion(.success(data.toConvosArray(proxyKey: key)))
            }
        }
    }
}

private extension String {
    var noWhiteSpaces: String {
        return components(separatedBy: .whitespacesAndNewlines).joined()
    }
}
