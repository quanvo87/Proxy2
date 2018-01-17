import UIKit

class ProxyViewController: UIViewController, Closing, NewConvoManaging {
    var newConvo: Convo?
    var shouldClose: Bool = false
    private let proxy: Proxy
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private weak var presenceManager: PresenceManaging?
    private weak var proxiesManager: ProxiesManaging?
    private weak var unreadMessagesManager: UnreadMessagesManaging?
    private lazy var convosManager = ConvosManager(proxyKey: proxy.key,
                                                   uid: proxy.ownerId,
                                                   manager: self,
                                                   tableView: tableView)
    private lazy var dataSource = ProxyTableViewDataSource(controller: self,
                                                           convosManager: convosManager,
                                                           proxyManager: proxyManager)
    private lazy var delegate = ProxyTableViewDelegate(controller: self,
                                                       convosManager: convosManager,
                                                       presenceManager: presenceManager,
                                                       proxiesManager: proxiesManager,
                                                       unreadMessagesManager: unreadMessagesManager)
    private lazy var proxyManager = ProxyManager(closer: self,
                                                 key: proxy.key,
                                                 tableView: tableView,
                                                 uid: proxy.ownerId)

    init(proxy: Proxy,
         presenceManager: PresenceManaging?,
         proxiesManager: ProxiesManaging?,
         unreadMessagesManager: UnreadMessagesManaging?) {
        self.proxy = proxy
        self.presenceManager = presenceManager
        self.proxiesManager = proxiesManager
        self.unreadMessagesManager = unreadMessagesManager

        super.init(nibName: nil, bundle: nil)

        navigationItem.rightBarButtonItems = [UIBarButtonItem.make(target: self,
                                                                   action: #selector(showMakeNewMessageController),
                                                                   imageName: ButtonName.makeNewMessage),
                                              UIBarButtonItem.make(target: self,
                                                                   action: #selector(deleteProxy),
                                                                   imageName: ButtonName.delete)]

        tableView.dataSource = dataSource
        tableView.delaysContentTouches = false
        tableView.delegate = delegate
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.register(UINib(nibName: Identifier.convosTableViewCell, bundle: nil),
                           forCellReuseIdentifier: Identifier.convosTableViewCell)
        tableView.register(UINib(nibName: Identifier.senderProxyTableViewCell, bundle: nil),
                           forCellReuseIdentifier: Identifier.senderProxyTableViewCell)
        tableView.sectionHeaderHeight = 0
        tableView.separatorStyle = .none
        tableView.setDelaysContentTouchesForScrollViews()

        view.addSubview(tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if shouldClose {
            _ = navigationController?.popViewController(animated: false)
        }
        if convosManager.convos.isEmpty {
            animateButton()
        }
        if let newConvo = newConvo {
            navigationController?.showConvoViewController(convo: newConvo,
                                                          presenceManager: presenceManager,
                                                          proxiesManager: proxiesManager,
                                                          unreadMessagesManager: unreadMessagesManager)
            self.newConvo = nil
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ProxyViewController: ButtonManaging {
    func animateButton() {
        guard let item = navigationItem.rightBarButtonItems?[safe: 0] else {
            return
        }
        item.morph(loop: true)
    }

    func stopAnimatingButton() {
        guard let item = navigationItem.rightBarButtonItems?[safe: 0] else {
            return
        }
        item.stopAnimating()
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
        guard let item = navigationItem.rightBarButtonItems?[safe: 0] else {
            return
        }
        item.morph()
        showMakeNewMessageController(sender: proxy, uid: proxy.ownerId, manager: proxiesManager, controller: self)
    }
}
