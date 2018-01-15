import UIKit

class ConvosViewController: UIViewController, MakeNewMessageDelegate {
    var newConvo: Convo?
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let uid: String
    private weak var presenceManager: PresenceManaging?
    private weak var proxiesManager: ProxiesManaging?
    private weak var unreadMessagesManager: UnreadMessagesManaging?
    private lazy var buttonManager = ConvosButtonManager(uid: uid,
                                                         controller: self,
                                                         delegate: self,
                                                         manager: proxiesManager)
    private lazy var convosManager = ConvosManager(proxyKey: nil,
                                                   uid: uid,
                                                   manager: buttonManager,
                                                   tableView: tableView)
    private lazy var dataSource = ConvosTableViewDataSource(convosManager)
    private lazy var delegate = ConvosTableViewDelegate(controller: self,
                                                        convosManager: convosManager,
                                                        presenceManager: presenceManager,
                                                        proxiesManager: proxiesManager,
                                                        unreadMessagesManager: unreadMessagesManager)

    init(uid: String,
         presenceManager: PresenceManaging?,
         proxiesManager: ProxiesManaging?,
         unreadMessagesManager: UnreadMessagesManaging?) {
        self.uid = uid
        self.presenceManager = presenceManager
        self.proxiesManager = proxiesManager
        self.unreadMessagesManager = unreadMessagesManager

        super.init(nibName: nil, bundle: nil)

        navigationItem.title = "Messages"

        tableView.dataSource = dataSource
        tableView.delegate = delegate
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.register(UINib(nibName: Identifier.convosTableViewCell, bundle: nil),
                           forCellReuseIdentifier: Identifier.convosTableViewCell)
        tableView.rowHeight = 80
        tableView.sectionHeaderHeight = 0

        view.addSubview(tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if convosManager.convos.isEmpty {
            buttonManager.animateButton()
        }
        if let newConvo = newConvo {
            navigationController?.showConvoViewController(convo: newConvo,
                                                          presenceManager: presenceManager,
                                                          proxiesManager: proxiesManager,
                                                          unreadMessagesManager: unreadMessagesManager)
            self.newConvo = nil
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
