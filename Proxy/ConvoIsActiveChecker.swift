import UIKit

struct ConvoIsActiveChecker {
    private let convo: Convo
    private weak var controller: UIViewController?

    init(controller: UIViewController, convo: Convo) {
        self.controller = controller
        self.convo = convo
    }

    func check() {
        checkIfReceiverIsBlocked()
        checkIfSenderDeletedProxy()
        checkIfSenderLeftConvo()
    }

    private func checkIfReceiverIsBlocked() {
        DBConvo.receiverIsBlocked(convo) { (receiverIsBlocked) in
            if receiverIsBlocked {
                self.close()
            }
        }
    }

    private func checkIfSenderDeletedProxy() {
        DBConvo.getConvo(withKey: convo.key, belongingTo: convo.senderId) { (convo) in
            if convo == nil {
                self.close()
            }
        }
    }

    private func checkIfSenderLeftConvo() {
        DBConvo.senderLeftConvo(convo) { (senderLeftConvo) in
            if senderLeftConvo {
                self.close()
            }
        }
    }

    private func close() {
        _ = controller?.navigationController?.popViewController(animated: true)
    }
}
