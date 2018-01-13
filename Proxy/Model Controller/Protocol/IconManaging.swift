import FirebaseDatabase
import MessageKit

protocol IconManaging: class {
    var icons: [String: UIImage] { get }
}

class IconManager: IconManaging {
    private (set) var icons = [String : UIImage]() {
        didSet {
            collectionView?.reloadDataAndKeepOffset()
        }
    }
    private let receiverRef: DatabaseReference?
    private let senderRef: DatabaseReference?
    private var receiverHandle: DatabaseHandle?
    private var senderHandle: DatabaseHandle?
    private weak var collectionView: MessagesCollectionView?

    init(receiverId: String,
         receiverProxyKey: String,
         senderId: String,
         senderProxyKey: String,
         collectionView: MessagesCollectionView?) {
        self.collectionView = collectionView
        icons["blank"] = UIImage.make(color: .white)
        receiverRef = DB.makeReference(Child.proxies, receiverId, receiverProxyKey, Child.icon)
        senderRef = DB.makeReference(Child.proxies, senderId, senderProxyKey, Child.icon)
        receiverHandle = receiverRef?.observe(.value) { [weak self] (data) in
            guard let _self = self else {
                return
            }
            guard let icon = data.value as? String else {
                return
            }
            _self.icons[receiverProxyKey] = UIImage(named: icon)
        }
        senderHandle = senderRef?.observe(.value) { [weak self] (data) in
            guard let _self = self else {
                return
            }
            guard let icon = data.value as? String else {
                return
            }
            _self.icons[senderProxyKey] = UIImage(named: icon)
        }
    }

    deinit {
        if let receiverHandle = receiverHandle {
            receiverRef?.removeObserver(withHandle: receiverHandle)
        }
        if let senderHandle = senderHandle {
            senderRef?.removeObserver(withHandle: senderHandle)
        }
    }
}

// https://stackoverflow.com/questions/26542035/create-uiimage-with-solid-color-in-swift
private extension UIImage {
    static func make(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if let cgImage = image?.cgImage {
            return UIImage(cgImage: cgImage)
        } else {
            return UIImage()
        }
    }
}
