import UIKit

class ProxyViewController: UIViewController, Closing, MakeNewMessageDelegate {
    var newConvo: Convo?
    var shouldClose: Bool = false
    private let convosManager = ConvosManager()
    private let dataSource = ProxyTableViewDataSource()
    private let delegate = ProxyTableViewDelegate()
    private let proxy: Proxy
    private let proxyManager = ProxyManager()
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private weak var presenceManager: PresenceManaging?
    private weak var proxiesManager: ProxiesManaging?
    private weak var unreadMessagesManager: UnreadMessagesManaging?

    init(proxy: Proxy,
         presenceManager: PresenceManaging,
         proxiesManager: ProxiesManaging,
         unreadMessagesManager: UnreadMessagesManaging) {
        self.proxy = proxy
        self.presenceManager = presenceManager
        self.proxiesManager = proxiesManager
        self.unreadMessagesManager = unreadMessagesManager

        super.init(nibName: nil, bundle: nil)

        navigationItem.rightBarButtonItems = [UIBarButtonItem.make(target: self, action: #selector(showMakeNewMessageController), imageName: ButtonName.makeNewMessage),
                                              UIBarButtonItem.make(target: self, action: #selector(deleteProxy), imageName: ButtonName.delete)]

        proxyManager.load(uid: proxy.ownerId, key: proxy.key, tableView: tableView, closer: self)

        convosManager.load(uid: proxy.ownerId, proxyKey: proxy.key, manager: nil, tableView: tableView)

        dataSource.load(controller: self, convosManager: convosManager, proxyManager: proxyManager)

        delegate.load(controller: self, convosManager: convosManager, presenceManager: presenceManager, proxiesManager: proxiesManager, unreadMessagesManager: unreadMessagesManager)
        
        tableView.dataSource = dataSource
        tableView.delaysContentTouches = false
        tableView.delegate = delegate
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.register(UINib(nibName: Identifier.convosTableViewCell, bundle: nil), forCellReuseIdentifier: Identifier.convosTableViewCell)
        tableView.register(UINib(nibName: Identifier.senderProxyTableViewCell, bundle: nil), forCellReuseIdentifier: Identifier.senderProxyTableViewCell)
        tableView.sectionHeaderHeight = 0
        tableView.separatorStyle = .none
        tableView.setDelaysContentTouchesForScrollViews()

        view.addSubview(tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if shouldClose {
            _ = navigationController?.popViewController(animated: false)
        }
        guard
            let newConvo = newConvo,
            let presenceManager = presenceManager,
            let proxiesManager = proxiesManager,
            let unreadMessagesManager = unreadMessagesManager else {
                return
        }
        navigationController?.showConvoViewController(convo: newConvo, presenceManager: presenceManager, proxiesManager: proxiesManager, unreadMessagesManager: unreadMessagesManager)
        self.newConvo = nil
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ProxyViewController {
    @objc func deleteProxy() {
        let alert = UIAlertController(title: "Delete Proxy?", message: "You will not be able to see this proxy or its conversations again.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let proxy = self?.proxy else {
                return
            }
            DB.deleteProxy(proxy) { _ in
                self?.navigationController?.popViewController(animated: true)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc func showMakeNewMessageController() {
        guard let proxiesManager = proxiesManager else {
            return
        }
        showMakeNewMessageController(sender: proxy, uid: proxy.ownerId, manager: proxiesManager, controller: self)
    }
}
