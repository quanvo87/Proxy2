import UIKit

class ConvoDetailViewController: UIViewController {
    private let convoManager = ConvoManager()
    private let proxyManager = ProxyManager()
    private let dataSource = ConvoDetailTableViewDataSource()
    private let delegate = ConvoDetailTableViewDelegate()
    private let tableView = UITableView(frame: .zero, style: .grouped)

    init(convo: Convo, container: DependencyContaining) {
        super.init(nibName: nil, bundle: nil)

        convoManager.load(convoOwnerId: convo.senderId, convoKey: convo.key, tableView: tableView)

        proxyManager.load(ownerId: convo.senderId, proxyKey: convo.senderProxyKey, tableView: tableView)

        dataSource.load(convoManager: convoManager, proxyManager: proxyManager, controller: self)

        delegate.load(convoManager: convoManager, proxyManager: proxyManager, controller: self, container: container)

        tableView.dataSource = dataSource
        tableView.delegate = delegate
        tableView.delaysContentTouches = false
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.register(UINib(nibName: Identifier.convoDetailReceiverProxyTableViewCell, bundle: nil), forCellReuseIdentifier: Identifier.convoDetailReceiverProxyTableViewCell)
        tableView.register(UINib(nibName: Identifier.convoDetailSenderProxyTableViewCell, bundle: nil), forCellReuseIdentifier: Identifier.convoDetailSenderProxyTableViewCell)
        tableView.setDelaysContentTouchesForScrollViews()

        view.addSubview(tableView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
