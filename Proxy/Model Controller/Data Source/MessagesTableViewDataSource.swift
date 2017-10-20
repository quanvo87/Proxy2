import UIKit

class MessagesTableViewDataSource: NSObject {
    private weak var manager: ConvosManaging?

    func load(manager: ConvosManaging, tableView: UITableView) {
        self.manager = manager
        tableView.dataSource = self
        tableView.register(UINib(nibName: Name.convosTableViewCell, bundle: nil), forCellReuseIdentifier: Name.convosTableViewCell)
    }
}

extension MessagesTableViewDataSource: UITableViewDataSource {
    var convos: [Convo] {
        return manager?.convos ?? []
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: Name.convosTableViewCell) as? ConvosTableViewCell,
            let convo = convos[safe: indexPath.row] else {
                return tableView.dequeueReusableCell(withIdentifier: Name.convosTableViewCell, for: indexPath)
        }
        cell.configure(convo)
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return convos.count
    }
}
