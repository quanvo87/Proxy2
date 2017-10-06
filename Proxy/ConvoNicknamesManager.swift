import UIKit

class ConvoNicknamesManager: ConvoNicknamesManaging {
    let receiverNicknameObserver = ReceiverNicknameObserver()
    let senderNicknameObserver = SenderNicknameObserver()
    var convo: Convo?
    weak var collectionView: UICollectionView?
    weak var navigationItem: UINavigationItem?

    func load(collectionView: UICollectionView, convo: Convo, navigationItem: UINavigationItem) {
        self.collectionView = collectionView
        self.convo = convo
        self.navigationItem = navigationItem
        nicknames[convo.receiverId] = convo.receiverProxyName
        nicknames[convo.senderId] = convo.senderProxyName
        receiverNicknameObserver.observe(convo: convo, manager: self)
        senderNicknameObserver.observe(convo: convo, manager: self)
    }

    var nicknames = [String : String]() {
        didSet {
            collectionView?.reloadData()
        }
    }

    var receiverNickname = String() {
        didSet {
            guard let receiverId = convo?.receiverId else { return }
            nicknames[receiverId] = receiverNickname == "" ? convo?.receiverProxyName : receiverNickname
            navigationItem?.title = nicknames[receiverId]
        }
    }

    var senderNickname = String() {
        didSet {
            guard let senderId = convo?.senderId else { return }
            nicknames[senderId] = senderNickname == "" ? convo?.senderProxyName : senderNickname
        }
    }
}
