import MessageKit

class ConvoInputBarDelegate {
    private weak var manager: ConvoManaging?
    private weak var controller: UIViewController?

    func load(manager: ConvoManaging, controller: UIViewController) {
        self.manager = manager
        self.controller = controller
    }
}

extension ConvoInputBarDelegate: MessageInputBarDelegate {
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        inputBar.inputTextView.text = ""
        guard text.count > 0, let convo = manager?.convo else {
            return
        }
        DB.sendMessage(convo: convo, text: text) { (result) in
            switch result {
            case .failure(let error):
                switch error {
                case .inputTooLong:
                    self.controller?.showAlert(title: "Message Too Long", message: error.localizedDescription)
                case .receiverDeletedProxy:
                    self.controller?.showAlert(title: "Receiver Deleted Proxy", message: error.localizedDescription)
                default:
                    self.controller?.showAlert(title: "Error Sending Message", message: error.localizedDescription)
                }
            default:
                break
            }
        }
    }
}
