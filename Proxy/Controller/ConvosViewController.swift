import UIKit

class ConvosViewController: UIViewController, MakeNewMessageDelegate {
    var newConvo: Convo?

    private let convosManager = ConvosManager()
    private let itemsToDeleteManager = ItemsToDeleteManager()
    private let dataSource = ConvosTableViewDataSource()
    private let delegate = ConvosTableViewDelegate()
    private let tableView = UITableView()
    private let buttonManager = ConvosButtonManager()
    private weak var unreadMessagesManager: UnreadMessagesManaging?

    init(uid: String, unreadMessagesManager: UnreadMessagesManaging) {
        self.unreadMessagesManager = unreadMessagesManager
        
        super.init(nibName: nil, bundle: nil)

        navigationItem.title = "Messages"

        convosManager.load(convosOwner: uid, tableView: tableView)

        dataSource.load(manager: convosManager)

        delegate.load(convosManager: convosManager, itemsToDeleteManager: itemsToDeleteManager, unreadMessagesManager: unreadMessagesManager, controller: self)

        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.dataSource = dataSource
        tableView.delegate = delegate
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.register(UINib(nibName: Identifier.convosTableViewCell, bundle: nil), forCellReuseIdentifier: Identifier.convosTableViewCell)
        tableView.rowHeight = 80
        tableView.separatorStyle = .none
        view.addSubview(tableView)

        buttonManager.load(uid: uid, itemsToDeleteManager: itemsToDeleteManager, makeNewMessageDelegate: self, tableView: tableView, viewController: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if let newConvo = newConvo {
            navigationController?.showConvoViewController(convo: newConvo, unreadMessagesManager: unreadMessagesManager)
            self.newConvo = nil
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
