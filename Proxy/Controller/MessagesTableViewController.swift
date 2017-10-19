import UIKit

class MessagesTableViewController: UITableViewController, MakeNewMessageDelegate {
//    private let authManager = MessagesAuthManager()
//    private let dataSource = MessagesTableViewDataSource()
//    private let delegate = MessagesTableViewDelegate()
//    private let buttonManager = MessagesButtonManager()
//    private let convosManager = ConvosManager()
//    private let itemsToDeleteManager = ItemsToDeleteManager()
//    private let unreadCountManager = MessagesUnreadCountManager()
    var newConvo: Convo?
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
////        authManager.load(self)
//        navigationItem.title = "Messages"
//        tableView.delegate = delegate
//        for item in tabBarController?.tabBar.items ?? [] {
//            item.isEnabled = false
//        }
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(true)
//        if let newConvo = newConvo {
//            showConvoController(newConvo)
//            self.newConvo = nil
//        }
//    }
//
//    func logIn() {
//        dataSource.load(manager: convosManager, tableView: tableView)
//        delegate.load(controller: self, convosManager: convosManager, itemsToDeleteManager: itemsToDeleteManager)
//        buttonManager.load(controller: self, itemsToDeleteManager: itemsToDeleteManager)
//        convosManager.load(convosOwner: Shared.shared.uid, tableView: tableView)
//        unreadCountManager.load(self)
//        tableView.allowsMultipleSelectionDuringEditing = true
//        tableView.delegate = delegate
//        tableView.rowHeight = 80
//        tableView.separatorStyle = .none
//        tabBarController?.tabBar.items?.setupForTabBar()
//        Shared.shared.queue.async {
//            DBProxy.fixConvoCounts { _ in }
//        }
//    }
}

//private extension Array where Element: UITabBarItem {
//    func setupForTabBar() {
//        guard
//            let tab0 = self[safe: 0],
//            let tab1 = self[safe: 1],
//            let tab2 = self[safe: 2] else {
//                return
//        }
//        tab0.isEnabled = true
//        tab1.isEnabled = true
//        tab2.isEnabled = true
//        tab0.image = UIImage(named: "messages")
//        tab1.image = UIImage(named: "proxies")
//        tab2.image = UIImage(named: "me")
//    }
//}

