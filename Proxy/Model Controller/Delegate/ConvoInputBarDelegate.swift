import MessageKit

class ConvoInputBarDelegate {
    private var convo = Convo()
    private weak var controller: UIViewController?

    func load(convo: Convo, controller: UIViewController) {
        self.convo = convo
        self.controller = controller
    }
}

extension ConvoInputBarDelegate: MessageInputBarDelegate {
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        DBMessage.sendMessage(text: text, senderConvo: convo) { (result) in
            switch result {
            case .failure(let error):
                switch error {
                case .inputTooLong:
                    self.controller?.showAlert("Message Too Long", message: "Please try shortening the message.")
                default:
                    self.controller?.showAlert("Error Sending Message", message: "There was an error sending the message. Please try again.")
                }
            case .success:
                inputBar.inputTextView.text = ""
            }
        }
    }
}
