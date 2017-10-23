import UIKit

class ProxyViewController: UIViewController, MakeNewMessageDelegate {
    private let dataSource = ProxyTableViewDataSource()
    private let delegate = ProxyTableViewDelegate()
    private let convosManager = ConvosManager()
    private let proxyManager = ProxyManager()
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let proxy: Proxy
    var newConvo: Convo?

    init(_ proxy: Proxy) {
        self.proxy = proxy

        super.init(nibName: nil, bundle: nil)

        navigationItem.rightBarButtonItems = [UIBarButtonItem.makeButton(target: self, action: #selector(showMakeNewMessageController), imageName: .makeNewMessage),
                                              UIBarButtonItem.makeButton(target: self, action: #selector(deleteProxy), imageName: .delete)]

        dataSource.load(controller: self, convosManager: convosManager, proxyManager: proxyManager)
        delegate.load(controller: self, manager: convosManager)

        convosManager.load(convosOwner: proxy.key, tableView: tableView)
        proxyManager.load(ownerId: proxy.ownerId, key: proxy.key, tableView: tableView)

        tableView.dataSource = dataSource
        tableView.delaysContentTouches = false
        tableView.delegate = delegate
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.register(UINib(nibName: Name.convosTableViewCell, bundle: nil), forCellReuseIdentifier: Name.convosTableViewCell)
        tableView.register(UINib(nibName: Name.senderProxyTableViewCell, bundle: nil), forCellReuseIdentifier: Name.senderProxyTableViewCell)
        tableView.sectionHeaderHeight = 0
        tableView.separatorStyle = .none

        for case let scrollView as UIScrollView in tableView.subviews {
            scrollView.delaysContentTouches = false
        }

        view.addSubview(tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
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
        let alert = UIAlertController(title: "Delete Proxy?", message: "You will not be able to see this proxy or its conversations again.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            DBProxy.deleteProxy(self.proxy) { _ in }
            _ = self.navigationController?.popViewController(animated: true)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc func showMakeNewMessageController() {
        showMakeNewMessageController(controller: self, sender: proxy, uid: proxy.ownerId)
    }
}
