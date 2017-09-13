import UIKit

class ProxyTableViewController: UITableViewController, MakeNewMessageDelegate {
    private var dataSource: ProxyTableViewDataSource?
    private var delegate: ProxyTableViewDelegate?
    var newConvo: Convo?
    var proxy: Proxy?

    override func viewDidLoad() {
        super.viewDidLoad()
        if let proxy = proxy {
            dataSource = ProxyTableViewDataSource(proxy: proxy, tableViewController: self)
        }
        delegate = ProxyTableViewDelegate(self)
        navigationItem.rightBarButtonItems = [UIBarButtonItem.makeButton(target: self, action: #selector(goToMakeNewMessageVC), imageName: .makeNewMessage),
                                              UIBarButtonItem.makeButton(target: self, action: #selector(deleteProxy), imageName: .delete)]
        tableView.delaysContentTouches = false
        tableView.separatorStyle = .none
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
        goToMakeNewMessageVC(proxy)
    }
}
