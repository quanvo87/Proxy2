class MessagesReceivedManager: MessagesReceivedManaging {
    let observer = MessagesReceivedObserver()
    weak var reloader: TableViewReloading?
    var messagesReceivedCount = "-" { didSet { reloader?.reloadTableView() } }

    func load(reloader: TableViewReloading, uid: String) {
        self.reloader = reloader
        observer.observe(manager: self, uid: uid)
    }
}
