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
    var newConvo: Convo?
    private let database: DatabaseType
    private let maxProxyCount: Int
    private let observer: ConvosObsering
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let uid: String
    private weak var presenceManager: PresenceManaging?
    private weak var proxiesManager: ProxiesManaging?
    private weak var unreadMessagesManager: UnreadMessagesManaging?
    private lazy var makeNewMessageButton = UIBarButtonItem.make(target: self,
                                                                 action: #selector(showMakeNewMessageController),
                                                                 imageName: ButtonName.makeNewMessage)
    private lazy var makeNewProxyButton = UIBarButtonItem.make(target: self,
                                                               action: #selector(makeNewProxy),
                                                               imageName: ButtonName.makeNewProxy)

    init(database: DatabaseType = FirebaseDatabase(),
         maxProxyCount: Int = Setting.maxProxyCount,
         observer: ConvosObsering = ConvosObserver(),
         uid: String,
         presenceManager: PresenceManaging?,
         proxiesManager: ProxiesManaging?,
         unreadMessagesManager: UnreadMessagesManaging?) {
        self.database = database
        self.maxProxyCount = maxProxyCount
        self.observer = observer
        self.uid = uid
        self.presenceManager = presenceManager
        self.proxiesManager = proxiesManager
        self.unreadMessagesManager = unreadMessagesManager

        super.init(nibName: nil, bundle: nil)

        navigationItem.rightBarButtonItems = [makeNewMessageButton, makeNewProxyButton]
        navigationItem.title = "Messages"

        observer.load(proxyKey: nil, querySize: Setting.querySize, uid: uid, manager: self)

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
                                proxiesManager: proxiesManager,
                                unreadMessagesManager: unreadMessagesManager)
            self.newConvo = nil
        }
    }

    @objc private func makeNewProxy() {
        guard proxiesManager?.proxies.count ?? Int.max < maxProxyCount else {
            showAlert(title: "You have too many Proxies", message: "Try deleting some and try again!")
            return
        }
        makeNewProxyButton.animate()
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
        showMakeNewMessageController(sender: nil, uid: uid, manager: proxiesManager)
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
                            proxiesManager: proxiesManager,
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
        observer.loadConvos(endingAtTimestamp: convo.timestamp,
                            proxyKey: nil,
                            querySize: Setting.querySize,
                            uid: uid,
                            manager: self)
    }
}
