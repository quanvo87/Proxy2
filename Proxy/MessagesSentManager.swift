class MessagesSentManager: MessagesSentManaging {
    let observer = MessagesSentObserver()
    weak var reloader: TableViewReloading?
    var messagesSentCount = "-" { didSet { reloader?.reloadTableView() } }

    func load(reloader: TableViewReloading, uid: String) {
        self.reloader = reloader
        observer.observe(manager: self, uid: uid)
    }
}
