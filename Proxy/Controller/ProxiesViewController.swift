import UIKit

class ProxiesViewController: UIViewController, NewMessageMakerDelegate {
    var newConvo: Convo?
    private let buttonAnimator: ButtonAnimating
    private let database: Database
    private let proxiesObserver: ProxiesObserving
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let uid: String
    private var proxies = [Proxy]()
    private var proxiesToDelete = [String: Any]()
    private var proxyCount = 0
    private lazy var cancelButton = UIBarButtonItem(
        target: self,
        action: #selector(setDefaultButtons),
        image: Image.cancel
    )
    private lazy var confirmButton = UIBarButtonItem(
        target: self,
        action: #selector(deleteSelectedItems),
        image: Image.confirm
    )
    private lazy var deleteButton = UIBarButtonItem(
        target: self,
        action: #selector(setEditModeButtons),
        image: Image.delete
    )
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
         database: Database = Constant.database,
         proxiesObserver: ProxiesObserving = ProxiesObserver(),
         uid: String) {
        self.buttonAnimator = buttonAnimator
        self.database = database
        self.proxiesObserver = proxiesObserver
        self.uid = uid

        super.init(nibName: nil, bundle: nil)

        let activityIndicatorView = UIActivityIndicatorView(view)

        buttonAnimator.add(makeNewProxyButton)

        makeNewProxyButton.isEnabled = false

        navigationItem.title = "My Proxies"

        proxiesObserver.observe(proxiesOwnerId: uid) { [weak self] proxies in
            activityIndicatorView.removeFromSuperview()
            if proxies.isEmpty {
                self?.buttonAnimator.animate()
            } else {
                self?.buttonAnimator.stopAnimating()
            }
            let title = "My Proxies\(proxies.count.asStringWithParens)"
            self?.navigationController?.tabBarController?.tabBar.items?[1].title = title
            self?.navigationItem.title = title
            self?.makeNewProxyButton.isEnabled = true
            self?.proxies = proxies
            self?.tableView.reloadData()
            if let proxyCount = self?.proxyCount, proxyCount < proxies.count {
                self?.scrollToTop()
            }
            self?.proxyCount = proxies.count
        }

        setDefaultButtons()

        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.dataSource = self
        tableView.delegate = self
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.register(
            UINib(nibName: String(describing: ProxiesTableViewCell.self), bundle: nil),
            forCellReuseIdentifier: String(describing: ProxiesTableViewCell.self)
        )
        tableView.rowHeight = 60
        tableView.sectionHeaderHeight = 0

        view.addSubview(tableView)

        activityIndicatorView.startAnimatingAndBringToFront()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if proxies.isEmpty {
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

private extension ProxiesViewController {
    @objc func setDefaultButtons() {
        if proxies.isEmpty {
            buttonAnimator.animate()
        }
        proxiesToDelete.removeAll()
        makeNewProxyButton.customView?.isHidden = false
        makeNewProxyButton.isEnabled = true
        navigationItem.leftBarButtonItem = deleteButton
        navigationItem.rightBarButtonItems = [makeNewMessageButton, makeNewProxyButton]
        tableView.setEditing(false, animated: true)
    }

    @objc func setEditModeButtons() {
        makeNewProxyButton.customView?.isHidden = true
        makeNewProxyButton.isEnabled = false
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = confirmButton
        tableView.setEditing(true, animated: true)
    }

    @objc func deleteSelectedItems() {
        if proxiesToDelete.isEmpty {
            setDefaultButtons()
            return
        }
        let alert = Alert.make(
            title: "Delete Proxies?",
            message: "Their conversations will also be deleted."
        )
        alert.addAction(Alert.makeDestructiveAction(title: "Delete") { [weak self] _ in
            for (_, item) in self?.proxiesToDelete ?? [:] {
                guard let proxy = item as? Proxy else {
                    continue
                }
                self?.database.deleteProxy(proxy) { error in
                    if let error = error {
                        StatusBar.showErrorStatusBarBanner(error)
                    } else {
                        StatusBar.showSuccessStatusBarBanner("\(proxy.name) has been deleted.")
                    }
                }
            }
            self?.proxiesToDelete.removeAll()
            self?.setDefaultButtons()
        })
        alert.addAction(Alert.makeCancelAction())
        present(alert, animated: true)
    }

    @objc func makeNewProxy() {
        makeNewProxyButton.animate()
        makeNewProxyButton.isEnabled = false
        database.makeProxy(currentProxyCount: proxies.count, ownerId: uid) { [weak self] result in
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

    func scrollToTop() {
        guard tableView.numberOfRows(inSection: 0) > 0 else {
            return
        }
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .bottom, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension ProxiesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: String(describing: ProxiesTableViewCell.self)
            ) as? ProxiesTableViewCell else {
                return ProxiesTableViewCell()
        }
        cell.load(proxy: proxies[indexPath.row], accessoryType: .disclosureIndicator)
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
        let proxy = proxies[indexPath.row]
        if tableView.isEditing {
            proxiesToDelete[proxy.key] = proxy
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            showProxyViewController(proxy)
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            let proxy = proxies[indexPath.row]
            proxiesToDelete.removeValue(forKey: proxy.key)
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}
