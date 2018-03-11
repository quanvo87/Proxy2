import UIKit

class ProxyViewController: UIViewController, NewMessageMakerDelegate {
    var newConvo: Convo?
    private let buttonAnimator: ButtonAnimating
    private let convosObserver: ConvosObsering
    private let database: Database
    private let proxyObserver: ProxyObsering
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private var convos = [Convo]()
    private var proxy: Proxy? { didSet { didSetProxy() } }
    private lazy var deleteProxyButton = UIBarButtonItem(
        target: self,
        action: #selector(deleteProxy),
        image: Image.delete
    )
    private lazy var makeNewMessageButton = UIBarButtonItem(
        target: self,
        action: #selector(showNewMessageMakerViewController),
        image: Image.makeNewMessage
    )

    init(buttonAnimator: ButtonAnimating = ButtonAnimator(),
         convosObserver: ConvosObsering = ConvosObserver(),
         database: Database = Firebase(),
         proxyObserver: ProxyObsering = ProxyObserver(),
         proxy: Proxy) {
        self.buttonAnimator = buttonAnimator
        self.convosObserver = convosObserver
        self.database = database
        self.proxyObserver = proxyObserver
        self.proxy = proxy

        super.init(nibName: nil, bundle: nil)

        buttonAnimator.add(makeNewMessageButton)

        convosObserver.observe(convosOwnerId: proxy.ownerId, proxyKey: proxy.key) { [weak self] convos in
            if convos.isEmpty {
                self?.buttonAnimator.animate()
            } else {
                self?.buttonAnimator.stopAnimating()
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
        tableView.register(
            UINib(nibName: String(describing: ConvosTableViewCell.self), bundle: nil),
            forCellReuseIdentifier: String(describing: ConvosTableViewCell.self)
        )
        tableView.register(
            UINib(nibName: String(describing: SenderProxyTableViewCell.self), bundle: nil),
            forCellReuseIdentifier: String(describing: SenderProxyTableViewCell.self)
        )
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

private extension ProxyViewController {
    @objc func deleteProxy() {
        let alert = Alert.make(
            title: Alert.deleteProxyMessage.title,
            message: Alert.deleteProxyMessage.message
        )
        alert.addAction(Alert.makeDestructiveAction(title: "Delete") { [weak self] _ in
            guard let proxy = self?.proxy else {
                return
            }
            self?.database.deleteProxy(proxy) { error in
                if let error = error {
                    StatusBar.showErrorStatusBarBanner(error)
                } else {
                    StatusBar.showSuccessStatusBarBanner("\(proxy.name) has been deleted.")
                }
            }
            self?.navigationController?.popViewController(animated: true)
        })
        alert.addAction(Alert.makeCancelAction())
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
}

// MARK: - UITableViewDataSource
extension ProxyViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            guard let proxy = proxy else {
                return SenderProxyTableViewCell()
            }
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: String(describing: SenderProxyTableViewCell.self)
                ) as? SenderProxyTableViewCell else {
                    assertionFailure()
                    return SenderProxyTableViewCell()
            }
            cell.changeIconButton.addTarget(self, action: #selector(_showIconPickerController), for: .touchUpInside)
            cell.load(proxy)
            cell.nicknameButton.addTarget(self, action: #selector(_showEditProxyNicknameAlert), for: .touchUpInside)
            cell.selectionStyle = .none
            return cell
        case 1:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: String(describing: ConvosTableViewCell.self)
                ) as? ConvosTableViewCell else {
                    assertionFailure()
                    return UITableViewCell()
            }
            cell.load(convos[indexPath.row])
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
        showIconPickerViewController(proxy)
    }
}

// MARK: - UITableViewDelegate
extension ProxyViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1, let row = tableView.indexPathForSelectedRow?.row {
            let convo = convos[row]
            showConvoViewController(convo)
        }
        tableView.deselectRow(at: indexPath, animated: true)
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
        guard let proxy = proxy, indexPath.section == 1, indexPath.row == convos.count - 1 else {
            return
        }
        let convo = convos[indexPath.row]
        convosObserver.loadConvos(endingAtTimestamp: convo.timestamp, proxyKey: proxy.key) { [weak self] convos in
            self?.convos += convos
        }
    }
}
