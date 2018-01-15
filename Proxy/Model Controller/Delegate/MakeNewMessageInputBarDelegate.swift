import MessageKit
import SearchTextField

class MakeNewMessageInputBarDelegate {
    private weak var controller: UIViewController?
    private weak var makeNewMessageDelegate: MakeNewMessageDelegate?
    private weak var manager: ButtonManaging?
    private weak var senderPickerDelegate: SenderPickerDelegate?
    private weak var textField: SearchTextField?

    init(controller: UIViewController?,
         makeNewMessageDelegate: MakeNewMessageDelegate?,
         manager: ButtonManaging?,
         senderPickerDelegate: SenderPickerDelegate?,
         textField: SearchTextField?) {
        self.controller = controller
        self.makeNewMessageDelegate = makeNewMessageDelegate
        self.manager = manager
        self.senderPickerDelegate = senderPickerDelegate
        self.textField = textField
    }
}

extension MakeNewMessageInputBarDelegate: MessageInputBarDelegate {
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        manager?.setButtons(false)
        guard let sender = senderPickerDelegate?.sender else {
            controller?.showAlert(title: "Sender Missing", message: "Please pick one of your Proxies to send the message from.")
            manager?.setButtons(true)
            return
        }
        guard
            let receiverName = textField?.text,
            receiverName != "" else {
                controller?.showAlert(title: "Receiver Missing", message: "Please enter the receiver's name.")
                manager?.setButtons(true)
                return
        }
        DB.getProxy(key: receiverName) { [weak self] (receiver) in
            guard let receiver = receiver else {
                self?.controller?.showAlert(title: "Receiver Not Found", message: "The receiver you chose could not be found. Please try again.")
                self?.manager?.setButtons(true)
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
                    self?.manager?.setButtons(true)
                case .success(let tuple):
                    self?.makeNewMessageDelegate?.newConvo = tuple.convo
                    self?.controller?.navigationController?.dismiss(animated: true)
                }
            }
        }
    }

    func messageInputBar(_ inputBar: MessageInputBar, textViewTextDidChangeTo text: String) {
        inputBar.sendButton.isEnabled = text != ""
    }
}
