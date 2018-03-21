import UIKit

// todo: show indicator when receiver deleted
class ConvosViewController: UIViewController, NewMessageMakerDelegate {
    var newConvo: Convo?
    private let buttonAnimator: ButtonAnimating
    private let convosObserver: ConvosObsering
    private let database: Database
    private let proxiesObserver: ProxiesObserving
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let tableViewRefresher: TableViewRefreshing
    private let uid: String
    private let unreadMessagesObserver: UnreadMessagesObserving
    private var convos = [Convo]()
    private var currentProxyCount = 0
    private var unreadMessageCount = 0 {
        didSet {
            UIApplication.shared.applicationIconBadgeNumber = unreadMessageCount
        }
    }
    private lazy var makeNewMessageButton = UIBarButtonItem(
        target: self,
        action: #selector(showNewMessageMakerViewController),
        image: Image.makeNewMessage
    )
    private lazy var makeNewProxyButton = UIBarButtonItem(
        target: self,
        action: #selector(makeNewProxy),
        image: Image.makeNewProxy
    )

    init(buttonAnimator: ButtonAnimating = ButtonAnimator(),
         convosObserver: ConvosObsering = ConvosObserver(),
         database: Database = Firebase(),
         proxiesObserver: ProxiesObserving = ProxiesObserver(),
         tableViewRefresher: TableViewRefreshing = TableViewRefresher(timeInterval: Constant.tableViewRefreshRate),
         uid: String,
         unreadMessagesObserver: UnreadMessagesObserving = UnreadMessagesObserver()) {
        self.buttonAnimator = buttonAnimator
        self.convosObserver = convosObserver
        self.database = database
        self.proxiesObserver = proxiesObserver
        self.tableViewRefresher = tableViewRefresher
        self.uid = uid
        self.unreadMessagesObserver = unreadMessagesObserver

        super.init(nibName: nil, bundle: nil)

        let activityIndicatorView = UIActivityIndicatorView(view)

        buttonAnimator.add(makeNewMessageButton)

        convosObserver.observe(convosOwnerId: uid, proxyKey: nil) { [weak self] convos in
            activityIndicatorView.removeFromSuperview()
            if convos.isEmpty {
                self?.buttonAnimator.animate()
            } else {
                self?.buttonAnimator.stopAnimating()
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
        tableView.register(
            UINib(nibName: String(describing: ConvosTableViewCell.self), bundle: nil),
            forCellReuseIdentifier: String(describing: ConvosTableViewCell.self)
        )
        tableView.rowHeight = 80
        tableView.sectionHeaderHeight = 0

        tableViewRefresher.refresh(tableView)

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

        activityIndicatorView.startAnimatingAndBringToFront()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if convos.isEmpty {
            buttonAnimator.animate()
        }
        if let newConvo = newConvo {
            showConvoViewController(newConvo)
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
                StatusBar.showErrorStatusBarBanner(error)
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
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: String(describing: ConvosTableViewCell.self)
            ) as? ConvosTableViewCell else {
                return ConvosTableViewCell()
        }
        cell.load(convos[indexPath.row])
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
        tableView.deselectRow(at: indexPath, animated: true)
        let convo = convos[indexPath.row]
        showConvoViewController(convo)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.row == convos.count - 1 else {  // todo: should be 0?
            return
        }
        let activityIndicatorView = UIActivityIndicatorView(view)
        activityIndicatorView.startAnimatingAndBringToFront()
        let convo = convos[indexPath.row]
        convosObserver.loadConvos(endingAtTimestamp: convo.timestamp, proxyKey: nil) { [weak self] convos in
            activityIndicatorView.removeFromSuperview()
            guard !convos.isEmpty else {
                return
            }
            self?.convos += convos
            self?.tableView.reloadData()
        }
    }
}
