//
//  temp.swift
//  proxy
//
//  Created by Quan Vo on 6/11/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

struct temp {
//    /// Uploads compressed version of `image` to storage.
//    /// Returns NSURL to the image in storage.
//    func uploadImage(_ image: UIImage, completion: @escaping (_ url: URL) -> Void) {
//        guard let data = UIImageJPEGRepresentation(image, 0) else { return }
//        storageRef.child(Path.UserFiles).child(uid + String(Date().timeIntervalSince1970)).putData(data, metadata: nil) { (metadata, error) in
//            guard error == nil, let url = metadata?.downloadURL() else { return }
//            completion(url)
//            KingfisherManager.shared.cache.store(image, forKey: url.absoluteString, toDisk: true, completionHandler: nil)
//        }
//    }
//
//    /// Uploads compressed version of video to storage.
//    /// Returns url to the video in storage.
//    func uploadVideo(from url: URL, completion: @escaping (_ url: URL) -> Void) {
//
//        // Compress video.
//        let compressedURL = URL(fileURLWithPath: NSTemporaryDirectory() + UUID().uuidString + ".m4v")
//        compressVideo(fromURL: url, toURL: compressedURL) { (session) in
//            if session.status == .completed {
//
//                // Upload to storage.
//                self.storageRef.child(Path.UserFiles).child(String(Date().timeIntervalSince1970)).putFile(from: compressedURL, metadata: nil) { metadata, error in
//                    guard error == nil, let url = metadata?.downloadURL() else { return }
//                    completion(url)
//                }
//            }
//        }
//    }
//
//    /// Compresses a video. Returns the export session.
//    func compressVideo(fromURL url: URL, toURL outputURL: URL, handler: @escaping (_ session: AVAssetExportSession) -> Void) {
//        let urlAsset = AVURLAsset(url: url, options: nil)
//        if let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPresetMediumQuality) {
//            exportSession.outputFileType = AVFileTypeQuickTimeMovie
//            exportSession.outputURL = outputURL
//            exportSession.shouldOptimizeForNetworkUse = true
//            exportSession.exportAsynchronously { () -> Void in
//                handler(exportSession)
//            }
//        }
//    }
}
