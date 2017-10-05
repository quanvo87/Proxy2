class MessagesReceivedManager: MessagesReceivedManaging {
    let observer = MessagesReceivedObserver()
    weak var reloader: ViewReloading?
    var messagesReceivedCount = "-" { didSet { reloader?.reload() } }

    func load(reloader: ViewReloading, uid: String) {
        self.reloader = reloader
        observer.observe(manager: self, uid: uid)
    }
}
