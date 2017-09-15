import UIKit

class ProxyTableViewController: UITableViewController, MakeNewMessageDelegate, ProxyObserving {
    private var convosObserver: ConvosObserver?
    private var dataSource: ProxyTableViewDataSource?
    private var delegate: ProxyTableViewDelegate?
    private var proxyObserver: ProxyObserver?
    var newConvo: Convo?
    var proxy: Proxy?

    var convos: [Convo] {
        return convosObserver?.convos ?? []
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItems = [UIBarButtonItem.makeButton(target: self, action: #selector(goToMakeNewMessageVC), imageName: .makeNewMessage),
                                              UIBarButtonItem.makeButton(target: self, action: #selector(deleteProxy), imageName: .delete)]
        guard let proxy = proxy else { return }
        convosObserver = ConvosObserver(owner: proxy.key, tableView: tableView)
        convosObserver?.observe()
        dataSource = ProxyTableViewDataSource(self)
        delegate = ProxyTableViewDelegate(self)
        proxyObserver = ProxyObserver(proxy: proxy, controller: self)
        proxyObserver?.observe()
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
