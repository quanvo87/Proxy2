import UIKit

class ProxyTableViewController: UITableViewController, MakeNewMessageDelegate {
    private var dataSource: ProxyTableViewDataSource?
    private var delegate: ProxyTableViewDelegate?
    var newConvo: Convo?
    var proxy: Proxy?

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = ProxyTableViewDelegate(self)
        navigationItem.rightBarButtonItems = [UIBarButtonItem.makeButton(target: self, action: #selector(self.goToMakeNewMessageVC), imageName: .makeNewMessage),
                                              UIBarButtonItem.makeButton(target: self, action: #selector(self.deleteProxy), imageName: .delete)]
        tableView.delaysContentTouches = false
        tableView.separatorStyle = .none
        if let proxy = proxy {
            dataSource = ProxyTableViewDataSource(proxy: proxy, tableViewController: self)
        }
        for case let scrollView as UIScrollView in tableView.subviews {
            scrollView.delaysContentTouches = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        if let newConvo = newConvo {
            goToConvoVC(newConvo)
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
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    @objc func goToMakeNewMessageVC() {
        guard let makeNewMessageVC = self.storyboard?.instantiateViewController(withIdentifier: Identifier.makeNewMessageViewController) as? MakeNewMessageViewController else { return }
        makeNewMessageVC.delegate = self
        makeNewMessageVC.sender = proxy
        let navigationController = UINavigationController(rootViewController: makeNewMessageVC)
        present(navigationController, animated: true)
    }
}
