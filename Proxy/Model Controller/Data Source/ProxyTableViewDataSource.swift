import UIKit

class ProxyTableViewDataSource: NSObject {
    private weak var proxyManager: ProxyManaging?
    private weak var convosManager: ConvosManaging?
    private weak var controller: UIViewController?

    func load(proxyManager: ProxyManaging, convosManager: ConvosManaging, controller: UIViewController) {
        self.proxyManager = proxyManager
        self.convosManager = convosManager
        self.controller = controller
    }
}

extension ProxyTableViewDataSource: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            guard
                let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.senderProxyTableViewCell) as? SenderProxyTableViewCell,
                let proxy = proxyManager?.proxy else {
                    return tableView.dequeueReusableCell(withIdentifier: Identifier.senderProxyTableViewCell, for: indexPath)
            }
            cell.load(proxy)
            cell.selectionStyle = .none
            cell.changeIconButton.addTarget(self, action: #selector(showIconPickerController), for: .touchUpInside)
            cell.nicknameButton.addTarget(self, action: #selector(showEditProxyNicknameAlert), for: .touchUpInside)
            return cell
        case 1:
            guard
                let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.convosTableViewCell) as? ConvosTableViewCell,
                let convo = convosManager?.convos[safe: indexPath.row] else {
                    return tableView.dequeueReusableCell(withIdentifier: Identifier.convosTableViewCell, for: indexPath)
            }
            cell.load(convo)
            return cell
        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return convosManager?.convos.count ?? 0
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1:
            return "CONVERSATIONS"
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 1 && convosManager?.convos.count == 0 {
            return "This Proxy is not in any conversations yet."
        } else {
            return nil
        }
    }
}

private extension ProxyTableViewDataSource {
    @objc func showEditProxyNicknameAlert() {
        guard let proxy = proxyManager?.proxy else {
            return
        }
        controller?.showEditProxyNicknameAlert(proxy)
    }

    @objc func showIconPickerController() {
        guard let proxy = proxyManager?.proxy else {
            return
        }
        controller?.showIconPickerController(proxy)
    }
}
