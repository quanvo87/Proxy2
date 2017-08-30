import AVFoundation
import FirebaseStorage

struct DBStorage {
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
                    // TODO: Cache
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
