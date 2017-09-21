import FirebaseDatabase
import JSQMessagesViewController
import UIKit

class ReceiverIconObserver: ReferenceObserving {
    private let receiverId: String
    let ref: DatabaseReference?
    private weak var controller: ConvoMemberIconsObserving?
    private(set) var handle: DatabaseHandle?

    init(controller: ConvoMemberIconsObserving, convo: Convo) {
        self.controller = controller
        receiverId = convo.receiverId
        ref = DB.makeReference(Child.proxies, convo.receiverId, convo.receiverProxyKey, Child.icon)
        observe()
    }

    func observe() {
        stopObserving()
        handle = ref?.observe(.value, with: { [weak self] (data) in
            guard let icon = data.value as? String else { return }
            UIImage.makeImage(named: icon) { (image) in
                guard
                    let image = image,
                    let strongSelf = self else {
                        return
                }
                strongSelf.controller?.convoMemberIcons[strongSelf.receiverId] = JSQMessagesAvatarImage(placeholder: image)
                DispatchQueue.main.async {
                    strongSelf.controller?.collectionView.reloadData()
                }
            }
        })
    }

    deinit {
        stopObserving()
    }
}

class SenderIconObserver: ReferenceObserving {
    private let senderId: String
    let ref: DatabaseReference?
    private weak var controller: ConvoMemberIconsObserving?
    private(set) var handle: DatabaseHandle?

    init(controller: ConvoMemberIconsObserving, convo: Convo) {
        self.controller = controller
        ref = DB.makeReference(Child.proxies, convo.senderId, convo.senderProxyKey, Child.icon)
        senderId = convo.senderId
        observe()
    }

    func observe() {
        stopObserving()
        handle = ref?.observe(.value, with: { [weak self] (data) in
            guard let icon = data.value as? String else { return }
            UIImage.makeImage(named: icon) { (image) in
                guard
                    let image = image,
                    let strongSelf = self else {
                        return
                }
                strongSelf.controller?.convoMemberIcons[strongSelf.senderId] = JSQMessagesAvatarImage(placeholder: image)
                DispatchQueue.main.async {
                    strongSelf.controller?.collectionView.reloadData()
                }
            }
        })
    }

    deinit {
        stopObserving()
    }
}

protocol ConvoMemberIconsObserving: class, JSQMessagesCollectionViewOwning {
    var convoMemberIcons: [String: JSQMessagesAvatarImage] { get set }
}
