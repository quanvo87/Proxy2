import UIKit

class MessagesTableViewDataSource: NSObject {
    private weak var controller: MessagesTableViewController?

    init(_ controller: MessagesTableViewController) {
        super.init()
        controller.tableView.dataSource = self
        self.controller = controller
    }
}

extension MessagesTableViewDataSource: UITableViewDataSource {
    var convos: [Convo] {
        return controller?.convos ?? []
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
