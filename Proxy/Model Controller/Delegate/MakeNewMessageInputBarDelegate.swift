import MessageKit
import SearchTextField

class MakeNewMessageInputBarDelegate {
    private weak var buttonManager: ButtonManaging?
    private weak var controller: UIViewController?
    private weak var makeNewMessageDelegate: MakeNewMessageDelegate?
    private weak var senderPickerDelegate: SenderPickerDelegate?
    private weak var tableView: UITableView?

    init(buttonManager: ButtonManaging?,
         controller: UIViewController?,
         makeNewMessageDelegate: MakeNewMessageDelegate?,
         senderPickerDelegate: SenderPickerDelegate?,
         tableView: UITableView?) {
        self.buttonManager = buttonManager
        self.controller = controller
        self.makeNewMessageDelegate = makeNewMessageDelegate
        self.senderPickerDelegate = senderPickerDelegate
        self.tableView = tableView
    }
}

extension MakeNewMessageInputBarDelegate: MessageInputBarDelegate {
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        buttonManager?.setButtons(false)
        guard let sender = senderPickerDelegate?.sender else {
            controller?.showAlert(title: "Sender Missing", message: "Please pick one of your Proxies to send the message from.")
            buttonManager?.setButtons(true)
            return
        }
        guard
            let receiverName = (tableView?.cellForRow(at: IndexPath(row: 1, section: 0)) as? MakeNewMessageReceiverTableViewCell)?.receiverTextField.text,
            receiverName != "" else {
                controller?.showAlert(title: "Receiver Missing", message: "Please enter the receiver's name.")
                buttonManager?.setButtons(true)
                return
        }
        DB.getProxy(key: receiverName) { [weak self] (receiver) in
            guard let receiver = receiver else {
                self?.controller?.showAlert(title: "Receiver Not Found", message: "The receiver you chose could not be found. Please try again.")
                self?.buttonManager?.setButtons(true)
                return
            }
            DB.sendMessage(sender: sender, receiver: receiver, text: text) { [weak self] (result) in
                switch result {
                case .failure(let error):
                    switch error {
                    case .inputTooLong:
                        self?.controller?.showAlert(title: "Message Too Long", message: error.localizedDescription)
                    case .receiverDeletedProxy:
                        self?.controller?.showAlert(title: "Receiver Has Been Deleted", message: error.localizedDescription)
                    default:
                        self?.controller?.showAlert(title: "Error Sending Message", message: error.localizedDescription)
                    }
                    self?.buttonManager?.setButtons(true)
                case .success(let tuple):
                    self?.makeNewMessageDelegate?.newConvo = tuple.convo
                    self?.controller?.navigationController?.dismiss(animated: false)
                }
            }
        }
    }

    func messageInputBar(_ inputBar: MessageInputBar, textViewTextDidChangeTo text: String) {
        inputBar.sendButton.isEnabled = text != ""
    }
}
