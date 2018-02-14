import UIKit

class ConvosViewController: UIViewController, NewMessageMakerDelegate {
    var newConvo: Convo?
    private let database: Database
    private let convosObserver: ConvosObsering
    private let proxiesObserver: ProxiesObserving
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let uid: String
    private let unreadMessagesObserver: UnreadMessagesObserving
    private var convos = [Convo]()
    private var currentProxyCount = 0
    private var unreadMessageCount = 0
    private lazy var makeNewMessageButton = UIBarButtonItem(
        target: self,
        action: #selector(showNewMessageMakerViewController),
        image: UIImage(named: ButtonName.makeNewMessage)
    )
    private lazy var makeNewProxyButton = UIBarButtonItem(
        target: self,
        action: #selector(makeNewProxy),
        image: UIImage(named: ButtonName.makeNewProxy)
    )

    init(database: Database = Firebase(),
         convosObserver: ConvosObsering = ConvosObserver(),
         proxiesObserver: ProxiesObserving = ProxiesObserver(),
         uid: String,
         unreadMessagesObserver: UnreadMessagesObserving = UnreadMessagesObserver()) {
        self.database = database
        self.convosObserver = convosObserver
        self.proxiesObserver = proxiesObserver
        self.uid = uid
        self.unreadMessagesObserver = unreadMessagesObserver

        super.init(nibName: nil, bundle: nil)

        convosObserver.observe(convosOwnerId: uid, proxyKey: nil) { [weak self] convos in
            if convos.isEmpty {
                self?.makeNewMessageButton.animate(loop: true)
            } else {
                self?.makeNewMessageButton.stopAnimating()
            }
            self?.convos = convos
            self?.tableView.reloadData()
        }

        makeNewProxyButton.isEnabled = false

        navigationItem.rightBarButtonItems = [makeNewMessageButton, makeNewProxyButton]
        navigationItem.title = "Messages"

        proxiesObserver.observe(proxiesOwnerId: uid) { [weak self] proxies in
            self?.currentProxyCount = proxies.count
            self?.makeNewProxyButton.isEnabled = true
        }

        tableView.dataSource = self
        tableView.delegate = self
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.register(UINib(nibName: Identifier.convosTableViewCell, bundle: nil),
                           forCellReuseIdentifier: Identifier.convosTableViewCell)
        tableView.rowHeight = 80
        tableView.sectionHeaderHeight = 0

        unreadMessagesObserver.observe(uid: uid) { [weak self] update in
            guard let _self = self else {
                return
            }
            switch update {
            case .added:
                _self.unreadMessageCount += 1
            case .removed:
                _self.unreadMessageCount -= 1
            }
            _self.navigationItem.title = "Messages" +  _self.unreadMessageCount.asStringWithParens
            _self.tabBarController?.tabBar.items?.first?.badgeValue = _self.unreadMessageCount.asBadgeValue
        }

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

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ConvosViewController {
    @objc func makeNewProxy() {
        makeNewProxyButton.animate()
        makeNewProxyButton.isEnabled = false
        tabBarController?.selectedIndex = 1
        database.makeProxy(currentProxyCount: currentProxyCount, ownerId: uid) { [weak self] result in
            switch result {
            case .failure(let error):
                self?.showErrorBanner(error)
            case .success:
                break
            }
            self?.makeNewProxyButton.isEnabled = true
        }
    }

    @objc func showNewMessageMakerViewController() {
        makeNewMessageButton.animate()
        makeNewMessageButton.isEnabled = false
        showNewMessageMakerViewController(sender: nil, uid: uid)
        makeNewMessageButton.isEnabled = true
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
            self?.convos += convos
        }
    }
}

// MARK: - Util
private extension Int {
    var asBadgeValue: String? {
        return self == 0 ? nil : String(self)
    }
}
