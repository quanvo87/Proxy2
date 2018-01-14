import MessageKit

class ConvoInputBarDelegate {
    private weak var controller: UIViewController?
    private weak var manager: ConvoManaging?

    init(controller: UIViewController?, manager: ConvoManaging?) {
        self.controller = controller
        self.manager = manager
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
