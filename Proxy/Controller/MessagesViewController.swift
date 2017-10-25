import UIKit

class MessagesViewController: UIViewController, MakeNewMessageDelegate {
    private let buttonManager = MessagesButtonManager()
    private let convosManager = ConvosManager()
    private let dataSource = MessagesTableViewDataSource()
    private let delegate = MessagesTableViewDelegate()
    private let itemsToDeleteManager = ItemsToDeleteManager()
    private let unreadCountManager = MessagesUnreadCountManager()
    private let tableView = UITableView()
    private let uid: String
    var newConvo: Convo?

    init(_ uid: String) {
        self.uid = uid
        
        super.init(nibName: nil, bundle: nil)

        navigationItem.title = "Messages"

        dataSource.load(manager: convosManager)
        delegate.load(controller: self, convosManager: convosManager, itemsToDeleteManager: itemsToDeleteManager)

        buttonManager.load(controller: self, delegate: self, itemsToDeleteManager: itemsToDeleteManager, tableView: tableView, uid: uid)
        convosManager.load(convosOwner: uid, tableView: tableView)
        unreadCountManager.load(uid: uid, controller: self)

        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.dataSource = dataSource
        tableView.delegate = delegate
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.register(UINib(nibName: Name.convosTableViewCell, bundle: nil), forCellReuseIdentifier: Name.convosTableViewCell)
        tableView.rowHeight = 80
        tableView.separatorStyle = .none

        view.addSubview(tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if let newConvo = newConvo {
            showConvo(newConvo)
            self.newConvo = nil
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
