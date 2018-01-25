import UIKit

class ConvosViewController: UIViewController, ConvosManaging, NewConvoManaging, ProxiesManaging {
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
    var newConvo: Convo?
    var proxies = [Proxy]()
    private let database: Database
    private let convosObserver: ConvosObsering
    private let maxProxyCount: Int
    private let proxiesObserver: ProxiesObserving
    private let querySize: UInt
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let uid: String
    private weak var presenceManager: PresenceManaging?
    private weak var unreadMessagesManager: UnreadMessagesManaging?
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
         querySize: UInt = Setting.querySize,
         uid: String,
         presenceManager: PresenceManaging?,
         unreadMessagesManager: UnreadMessagesManaging?) {
        self.database = database
        self.maxProxyCount = maxProxyCount
        self.convosObserver = convosObserver
        self.proxiesObserver = proxiesObserver
        self.querySize = querySize
        self.uid = uid
        self.presenceManager = presenceManager
        self.unreadMessagesManager = unreadMessagesManager

        super.init(nibName: nil, bundle: nil)

        convosObserver.load(proxyKey: nil, querySize: Setting.querySize, uid: uid, manager: self)

        navigationItem.rightBarButtonItems = [makeNewMessageButton, makeNewProxyButton]
        navigationItem.title = "Messages"

        proxiesObserver.load(manager: self, uid: uid)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.register(UINib(nibName: Identifier.convosTableViewCell, bundle: nil),
                           forCellReuseIdentifier: Identifier.convosTableViewCell)
        tableView.rowHeight = 80
        tableView.sectionHeaderHeight = 0

        view.addSubview(tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if convos.isEmpty {
            makeNewMessageButton.animate(loop: true)
        }
        if let newConvo = newConvo {
            showConvoController(convo: newConvo,
                                presenceManager: presenceManager,
                                unreadMessagesManager: unreadMessagesManager)
            self.newConvo = nil
        }
    }

    @objc private func makeNewProxy() {
        makeNewProxyButton.animate()
        guard proxies.count < maxProxyCount else {
            showErrorAlert(ProxyError.tooManyProxies)
            return
        }
        makeNewProxyButton.isEnabled = false
        database.makeProxy(ownerId: uid) { [weak self] (result) in
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
            self?.tabBarController?.selectedIndex = 1
            self?.makeNewProxyButton.isEnabled = true
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
        showConvoController(convo: convo,
                            presenceManager: presenceManager,
                            unreadMessagesManager: unreadMessagesManager)
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
        convosObserver.loadConvos(endingAtTimestamp: convo.timestamp,
                                  proxyKey: nil,
                                  querySize: querySize,
                                  uid: uid,
                                  manager: self)
    }
}
