import UIKit

class ConvoIsActiveChecker {
    weak var controller: UIViewController?

    func check(controller: UIViewController, convo: Convo) {
        self.controller = controller
        checkIfReceiverIsBlocked(convo)
        checkIfSenderDeletedProxy(convo)
        checkIfSenderLeftConvo(convo)
    }
}

private extension ConvoIsActiveChecker {
    func checkIfReceiverIsBlocked(_ convo: Convo) {
        DBConvo.receiverIsBlocked(convo) { (receiverIsBlocked) in
            if receiverIsBlocked {
                self.close()
            }
        }
    }

    func checkIfSenderDeletedProxy(_ convo: Convo) {
        DBConvo.getConvo(withKey: convo.key, belongingTo: convo.senderId) { (convo) in
            if convo == nil {
                self.close()
            }
        }
    }

    func checkIfSenderLeftConvo(_ convo: Convo) {
        DBConvo.senderLeftConvo(convo) { (senderLeftConvo) in
            if senderLeftConvo {
                self.close()
            }
        }
    }

    func close() {
        _ = controller?.navigationController?.popViewController(animated: true)
    }
}
