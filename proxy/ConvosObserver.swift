import FirebaseDatabase

class ConvosObserver {
    private var ref: DatabaseReference?
    private var handle: DatabaseHandle?
    private var convos = [Convo]()

    init() {}

    func getConvos() -> [Convo] {
        return convos
    }

    func observeConvos(forOwner owner: String, tableView: UITableView) {
        ref = DB.makeReference(Child.Convos, owner)
        handle = ref?.queryOrdered(byChild: Child.Timestamp).observe(.value, with: { [weak self, weak tableView = tableView] (data) in
            self?.convos = data.toConvos(filtered: true).reversed()
            tableView?.visibleCells.incrementTags()
            tableView?.reloadData()
        })
    }

    deinit {
        if let handle = handle {
            ref?.removeObserver(withHandle: handle)
        }
    }
}
