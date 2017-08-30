import FirebaseDatabase

class ConvosObserver {
    private var ref = DB.makeReference(Child.Convos, Shared.shared.uid)
    private var convos = [Convo]()

    init() {}

    func getConvos() -> [Convo] {
        return convos
    }

    func observe(_ tableView: UITableView) {
        ref?.queryOrdered(byChild: Child.Timestamp).observe(.value, with: { [weak self] (data) in
            self?.convos = data.toConvos(filtered: true).reversed()
            tableView.visibleCells.incrementTags()
            tableView.reloadData()
        })
    }

    deinit {
        ref?.removeAllObservers()
    }
}
