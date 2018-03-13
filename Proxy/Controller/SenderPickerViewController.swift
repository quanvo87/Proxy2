import UIKit

class SenderPickerViewController: UIViewController {
    private let buttonAnimator: ButtonAnimating
    private let database: Database
    private let proxiesObserver: ProxiesObserving
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let uid: String
    private var proxies = [Proxy]()
    private weak var senderPickerDelegate: SenderPickerDelegate?
    private lazy var makeNewProxyButton = UIBarButtonItem(
        target: self,
        action: #selector(makeNewProxy),
        image: Image.makeNewProxy
    )

    init(buttonAnimator: ButtonAnimating = ButtonAnimator(),
         database: Database = Firebase(),
         proxiesObserver: ProxiesObserving = ProxiesObserver(),
         uid: String,
         senderPickerDelegate: SenderPickerDelegate?) {
        self.buttonAnimator = buttonAnimator
        self.database = database
        self.proxiesObserver = proxiesObserver
        self.uid = uid
        self.senderPickerDelegate = senderPickerDelegate

        super.init(nibName: nil, bundle: nil)

        let activityIndicatorView = UIActivityIndicatorView(view)

        buttonAnimator.add(makeNewProxyButton)

        proxiesObserver.observe(proxiesOwnerId: uid) { [weak self] proxies in
            activityIndicatorView.removeFromSuperview()
            if proxies.isEmpty {
                self?.buttonAnimator.animate()
            } else {
                self?.buttonAnimator.stopAnimating()
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
        tableView.register(
            UINib(nibName: String(describing: ProxiesTableViewCell.self), bundle: nil),
            forCellReuseIdentifier: String(describing: ProxiesTableViewCell.self)
        )
        tableView.rowHeight = 60
        tableView.sectionHeaderHeight = 0

        view.addSubview(tableView)

        activityIndicatorView.startAnimatingAndBringToFront()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension SenderPickerViewController {
    @objc func makeNewProxy() {
        makeNewProxyButton.animate()
        makeNewProxyButton.isEnabled = false
        database.makeProxy(currentProxyCount: proxies.count, ownerId: uid) { [weak self] result in
            switch result {
            case .failure(let error):
                StatusBar.showErrorStatusBarBanner(error)
            default:
                break
            }
            self?.makeNewProxyButton.isEnabled = true
        }
    }
}

// MARK: - UITableViewDataSource
extension SenderPickerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: String(describing: ProxiesTableViewCell.self)
            ) as? ProxiesTableViewCell else {
                return ProxiesTableViewCell()
        }
        cell.load(proxy: proxies[indexPath.row], accessoryType: .none)
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
        let proxy = proxies[indexPath.row]
        senderPickerDelegate?.sender = proxy
        navigationController?.popViewController(animated: true)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}
