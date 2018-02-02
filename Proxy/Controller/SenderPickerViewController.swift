import UIKit

class SenderPickerViewController: UIViewController {
    private let database: Database
    private let proxiesObserver: ProxiesObserving
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let uid: String
    private var proxies = [Proxy]()
    private weak var senderManager: SenderManaging?
    private lazy var makeNewProxyButton = UIBarButtonItem.make(target: self,
                                                               action: #selector(makeNewProxy),
                                                               imageName: ButtonName.makeNewProxy)

    init(database: Database = Firebase(),
         proxiesObserver: ProxiesObserving = ProxiesObserver(),
         uid: String,
         senderManager: SenderManaging?) {
        self.database = database
        self.proxiesObserver = proxiesObserver
        self.uid = uid
        self.senderManager = senderManager

        super.init(nibName: nil, bundle: nil)

        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }

        proxiesObserver.observe(proxiesOwnerId: uid) { [weak self] proxies in
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            if proxies.isEmpty {
                self?.makeNewProxyButton.animate(loop: true)
            } else {
                self?.makeNewProxyButton.stopAnimating()
            }
            self?.makeNewProxyButton.isEnabled = true
            self?.proxies = proxies
            self?.tableView.reloadData()
        }

        makeNewProxyButton.isEnabled = false

        navigationItem.rightBarButtonItem = makeNewProxyButton
        navigationItem.title = "Pick Your Sender"

        tableView.dataSource = self
        tableView.delegate = self
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.register(UINib(nibName: Identifier.proxiesTableViewCell, bundle: nil),
                           forCellReuseIdentifier: Identifier.proxiesTableViewCell)
        tableView.rowHeight = 60
        tableView.sectionHeaderHeight = 0

        view.addSubview(tableView)
    }

    @objc private func makeNewProxy() {
        makeNewProxyButton.animate()
        makeNewProxyButton.isEnabled = false
        database.makeProxy(currentProxyCount: proxies.count, ownerId: uid) { [weak self] result in
            switch result {
            case .failure(let error):
                self?.showErrorAlert(error)
            default:
                break
            }
            self?.makeNewProxyButton.isEnabled = true
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UITableViewDataSource
extension SenderPickerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.proxiesTableViewCell) as? ProxiesTableViewCell,
            let proxy = proxies[safe: indexPath.row] else {
                return tableView.dequeueReusableCell(withIdentifier: Identifier.proxiesTableViewCell, for: indexPath)
        }
        cell.load(proxy: proxy, accessoryType: .none)
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
extension SenderPickerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let proxy = proxies[safe: indexPath.row] else {
            return
        }
        senderManager?.sender = proxy
        navigationController?.popViewController(animated: true)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}
