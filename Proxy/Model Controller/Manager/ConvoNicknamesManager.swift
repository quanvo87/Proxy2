import UIKit

class ConvoNicknamesManager: ConvoNicknamesManaging {
    var convoNicknames = [String : String]() {
        didSet {
            collectionView?.reloadData()
        }
    }

    var receiverNickname = "" {
        didSet {
            convoNicknames[receiverId] = receiverNickname == "" ? receiverProxyName : receiverNickname
            navigationItem?.title = convoNicknames[receiverId]
        }
    }

    var senderNickname = "" {
        didSet {
            convoNicknames[senderId] = senderNickname == "" ? senderProxyName : senderNickname
        }
    }

    private let receiverNicknameObserver = ReceiverNicknameObserver()
    private let senderNicknameObserver = SenderNicknameObserver()
    private var receiverId = ""
    private var receiverProxyName = ""
    private var senderId = ""
    private var senderProxyName = ""
    private weak var collectionView: UICollectionView?
    private weak var navigationItem: UINavigationItem?

    func load(convo: Convo, collectionView: UICollectionView, navigationItem: UINavigationItem) {
        receiverId = convo.receiverId
        receiverProxyName = convo.receiverProxyName
        senderId = convo.senderId
        senderProxyName = convo.senderProxyName
        self.collectionView = collectionView
        self.navigationItem = navigationItem
        convoNicknames[receiverId] = receiverProxyName
        convoNicknames[senderId] = senderProxyName
        receiverNicknameObserver.observe(senderId: senderId, convoKey: convo.key, manager: self)
        senderNicknameObserver.observe(senderId: senderId, convoKey: convo.key, manager: self)
    }
}
