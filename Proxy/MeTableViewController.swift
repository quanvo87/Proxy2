import FirebaseDatabase
import UIKit

typealias MeObserving = MessagesReceivedObserving & MessagesSentObserving & ProxiesInteractedWithObserving

class MeTableViewController: UITableViewController, MeObserving {
    func reloadTableView() {
        
    }

    private var authObserver: AuthObserver?
    private var dataSource: MeTableViewDataSource?
    private var delegate: MeTableViewDelegate?
    private var messagesReceivedObserver: MessagesReceivedObserver?
    private var messagesSentObserver: MessagesSentObserver?
    private var proxiesInteractedWithObserver: ProxiesInteractedWithObserver?
    var messagesReceivedCount = "-"
    var messagesSentCount = "-"
    var proxiesInteractedWithCount = "-"

    override func viewDidLoad() {
        super.viewDidLoad()
        authObserver = AuthObserver(self)
        dataSource = MeTableViewDataSource(self)
        delegate = MeTableViewDelegate(self)
    }
}

extension MeTableViewController: AuthManaging {
    func logIn() {
        navigationItem.title = Shared.shared.userName
        messagesReceivedObserver = MessagesReceivedObserver(controller: self)
        messagesSentObserver = MessagesSentObserver(controller: self)
        proxiesInteractedWithObserver = ProxiesInteractedWithObserver(controller: self)
        tableView.reloadData()
    }
}
