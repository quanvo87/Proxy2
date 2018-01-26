import UIKit

class ProxiesViewController: UIViewController, NewConvoManaging, ProxiesManaging {
    var proxies = [Proxy]() {
        didSet {
            if proxies.isEmpty {
                makeNewProxyButton.animate(loop: true)
            } else {
                makeNewProxyButton.stopAnimating()
            }
            let title = "My Proxies\(proxies.count.asStringWithParens)"
            navigationItem.title = title
            navigationController?.tabBarController?.tabBar.items?[1].title = title
            tableView.reloadData()
        }
    }
    var newConvo: Convo?
    private let database: Database
    private let maxProxyCount: Int
    private let proxiesObserver: ProxiesObserving
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let uid: String
    private var itemsToDelete: [String: Any] = [:]
    private lazy var cancelButton = UIBarButtonItem.make(target: self,
                                                         action: #selector(setDefaultButtons),
                                                         imageName: ButtonName.cancel)
    private lazy var confirmButton = UIBarButtonItem.make(target: self,
                                                          action: #selector(deleteSelectedItems),
                                                          imageName: ButtonName.confirm)
    private lazy var deleteButton = UIBarButtonItem.make(target: self,
                                                         action: #selector(setEditModeButtons),
                                                         imageName: ButtonName.delete)
    private lazy var makeNewMessageButton = UIBarButtonItem.make(target: self,
                                                                 action: #selector(showMakeNewMessageController),
                                                                 imageName: ButtonName.makeNewMessage)
    private lazy var makeNewProxyButton = UIBarButtonItem.make(target: self,
                                                               action: #selector(makeNewProxy),
                                                               imageName: ButtonName.makeNewProxy)

    init(database: Database = Firebase(),
         maxProxyCount: Int = Setting.maxProxyCount,
         proxiesObserver: ProxiesObserving = ProxiesObserver(),
         uid: String) {
        self.database = database
        self.maxProxyCount = maxProxyCount
        self.proxiesObserver = proxiesObserver
        self.uid = uid

        super.init(nibName: nil, bundle: nil)

        navigationItem.title = "My Proxies"

        proxiesObserver.load(proxiesOwnerId: uid, proxiesManager: self)

        setDefaultButtons()

        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.dataSource = self
        tableView.delegate = self
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.register(UINib(nibName: Identifier.proxiesTableViewCell, bundle: nil),
                           forCellReuseIdentifier: Identifier.proxiesTableViewCell)
        tableView.rowHeight = 60
        tableView.sectionHeaderHeight = 0

        view.addSubview(tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if proxies.isEmpty {
            makeNewProxyButton.animate(loop: true)
        }
        if let newConvo = newConvo {
            showConvoController(newConvo)
            self.newConvo = nil
        }
    }

    func scrollToTop() {
        guard tableView.numberOfRows(inSection: 0) > 0 else {
            return
        }
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .bottom, animated: true)
    }

    @objc private func setDefaultButtons() {
        if proxies.isEmpty {
            makeNewProxyButton.animate(loop: true)
        }
        itemsToDelete.removeAll()
        makeNewProxyButton.customView?.isHidden = false
        makeNewProxyButton.isEnabled = true
        navigationItem.leftBarButtonItem = deleteButton
        navigationItem.rightBarButtonItems = [makeNewMessageButton, makeNewProxyButton]
        tableView.setEditing(false, animated: true)
    }

    @objc private func setEditModeButtons() {
        makeNewProxyButton.customView?.isHidden = true
        makeNewProxyButton.isEnabled = false
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = confirmButton
        tableView.setEditing(true, animated: true)
    }

    @objc private func deleteSelectedItems() {
        if itemsToDelete.isEmpty {
            setDefaultButtons()
            return
        }
        let alert = UIAlertController(title: "Delete Proxies?", message: "The conversations will also be deleted.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            for (_, item) in self?.itemsToDelete ?? [:] {
                guard let proxy = item as? Proxy else {
                    continue
                }
                self?.database.delete(proxy) { _ in }
            }
            self?.itemsToDelete.removeAll()
            self?.setDefaultButtons()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
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
                self?.scrollToTop()
            }
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
extension ProxiesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.proxiesTableViewCell) as? ProxiesTableViewCell,
            let proxy = proxies[safe: indexPath.row] else {
                return tableView.dequeueReusableCell(withIdentifier: Identifier.proxiesTableViewCell, for: indexPath)
        }
        cell.load(proxy: proxy, accessoryType: .disclosureIndicator)
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return proxies.count
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if proxies.isEmpty {
            return "Tap the bouncing button to make a new Proxy 🎉."
        } else {
            return nil
        }
    }
}

// MARK: - UITableViewDelegate
extension ProxiesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let proxy = proxies[safe: indexPath.row] else {
            return
        }
        if tableView.isEditing {
            itemsToDelete[proxy.key] = proxy
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            showProxyController(proxy)
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard
            tableView.isEditing,
            let proxy = proxies[safe: indexPath.row] else {
                return
        }
        itemsToDelete.removeValue(forKey: proxy.key)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}
