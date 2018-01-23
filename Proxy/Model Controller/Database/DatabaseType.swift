protocol DatabaseType {
    typealias Callback = (Result<Proxy, Error>) -> Void
    init(_ settings: [String: Any])
    func delete(_ proxy: Proxy, completion: @escaping (Error?) -> Void)
    func getProxy(key: String, completion: @escaping Callback)
    func getProxy(key: String, ownerId: String, completion: @escaping Callback)
    func makeProxy(ownerId: String, completion: @escaping Callback)
    func setIcon(to icon: String, for proxy: Proxy, completion: @escaping (Error?) -> Void)
    func setNickname(to nickname: String, for proxy: Proxy, completion: @escaping (Error?) -> Void)
}
