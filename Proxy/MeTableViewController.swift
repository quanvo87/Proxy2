import FirebaseDatabase
import UIKit

typealias MeObserving = MessagesReceivedObserving & MessagesSentObserving & ProxiesInteractedWithObserving

class MeTableViewController: UITableViewController, MeObserving {
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
        authObserver?.observe()
        dataSource = MeTableViewDataSource(self)
        delegate = MeTableViewDelegate(self)
    }
}

extension MeTableViewController: AuthObserving {
    func logIn() {
        navigationItem.title = Shared.shared.userName
        messagesReceivedObserver = MessagesReceivedObserver(controller: self)
        messagesReceivedObserver?.observe()
        messagesSentObserver = MessagesSentObserver(controller: self)
        messagesSentObserver?.observe()
        proxiesInteractedWithObserver = ProxiesInteractedWithObserver(controller: self)
        proxiesInteractedWithObserver?.observe()
        tableView.reloadData()
    }
}
