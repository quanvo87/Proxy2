import UIKit

class IconManager: IconManaging {
    var icons = [String: UIImage]() {
        didSet {
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
            }
        }
    }

    private let receiverIconObserver = IconObserver()
    private let senderIconObserver = IconObserver()
    private weak var collectionView: UICollectionView?

    func load(convo: Convo, collectionView: UICollectionView) {
        receiverIconObserver.observe(proxyOwner: convo.receiverId, proxyKey: convo.receiverProxyKey, manager: self)
        senderIconObserver.observe(proxyOwner: convo.senderId, proxyKey: convo.senderProxyKey, manager: self)
        self.collectionView = collectionView
    }
}
