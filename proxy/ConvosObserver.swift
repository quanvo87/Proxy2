import FirebaseDatabase

class ConvosObserver {
    private weak var ref: DatabaseReference?
    var convos = [Convo]()

    init() {}

    func observe(_ delegate: MessagesTableViewDataSource) {
        ref = DB.makeReference(Child.Convos, Shared.shared.uid)
        ref?.queryOrdered(byChild: Child.Timestamp).observe(.value, with: { [weak self, weak delegate = delegate] (data) in
            self?.convos = data.toConvos(filtered: true).reversed()
            delegate?.tableViewController?.tableView.visibleCells.incrementTags()
            delegate?.tableViewController?.tableView.reloadData()
        })
    }

    deinit {
        ref?.removeAllObservers()
    }
}
