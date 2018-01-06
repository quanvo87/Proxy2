import UIKit

class ConvosTableViewDataSource: NSObject {
    private weak var manager: ConvosManaging?

    private var convos: [Convo] {
        return manager?.convos ?? []
    }

    func load(_ manager: ConvosManaging) {
        self.manager = manager
    }
}

extension ConvosTableViewDataSource: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.convosTableViewCell) as? ConvosTableViewCell,
            let convo = convos[safe: indexPath.row] else {
                return tableView.dequeueReusableCell(withIdentifier: Identifier.convosTableViewCell, for: indexPath)
        }
        cell.load(convo)
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return convos.count
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if convos.isEmpty {
            return "No messages yet. Tap the bouncing button to begin 💬."
        } else {
            return nil
        }
    }
}
