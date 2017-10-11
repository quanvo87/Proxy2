import UIKit

class ConvoNicknamesManager: ConvoNicknamesManaging {
    private let receiverNicknameObserver = ReceiverNicknameObserver()
    private let senderNicknameObserver = SenderNicknameObserver()
    private var receiverId = String()
    private var receiverProxyName = String()
    private var senderId = String()
    private var senderProxyName = String()
    private weak var collectionView: UICollectionView?
    private weak var navigationItem: UINavigationItem?

    func load(receiverId: String,
              receiverProxyName: String,
              senderId: String,
              senderProxyName: String,
              key: String,
              collectionView: UICollectionView,
              navigationItem: UINavigationItem) {
        self.receiverId = receiverId
        self.receiverProxyName = receiverProxyName
        self.senderId = senderId
        self.senderProxyName = senderProxyName
        self.collectionView = collectionView
        self.navigationItem = navigationItem
        nicknames[receiverId] = receiverProxyName
        nicknames[senderId] = senderProxyName
        receiverNicknameObserver.observe(senderId: senderId, key: key, manager: self)
        senderNicknameObserver.observe(senderId: senderId, key: key, manager: self)
    }

    var nicknames = [String : String]() {
        didSet {
            collectionView?.reloadData()
        }
    }

    var receiverNickname = String() {
        didSet {
            nicknames[receiverId] = receiverNickname == "" ? receiverProxyName : receiverNickname
            navigationItem?.title = nicknames[receiverId]
        }
    }

    var senderNickname = String() {
        didSet {
            nicknames[senderId] = senderNickname == "" ? senderProxyName : senderNickname
        }
    }
}
