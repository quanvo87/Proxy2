import UIKit

class ProxyViewController: UIViewController, ConvosManaging, NewConvoManaging, ProxyManaging {
    var convos = [Convo]() {
        didSet {
            if convos.isEmpty {
                animateButton()
            } else {
                stopAnimatingButton()
            }
            tableView.reloadData()
        }
    }
    var newConvo: Convo?
    var proxy: Proxy? {
        didSet {
            if proxy == nil {
                _ = navigationController?.popViewController(animated: false)
            } else {
                tableView.reloadData()
            }
        }
    }
    private let convosObserver: ConvosObsering
    private let database: DatabaseType
    private let proxyObserver: ProxyObsering
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private weak var presenceManager: PresenceManaging?
    private weak var proxiesManager: ProxiesManaging?
    private weak var unreadMessagesManager: UnreadMessagesManaging?
    private lazy var dataSource = ProxyTableViewDataSource(controller: self,
                                                           convosManager: self,
                                                           proxyManager: self)
    private lazy var delegate = ProxyTableViewDelegate(controller: self,
                                                       convosManager: self,
                                                       presenceManager: presenceManager,
                                                       proxiesManager: proxiesManager,
                                                       unreadMessagesManager: unreadMessagesManager)

    init(proxy: Proxy,
         convosObserver: ConvosObsering = ConvosObserver(),
         database: DatabaseType = FirebaseDatabase(),
         proxyObserver: ProxyObsering = ProxyObserver(),
         presenceManager: PresenceManaging?,
         proxiesManager: ProxiesManaging?,
         unreadMessagesManager: UnreadMessagesManaging?) {
        self.proxy = proxy
        self.convosObserver = convosObserver
        self.database = database
        self.proxyObserver = proxyObserver
        self.presenceManager = presenceManager
        self.proxiesManager = proxiesManager
        self.unreadMessagesManager = unreadMessagesManager

        super.init(nibName: nil, bundle: nil)

        convosObserver.load(proxyKey: proxy.key, querySize: Setting.querySize, uid: proxy.ownerId, manager: self)

        navigationItem.rightBarButtonItems = [UIBarButtonItem.make(target: self,
                                                                   action: #selector(showMakeNewMessageController),
                                                                   imageName: ButtonName.makeNewMessage),
                                              UIBarButtonItem.make(target: self,
                                                                   action: #selector(deleteProxy),
                                                                   imageName: ButtonName.delete)]

        proxyObserver.load(proxyKey: proxy.key, uid: proxy.ownerId, manager: self)

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
        if convos.isEmpty {
            animateButton()
        }
        if let newConvo = newConvo {
            showConvoController(convo: newConvo,
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
        item.animate(loop: true)
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
            self?.database.delete(proxy) { (error) in
                if let error = error {
                    self?.showErrorAlert(error)
                } else {
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc func showMakeNewMessageController() {
        guard
            let item = navigationItem.rightBarButtonItems?[safe: 0],
            let proxy = proxy else {
                return
        }
        item.animate()
        showMakeNewMessageController(sender: proxy, uid: proxy.ownerId, manager: proxiesManager)
    }
}
