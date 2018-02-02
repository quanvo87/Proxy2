import UIKit

class ConvosViewController: UIViewController, ConvosManaging, NewConvoManaging {
    var convos = [Convo]() {
        didSet {
            if convos.isEmpty {
                makeNewMessageButton.animate(loop: true)
            } else {
                makeNewMessageButton.stopAnimating()
            }
            tableView.reloadData()
        }
    }
    private var unreadMessageCount = 0 {
        didSet {
            navigationItem.title = "Messages" +  unreadMessageCount.asStringWithParens
            tabBarController?.tabBar.items?.first?.badgeValue = unreadMessageCount.asBadgeValue
        }
    }
    var newConvo: Convo?
    var proxyCount = 0
    private let database: Database
    private let convosObserver: ConvosObsering
    private let maxProxyCount: Int
    private let proxiesObserver: ProxiesObserving
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let uid: String
    private let unreadMessagesObserver: UnreadMessagesObserving
    private lazy var makeNewMessageButton = UIBarButtonItem.make(target: self,
                                                                 action: #selector(showMakeNewMessageController),
                                                                 imageName: ButtonName.makeNewMessage)
    private lazy var makeNewProxyButton = UIBarButtonItem.make(target: self,
                                                               action: #selector(makeNewProxy),
                                                               imageName: ButtonName.makeNewProxy)

    init(database: Database = Firebase(),
         convosObserver: ConvosObsering = ConvosObserver(),
         maxProxyCount: Int = Setting.maxProxyCount,
         proxiesObserver: ProxiesObserving = ProxiesObserver(),
         uid: String,
         unreadMessagesObserver: UnreadMessagesObserving = UnreadMessagesObserver()) {
        self.database = database
        self.maxProxyCount = maxProxyCount
        self.convosObserver = convosObserver
        self.proxiesObserver = proxiesObserver
        self.uid = uid
        self.unreadMessagesObserver = unreadMessagesObserver

        super.init(nibName: nil, bundle: nil)

        let loadingViewController = LoadingViewController()
        add(loadingViewController)

        convosObserver.observe(convosOwnerId: uid, proxyKey: nil) { [weak self] convos in
            self?.convos = convos
            loadingViewController.remove()
        }

        makeNewProxyButton.isEnabled = false

        navigationItem.rightBarButtonItems = [makeNewMessageButton, makeNewProxyButton]
        navigationItem.title = "Messages"

        proxiesObserver.observe(proxiesOwnerId: uid) { [weak self] proxies in
            self?.proxyCount = proxies.count
            self?.makeNewProxyButton.isEnabled = true
        }

        tableView.dataSource = self
        tableView.delegate = self
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.register(UINib(nibName: Identifier.convosTableViewCell, bundle: nil),
                           forCellReuseIdentifier: Identifier.convosTableViewCell)
        tableView.rowHeight = 80
        tableView.sectionHeaderHeight = 0

        unreadMessagesObserver.observe(uid: uid, unreadMessagesManager: self)

        view.addSubview(tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if convos.isEmpty {
            makeNewMessageButton.animate(loop: true)
        }
        if let newConvo = newConvo {
            showConvoController(newConvo)
            self.newConvo = nil
        }
    }

    @objc private func makeNewProxy() {
        makeNewProxyButton.animate()
        tabBarController?.selectedIndex = 1
        guard proxyCount < maxProxyCount else {
            showErrorAlert(ProxyError.tooManyProxies)
            return
        }
        makeNewProxyButton.isEnabled = false
        database.makeProxy(ownerId: uid) { [weak self] result in
            self?.makeNewProxyButton.isEnabled = true
            switch result {
            case .failure(let error):
                self?.showErrorAlert(error)
            case .success:
                guard
                    let proxiesNavigationController = self?.tabBarController?.viewControllers?[safe: 1] as? UINavigationController,
                    let proxiesViewController = proxiesNavigationController.viewControllers[safe: 0] as? ProxiesViewController else {
                        return
                }
                proxiesViewController.scrollToTop()
            }
        }
    }

    @objc private func showMakeNewMessageController() {
        makeNewMessageButton.animate()
        makeNewMessageButton.isEnabled = false
        showMakeNewMessageController(sender: nil, uid: uid)
        makeNewMessageButton.isEnabled = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UITableViewDataSource
extension ConvosViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.convosTableViewCell) as? ConvosTableViewCell,
            let convo = convos[safe: indexPath.row] else {
                return tableView.dequeueReusableCell(withIdentifier: Identifier.convosTableViewCell, for: indexPath)
        }
        cell.load(convo)
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return convos.count
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if convos.isEmpty {
            return "Tap the bouncing button to send a message 💬."
        } else {
            return nil
        }
    }
}

// MARK: - UITableViewDelegate
extension ConvosViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let convo = convos[safe: indexPath.row] else {
            return
        }
        tableView.deselectRow(at: indexPath, animated: true)
        showConvoController(convo)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard
            indexPath.row == convos.count - 1,
            let convo = convos[safe: indexPath.row] else {
                return
        }
        convosObserver.loadConvos(endingAtTimestamp: convo.timestamp, proxyKey: nil) { [weak self] convos in
            self?.convos = convos
        }
    }
}

// MARK: - UnreadMessagesManaging
extension ConvosViewController: UnreadMessagesManaging {
    func unreadMessageAdded(_ message: Message) {
        unreadMessageCount += 1
    }

    func unreadMessageRemoved(_ message: Message) {
        unreadMessageCount -= 1
    }
}

// MARK: - Util
private extension Int {
    var asBadgeValue: String? {
        return self == 0 ? nil : String(self)
    }
}
