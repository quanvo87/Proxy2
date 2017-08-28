import AVFoundation
import FirebaseStorage

struct DBStorage {
    typealias GetImageCallback = ((image: UIImage, cellTag: Int)?) -> Void
    typealias UploadFileCallback = (URL?) -> Void

    private static let ref = Storage.storage().reference(forURL: URLs.Storage)

    static func makeReference(_ first: String, _ rest: String...) -> StorageReference? {
        return makeReference(first, rest)
    }

    static func makeReference(_ first: String, _ rest: [String]) -> StorageReference? {
        guard let path = String.makePath(first, rest) else {
            return nil
        }
        return ref.child(path)
    }
}

extension DBStorage {
    static func deleteFile(withKey key: String, completion: @escaping (Success) -> Void) {
        ref.child(Child.UserFiles).child(key).delete { (error) in
            completion(error == nil)
        }
    }

    static func getImageForIcon(_ icon: String, tag: Int, completion: @escaping GetImageCallback) {
        if let image = Shared.shared.cache.object(forKey: icon as AnyObject) as? UIImage {
            completion((image, tag))
            return
        }
        ref.child(Child.Icons).child("\(icon)").downloadURL { (url, _) in
            guard let url = url else {
                completion(nil)
                return
            }
            DispatchQueue.global().async {
                guard
                    let data = try? Data(contentsOf: url),
                    let image = UIImage(data: data) else {
                        completion(nil)
                        return
                }
                Shared.shared.cache.setObject(image, forKey: icon as AnyObject)
                completion((image, tag))
            }
        }
    }

    static func loadProxyInfo(completion: ((Success) -> Void)? = nil) {
        if  !Shared.shared.adjectives.isEmpty &&
            !Shared.shared.nouns.isEmpty &&
            !Shared.shared.iconNames.isEmpty {
            completion?(true)
            return
        }
        let workKey = AsyncWorkGroupKey()
        workKey.loadIconNames()
        workKey.loadProxyNameWords()
        workKey.notify() {
            completion?(workKey.workResult)
            workKey.finishWorkGroup()
        }
    }
    
    static func uploadImage(_ image: UIImage, withKey key: String = UUID().uuidString, completion: @escaping UploadFileCallback) {
        guard let data = UIImageJPEGRepresentation(image, 0) else {
            completion(nil)
            return
        }
        ref.child(Child.UserFiles).child(key).putData(data, metadata: nil) { (metadata, _) in
            guard let url = metadata?.downloadURL() else {
                completion(nil)
                return
            }
            Shared.shared.cache.setObject(image, forKey: url as AnyObject)
            completion(url)
        }
    }

    static func uploadVideo(fromURL url: URL, withKey key: String = UUID().uuidString, completion: @escaping UploadFileCallback) {
        let compressedVideoURL = URL(fileURLWithPath: NSTemporaryDirectory() + UUID().uuidString + ".m4v")
        compressVideo(fromURL: url, toURL: compressedVideoURL) { (session) in
            guard let session = session else {
                completion(nil)
                return
            }
            switch session.status {
            case .completed:
                ref.child(Child.UserFiles).child(key).putFile(from: compressedVideoURL, metadata: nil) { (metadata, _) in
                    // cache?
                    completion(metadata?.downloadURL())
                    return
                }
            case .failed:
                completion(nil)
                return
            default:
                break
            }
        }
    }

    private static func compressVideo(fromURL url: URL, toURL outputURL: URL, completion: @escaping (AVAssetExportSession?) -> Void) {
        let urlAsset = AVURLAsset(url: url)
        guard let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPresetLowQuality) else {
            completion(nil)
            return
        }
        exportSession.outputFileType = AVFileType.mov
        exportSession.outputURL = outputURL
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously {
            completion(exportSession)
        }
    }
}

extension Array where Element: UITableViewCell {
    func incrementTags() {
        _ = self.map { $0.tag += 1 }
    }
}

extension AsyncWorkGroupKey {
    func loadIconNames() {
        guard let ref = DBStorage.makeReference(Child.app, "iconNames.json") else {
            return
        }
        startWork()
        ref.getData(maxSize: 1 * 1024 * 1024) { (data, _) in
            if  let data = data,
                let json = try? JSONSerialization.jsonObject(with: data),
                let dictionary = json as? [String: Any],
                let iconsNames = dictionary["iconNames"] as? [String] {
                Shared.shared.iconNames = iconsNames
            }
            self.finishWork(withResult: !Shared.shared.iconNames.isEmpty)
        }
    }

    func loadProxyNameWords() {
        guard let ref = DBStorage.makeReference(Child.app, "words.json") else {
            return
        }
        startWork()
        ref.getData(maxSize: 1 * 1024 * 1024) { (data, _) in
            if  let data = data,
                let json = try? JSONSerialization.jsonObject(with: data),
                let dictionary = json as? [String: Any],
                let adjectives = dictionary["adjectives"] as? [String],
                let nouns = dictionary["nouns"] as? [String] {
                Shared.shared.adjectives = adjectives
                Shared.shared.nouns = nouns
            }
            self.finishWork(withResult: !Shared.shared.adjectives.isEmpty && !Shared.shared.nouns.isEmpty)
        }
    }
}
