import UIKit

class ProxyTableViewController: UITableViewController, MakeNewMessageDelegate {
    let convosManager = ConvosManager()
    let dataSource = ProxyTableViewDataSource()
    let delegate = ProxyTableViewDelegate()
    let proxyManager = ProxyManager()
    var newConvo: Convo?
    var proxy: Proxy?

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let proxy = proxy else { return }
        convosManager.load(convosOwner: proxy.key, tableView: tableView)
        dataSource.load(self)
        delegate.load(self)
        proxyManager.load(ownerId: proxy.ownerId, key: proxy.key, tableView: tableView)
        navigationItem.rightBarButtonItems = [UIBarButtonItem.makeButton(target: self, action: #selector(goToMakeNewMessageVC), imageName: .makeNewMessage),
                                              UIBarButtonItem.makeButton(target: self, action: #selector(deleteProxy), imageName: .delete)]
        tableView.delaysContentTouches = false
        tableView.separatorStyle = .none
        for case let scrollView as UIScrollView in tableView.subviews {
            scrollView.delaysContentTouches = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if let newConvo = newConvo {
            goToConvoVC(newConvo)
            self.newConvo = nil
        }
    }
}

private extension ProxyTableViewController {
    @objc func deleteProxy() {
        guard let proxy = proxy else { return }
        let alert = UIAlertController(title: "Delete Proxy?", message: "You will not be able to see this proxy or its conversations again.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            DBProxy.deleteProxy(proxy) { _ in }
            _ = self.navigationController?.popViewController(animated: true)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    @objc func goToMakeNewMessageVC() {
        goToMakeNewMessageVC(proxy)
    }
}
