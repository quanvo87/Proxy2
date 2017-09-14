import UIKit

class MessagesTableViewDataSource: NSObject {
    private var id: Int { return ObjectIdentifier(self).hashValue }
    private weak var convosObserver: ConvosObserver?

    init(_ tableView: UITableView) {
        super.init()
        convosObserver = (UIApplication.shared.delegate as? AppDelegate)?.convosObserver
        convosObserver?.tableViews.setObject(tableView, forKey: id as AnyObject)
        convosObserver?.observeConvos(forOwner: Shared.shared.uid)
        tableView.dataSource = self
    }

    deinit {
        convosObserver?.tableViews.removeObject(forKey: id as AnyObject)
    }
}

extension MessagesTableViewDataSource: UITableViewDataSource {
    var convos: [Convo] {
        return convosObserver?.convos ?? []
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.convosTableViewCell) as? ConvosTableViewCell,
            let convo = convos[safe: indexPath.row] else {
                return tableView.dequeueReusableCell(withIdentifier: Identifier.convosTableViewCell, for: indexPath)
        }
        cell.configure(convo)
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return convos.count
    }
}
