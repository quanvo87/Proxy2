import MessageKit
import SearchTextField

class MakeNewMessageInputBarDelegate {
    private var isSending = false
    private weak var buttonManager: ButtonManaging?
    private weak var controller: UIViewController?
    private weak var newConvoManager: NewConvoManaging?
    private weak var senderManager: SenderManaging?
    private weak var tableView: UITableView?

    init(buttonManager: ButtonManaging?,
         controller: UIViewController?,
         newConvoManager: NewConvoManaging?,
         senderManager: SenderManaging?,
         tableView: UITableView?) {
        self.buttonManager = buttonManager
        self.controller = controller
        self.newConvoManager = newConvoManager
        self.senderManager = senderManager
        self.tableView = tableView
    }
}

extension MakeNewMessageInputBarDelegate: MessageInputBarDelegate {
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        buttonManager?.setButtons(false)
        isSending = true
        guard let sender = senderManager?.sender else {
            controller?.showAlert(title: "Sender Missing", message: "Please pick one of your Proxies to send the message from.")
            buttonManager?.setButtons(true)
            isSending = false
            return
        }
        guard
            let receiverName = (tableView?.cellForRow(at: IndexPath(row: 1, section: 0)) as? MakeNewMessageReceiverTableViewCell)?.receiverTextField.text,
            receiverName != "" else {
                controller?.showAlert(title: "Receiver Missing", message: "Please enter the receiver's name.")
                buttonManager?.setButtons(true)
                isSending = false
                return
        }
//        Database.getProxy(key: receiverName) { [weak self] (receiver) in
//            guard let receiver = receiver else {
//                self?.controller?.showAlert(title: "Receiver Not Found", message: "The receiver you chose could not be found. Please try again.")
//                self?.buttonManager?.setButtons(true)
//                self?.isSending = false
//                return
//            }
//            DB.sendMessage(sender: sender, receiver: receiver, text: text) { [weak self] (result) in
//                switch result {
//                case .failure(let error):
//                    switch error {
//                    case .inputTooLong:
//                        self?.controller?.showAlert(title: "Message Too Long", message: error.localizedDescription)
//                    case .receiverDeletedProxy:
//                        self?.controller?.showAlert(title: "Receiver Has Been Deleted", message: error.localizedDescription)
//                    default:
//                        self?.controller?.showAlert(title: "Error Sending Message", message: error.localizedDescription)
//                    }
//                    self?.buttonManager?.setButtons(true)
//                    self?.isSending = false
//                case .success(let tuple):
//                    self?.newConvoManager?.newConvo = tuple.convo
//                    self?.controller?.navigationController?.dismiss(animated: false)
//                }
//            }
//        }
    }

    func messageInputBar(_ inputBar: MessageInputBar, textViewTextDidChangeTo text: String) {
        if isSending {
            inputBar.sendButton.isEnabled = false
        } else {
            inputBar.sendButton.isEnabled = text != ""
        }
    }
}
