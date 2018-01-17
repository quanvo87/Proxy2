import UIKit

protocol SenderManaging: class {
    var sender: Proxy? { get set }
}

class SenderManager: SenderManaging {
    var sender: Proxy? {
        didSet {
            tableView?.reloadData()
            setter?.setFirstResponder()
        }
    }
    private weak var setter: FirstResponderSetting?
    private weak var tableView: UITableView?

    init(setter: FirstResponderSetting?, tableView: UITableView?) {
        self.setter = setter
        self.tableView = tableView
    }
}
