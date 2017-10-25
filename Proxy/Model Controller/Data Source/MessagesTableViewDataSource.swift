import UIKit

class MessagesTableViewDataSource: NSObject {
    private weak var manager: ConvosManaging?

    func load(manager: ConvosManaging) {
        self.manager = manager
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
        cell.load(convo)
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return convos.count
    }
}
