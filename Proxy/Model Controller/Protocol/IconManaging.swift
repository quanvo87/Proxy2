import UIKit

protocol IconManaging: class {
    var icons: [String: UIImage] { get set }
}

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

    init() {
        UIImage.make(color: .white) { (image) in
            self.icons["blank"] = image
        }
    }

    func load(convo: Convo, collectionView: UICollectionView) {
        self.collectionView = collectionView
        receiverIconObserver.observe(proxyOwner: convo.receiverId, proxyKey: convo.receiverProxyKey, manager: self)
        senderIconObserver.observe(proxyOwner: convo.senderId, proxyKey: convo.senderProxyKey, manager: self)
    }
}

// modified from https://stackoverflow.com/questions/26542035/create-uiimage-with-solid-color-in-swift
private extension UIImage {
    static func make(color: UIColor, size: CGSize = CGSize(width: 1, height: 1), completion: @escaping (UIImage) -> Void) {
        DispatchQueue.main.async {
            let rect = CGRect(origin: .zero, size: size)
            UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
            color.setFill()
            UIRectFill(rect)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            if let cgImage = image?.cgImage {
                completion(UIImage(cgImage: cgImage))
            }
        }
    }
}
