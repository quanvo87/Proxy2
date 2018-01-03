import MessageKit

class ConvoInputBarDelegate {
    private weak var convoManager: ConvoManaging?
    private weak var controller: UIViewController?

    func load(convoManager: ConvoManaging, controller: UIViewController) {
        self.convoManager = convoManager
        self.controller = controller
    }
}

extension ConvoInputBarDelegate: MessageInputBarDelegate {
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        inputBar.inputTextView.text = ""
        guard text.count > 0, let convo = convoManager?.convo else {
            return
        }
        DB.sendMessage(senderConvo: convo, text: text) { (result) in
            switch result {
            case .failure(let error):
                switch error {
                case .inputTooLong:
                    self.controller?.showAlert("Message Too Long", message: "Please try shortening the message.")
                default:
                    self.controller?.showAlert("Error Sending Message", message: "There was an error sending the message. Please try again.")
                }
            default:
                break
            }
        }
    }
}
