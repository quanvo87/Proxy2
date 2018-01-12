import MessageKit

class MakeNewMessageInputBarDelegate {
    private weak var controller: MakeNewMessageViewController?

    init(_ controller: MakeNewMessageViewController) {
        self.controller = controller
    }
}

extension MakeNewMessageInputBarDelegate: MessageInputBarDelegate {
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        controller?.setButtons(false)
        guard let sender = controller?.sender else {
            controller?.showAlert(title: "Sender Missing", message: "Please pick one of your Proxies to send the message from.")
            controller?.setButtons(true)
            return
        }
        guard
            let receiverName = controller?.receiverNameTextField?.text,
            receiverName != "" else {
                controller?.showAlert(title: "Receiver Missing", message: "Please enter the receiver's name.")
                controller?.setButtons(true)
                return
        }
        DB.getProxy(key: receiverName) { [weak self] (receiver) in
            guard let receiver = receiver else {
                self?.controller?.showAlert(title: "Receiver Not Found", message: "The receiver you chose could not be found. Please try again.")
                self?.controller?.setButtons(true)
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
                    self?.controller?.setButtons(true)
                case .success(let tuple):
                    self?.controller?.makeNewMessageDelegate?.newConvo = tuple.convo
                    self?.controller?.navigationController?.dismiss(animated: true)
                }
            }
        }
    }

    func messageInputBar(_ inputBar: MessageInputBar, textViewTextDidChangeTo text: String) {
        inputBar.sendButton.isEnabled = text != ""
    }
}
