import UIKit

class ConvoNicknamesManager: ConvoNicknamesManaging {
    private let receiverNicknameObserver = ReceiverNicknameObserver()
    private let senderNicknameObserver = SenderNicknameObserver()
    private var receiverId = ""
    private var receiverProxyName = ""
    private var senderId = ""
    private var senderProxyName = ""
    private weak var collectionView: UICollectionView?
    private weak var navigationItem: UINavigationItem?

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

    func load(convo: Convo, collectionView: UICollectionView, navigationItem: UINavigationItem) {
        receiverId = convo.receiverId
        receiverProxyName = convo.receiverProxyName
        senderId = convo.senderId
        senderProxyName = convo.senderProxyName
        self.collectionView = collectionView
        self.navigationItem = navigationItem
        convoNicknames[receiverId] = receiverProxyName
        convoNicknames[senderId] = senderProxyName
        receiverNicknameObserver.observe(receiverNicknameManager: self, convoKey: convo.key, senderId: senderId)
        senderNicknameObserver.observe(senderNicknameManager: self, convoKey: convo.key, senderId: senderId)
    }
}
