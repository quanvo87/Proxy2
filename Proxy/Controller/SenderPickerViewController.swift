import UIKit

class SenderPickerViewController: UIViewController {
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let uid: String
    private weak var manager: ProxiesManaging?
    private weak var senderPickerDelegate: SenderPickerDelegate?
    private lazy var tableViewDataSource = ProxiesTableViewDataSource(accessoryType: .none,
                                                                      manager: manager)
    private lazy var tableViewDelegate = SenderPickerTableViewDelegate(controller: self,
                                                                       delegate: senderPickerDelegate,
                                                                       manager: manager)

    init(uid: String, manager: ProxiesManaging, senderPickerDelegate: SenderPickerDelegate) {
        self.uid = uid
        self.manager = manager
        self.senderPickerDelegate = senderPickerDelegate

        super.init(nibName: nil, bundle: nil)

        manager.load(animator: self, controller: nil, tableView: tableView)

        navigationItem.rightBarButtonItem = UIBarButtonItem.make(target: self, action: #selector(makeNewProxy), imageName: ButtonName.makeNewProxy)
        navigationItem.title = "Pick Your Sender"

        tableView.dataSource = tableViewDataSource
        tableView.delegate = tableViewDelegate
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.register(UINib(nibName: Identifier.proxiesTableViewCell, bundle: nil), forCellReuseIdentifier: Identifier.proxiesTableViewCell)
        tableView.rowHeight = 60
        tableView.sectionHeaderHeight = 0
        
        view.addSubview(tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if manager?.proxies.isEmpty ?? false {
            animateButton()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SenderPickerViewController: ButtonAnimating {
    func animateButton() {
        navigationItem.rightBarButtonItem?.morph(loop: true)
    }

    func stopAnimatingButton() {
        navigationItem.rightBarButtonItem?.stopAnimating()
    }
}

private extension SenderPickerViewController {
    @objc func makeNewProxy() {
        guard let proxyCount = manager?.proxies.count else {
            return
        }
        navigationItem.rightBarButtonItem?.isEnabled = false
        DB.makeProxy(uid: uid, currentProxyCount: proxyCount) { [weak self] (result) in
            switch result {
            case .failure(let error):
                self?.showAlert(title: "Error Making New Proxy", message: error.description)
            case .success:
                self?.animateButton()
            }
            self?.navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }
}
