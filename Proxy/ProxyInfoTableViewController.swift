class ProxyInfoTableViewController: UITableViewController {
    private let dataSource = ProxyInfoTableViewDataSource()
    private var newConvo: Convo?
    private var proxy = Proxy()

    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource.observe(proxy: proxy, tableViewController: self)

        navigationItem.rightBarButtonItems = [ButtonManager.makeButton(target: self, action: #selector(self.goToMakeNewMessageVC), imageName: .makeNewMessage),
                                              ButtonManager.makeButton(target: self, action: #selector(self.deleteProxy), imageName: .delete)]

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

    func setProxy(_ proxy: Proxy) {
        self.proxy = proxy
    }
}

private extension ProxyInfoTableViewController {
    @objc func deleteProxy() {
        let alert = UIAlertController(title: "Delete Proxy?", message: "You will not be able to see this proxy or its conversations again.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            DBProxy.deleteProxy(self.proxy) { _ in }
            _ = self.navigationController?.popViewController(animated: true)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    @objc func goToMakeNewMessageVC() {
        guard let makeNewMessageVC = self.storyboard?.instantiateViewController(withIdentifier: Identifier.NewMessageViewController) as? MakeNewMessageViewController else { return }
        makeNewMessageVC.setDelegate(to: self)
        makeNewMessageVC.setSender(to: proxy)
        let navigationController = UINavigationController(rootViewController: makeNewMessageVC)
        present(navigationController, animated: true)
    }
}

extension ProxyInfoTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if  indexPath.section == 1,
            let row = tableView.indexPathForSelectedRow?.row,
            let convo = dataSource.convos[safe: row],
            let convoVC = storyboard?.instantiateViewController(withIdentifier: Identifier.ConvoViewController) as? ConvoViewController {
            convoVC.convo = convo
            navigationController?.pushViewController(convoVC, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return CGFloat.leastNormalMagnitude
        case 1:
            return 15
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 140
        case 1:
            return 80
        default:
            return 0
        }
    }
}

extension ProxyInfoTableViewController: MakeNewMessageDelegate {
    func setNewConvo(to convo: Convo) {
        newConvo = convo
    }
}
