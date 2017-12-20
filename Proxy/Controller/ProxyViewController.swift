import UIKit

class ProxyViewController: UIViewController, MakeNewMessageDelegate {
    var newConvo: Convo?

    private let proxy: Proxy
    private let proxyManager = ProxyManager()
    private let convosManager = ConvosManager()
    private let dataSource = ProxyTableViewDataSource()
    private let delegate = ProxyTableViewDelegate()
    private let tableView = UITableView(frame: .zero, style: .grouped)

    init(_ proxy: Proxy) {
        self.proxy = proxy

        super.init(nibName: nil, bundle: nil)

        navigationItem.rightBarButtonItems = [UIBarButtonItem.make(target: self, action: #selector(showMakeNewMessageController), imageName: ButtonName.makeNewMessage),
                                              UIBarButtonItem.make(target: self, action: #selector(deleteProxy), imageName: ButtonName.delete)]

        proxyManager.load(ownerId: proxy.ownerId, proxyKey: proxy.key, tableView: tableView)

        convosManager.load(convosOwner: proxy.key, tableView: tableView)

        dataSource.load(proxyManager: proxyManager, convosManager: convosManager, controller: self)

        delegate.load(manager: convosManager, controller: self)

        for case let scrollView as UIScrollView in tableView.subviews {
            scrollView.delaysContentTouches = false
        }
        
        tableView.dataSource = dataSource
        tableView.delaysContentTouches = false
        tableView.delegate = delegate
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.register(UINib(nibName: Identifier.convosTableViewCell, bundle: nil), forCellReuseIdentifier: Identifier.convosTableViewCell)
        tableView.register(UINib(nibName: Identifier.senderProxyTableViewCell, bundle: nil), forCellReuseIdentifier: Identifier.senderProxyTableViewCell)
        tableView.sectionHeaderHeight = 0
        tableView.separatorStyle = .none
        view.addSubview(tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if let newConvo = newConvo {
            navigationController?.showConvoViewController(newConvo)
            self.newConvo = nil
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ProxyViewController {
    @objc func deleteProxy() {
        let alert = UIAlertController(title: "Delete Proxy?", message: "You will not be able to see this proxy or its conversations again.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            DBProxy.deleteProxy(self.proxy) { _ in }
            _ = self.navigationController?.popViewController(animated: true)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc func showMakeNewMessageController() {
        showMakeNewMessageController(uid: proxy.ownerId, sender: proxy, viewController: self)
    }
}
