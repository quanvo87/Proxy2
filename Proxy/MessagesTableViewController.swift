import UIKit

class MessagesTableViewController: UITableViewController, MakeNewMessageDelegate {
    let authManager = MessagesAuthManager()
    let buttonManager = MessagesButtonManager()
    let convosManager = ConvosManager()
    let dataSource = MessagesTableViewDataSource()
    let delegate = MessagesTableViewDelegate()
    let reloader = TableViewReloader()
    let unreadCountManager = MessagesUnreadCountManager()
    var newConvo: Convo?

    override func viewDidLoad() {
        super.viewDidLoad()
        authManager.load(self)
        navigationItem.title = "Messages"
        reloader.tableView = tableView
        tabBarController?.tabBar.items?.setupForTabBar()
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.dataSource = dataSource
        tableView.delegate = delegate
        tableView.rowHeight = 80
        tableView.separatorStyle = .none
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if let newConvo = newConvo {
            goToConvoVC(newConvo)
            self.newConvo = nil
        }
    }
}

private extension Array where Element: UITabBarItem {
    func setupForTabBar() {
        guard
            let tab0 = self[safe: 0],
            let tab1 = self[safe: 1],
            let tab2 = self[safe: 2] else {
                return
        }
        tab0.image = UIImage(named: "messages")
        tab1.image = UIImage(named: "proxies")
        tab2.image = UIImage(named: "me")
    }
}
