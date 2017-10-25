struct Cache {
    static let cache: NSCache = {
        return NSCache<AnyObject, AnyObject>()
    }()
}
