import UIKit

class ProxyViewController: UIViewController, NewMessageMakerDelegate {
    var newConvo: Convo?
    private let convosObserver: ConvosObsering
    private let database: Database
    private let proxyObserver: ProxyObsering
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private var convos = [Convo]()
    private var proxy: Proxy? { didSet { didSetProxy() } }
    private lazy var deleteProxyButton = makeDeleteProxyButton()
    private lazy var makeNewMessageButton = makeMakeNewMessageButton()

    init(proxy: Proxy,
         convosObserver: ConvosObsering = ConvosObserver(),
         database: Database = Firebase(),
         proxyObserver: ProxyObsering = ProxyObserver()) {
        self.proxy = proxy
        self.convosObserver = convosObserver
        self.database = database
        self.proxyObserver = proxyObserver

        super.init(nibName: nil, bundle: nil)

        convosObserver.observe(convosOwnerId: proxy.ownerId, proxyKey: proxy.key) { [weak self] convos in
            if convos.isEmpty {
                self?.makeNewMessageButton.animate(loop: true)
            } else {
                self?.makeNewMessageButton.stopAnimating()
            }
            self?.convos = convos
            self?.tableView.reloadData()
        }

        navigationItem.rightBarButtonItems = [makeNewMessageButton, deleteProxyButton]

        proxyObserver.observe(proxyKey: proxy.key, proxyOwnerId: proxy.ownerId) { [weak self] proxy in
            self?.proxy = proxy
        }

        tableView.dataSource = self
        tableView.delaysContentTouches = false
        tableView.delegate = self
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
        guard proxy != nil else {
            _ = navigationController?.popViewController(animated: false)
            return
        }
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

private extension ProxyViewController {
    @objc func deleteProxy() {
        let alert = UIAlertController(title: "Delete Proxy?",
                                      message: "You will not be able to see this proxy or its conversations again.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let proxy = self?.proxy else {
                return
            }
            self?.database.deleteProxy(proxy) { _ in
                self?.navigationController?.popViewController(animated: true)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc func showNewMessageMakerViewController() {
        guard let proxy = proxy else {
            return
        }
        makeNewMessageButton.animate()
        showNewMessageMakerViewController(sender: proxy, uid: proxy.ownerId)
    }

    func didSetProxy() {
        guard proxy != nil else {
            _ = navigationController?.popViewController(animated: false)
            return
        }
        tableView.reloadData()
    }

    func makeDeleteProxyButton() -> UIBarButtonItem {
        return UIBarButtonItem(target: self, action: #selector(deleteProxy), image: .delete)
    }

    func makeMakeNewMessageButton() -> UIBarButtonItem {
        return UIBarButtonItem(target: self, action: #selector(showNewMessageMakerViewController), image: .makeNewMessage)
    }
}

// MARK: - UITableViewDataSource
extension ProxyViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            guard
                let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.senderProxyTableViewCell) as? SenderProxyTableViewCell,
                let proxy = proxy else {
                    return tableView.dequeueReusableCell(withIdentifier: Identifier.senderProxyTableViewCell, for: indexPath)
            }
            cell.changeIconButton.addTarget(self, action: #selector(_showIconPickerController), for: .touchUpInside)
            cell.load(proxy)
            cell.nicknameButton.addTarget(self, action: #selector(_showEditProxyNicknameAlert), for: .touchUpInside)
            cell.selectionStyle = .none
            return cell
        case 1:
            guard
                let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.convosTableViewCell) as? ConvosTableViewCell,
                let convo = convos[safe: indexPath.row] else {
                    return tableView.dequeueReusableCell(withIdentifier: Identifier.convosTableViewCell, for: indexPath)
            }
            cell.load(convo)
            return cell
        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return convos.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1:
            return "CONVERSATIONS"
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 1 && convos.isEmpty {
            return "Tap the bouncing button to send a new message 💬."
        } else {
            return nil
        }
    }

    @objc private func _showEditProxyNicknameAlert() {
        guard let proxy = proxy else {
            return
        }
        showEditProxyNicknameAlert(proxy)
    }

    @objc private func _showIconPickerController() {
        guard let proxy = proxy else {
            return
        }
        showIconPickerController(proxy)
    }
}

// MARK: - UITableViewDelegate
extension ProxyViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard
            indexPath.section == 1,
            let row = tableView.indexPathForSelectedRow?.row,
            let convo = convos[safe: row] else {
                return
        }
        tableView.deselectRow(at: indexPath, animated: true)
        showConvoController(convo)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return CGFloat.leastNormalMagnitude
        case 1:
            return 15
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 140
        case 1:
            return 80
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard
            indexPath.section == 1,
            indexPath.row == convos.count - 1,
            let convo = convos[safe: indexPath.row],
            let proxy = proxy else {
                return
        }
        convosObserver.loadConvos(endingAtTimestamp: convo.timestamp, proxyKey: proxy.key) { [weak self] convos in
            self?.convos += convos
        }
    }
}
