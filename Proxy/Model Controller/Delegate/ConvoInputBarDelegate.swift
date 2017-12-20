import MessageKit

class ConvoInputBarDelegate {
    private var convo = Convo()

    func load(_ convo: Convo) {
        self.convo = convo
    }
}

extension ConvoInputBarDelegate: MessageInputBarDelegate {
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        inputBar.inputTextView.text = ""
        DBMessage.sendMessage(text: text, senderConvo: convo) { _ in }
    }
}
