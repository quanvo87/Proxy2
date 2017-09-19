import FirebaseDatabase
import JSQMessagesViewController
import UIKit

protocol JSQMessagesCollectionViewOwning {
    var collectionView: JSQMessagesCollectionView! { get }
}

protocol ConvoMemberIconsObserving: class, JSQMessagesCollectionViewOwning {
    var convoMemberIcons: [String: JSQMessagesAvatarImage] { get set }
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
        handle = ref?.observe(.value, with: { (data) in
            guard let icon = data.value as? String else { return }
            UIImage.makeImage(named: icon) { (image) in
                guard let image = image else { return }
                self.controller?.convoMemberIcons[self.senderId] = JSQMessagesAvatarImage(placeholder: image)
                DispatchQueue.main.async {
                    self.controller?.collectionView.reloadData()
                }
            }
        })
    }

    deinit {
        stopObserving()
    }
}

class ReceiverIconObserver: ReferenceObserving {
    private let receiverId: String
    let ref: DatabaseReference?
    private weak var controller: ConvoMemberIconsObserving?
    private(set) var handle: DatabaseHandle?

    init(controller: ConvoMemberIconsObserving, convo: Convo) {
        self.controller = controller
        receiverId = convo.receiverId
        ref = DB.makeReference(Child.convos, convo.senderId, convo.key, Child.receiverIcon)
        observe()
    }

    func observe() {
        stopObserving()
        handle = ref?.observe(.value, with: { (data) in
            guard let icon = data.value as? String else { return }
            UIImage.makeImage(named: icon) { (image) in
                guard let image = image else { return }
                self.controller?.convoMemberIcons[self.receiverId] = JSQMessagesAvatarImage(placeholder: image)
                DispatchQueue.main.async {
                    self.controller?.collectionView.reloadData()
                }
            }
        })
    }

    deinit {
        stopObserving()
    }
}

