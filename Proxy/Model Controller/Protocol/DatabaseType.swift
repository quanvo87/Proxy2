enum Result<T, Error> {
    case success(T)
    case failure(Error)
}

protocol DatabaseType {
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
