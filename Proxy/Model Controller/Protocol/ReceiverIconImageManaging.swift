import UIKit

protocol ReceiverIconImageManaging: class {
    var receiverIconImage: UIImage? { get set }
}

class ReceiverIconImageManager: ReceiverIconImageManaging {
    var receiverIconImage: UIImage? {
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
