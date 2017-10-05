class MessagesSentManager: MessagesSentManaging {
    let observer = MessagesSentObserver()
    weak var reloader: ViewReloading?
    var messagesSentCount = "-" { didSet { reloader?.reload() } }

    func load(reloader: ViewReloading, uid: String) {
        self.reloader = reloader
        observer.observe(manager: self, uid: uid)
    }
}
