//
//  IconManager.swift
//  proxy
//
//  Created by Quan Vo on 6/6/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import FirebaseStorage

class IconManager {
    static let shared = IconManager()
    fileprivate let ref = Storage.storage().reference(forURL: URLs.Storage + "/icons")
    fileprivate let getIconNamesComplete = DispatchGroup()
    fileprivate var iconNames = [String]()
    fileprivate var iconURLCache = NSCache<NSString, NSURL>()
    fileprivate var iconCache = NSCache<NSString, UIImage>()

    private init() {}

    func getIconNames(completion: @escaping ([String]) -> Void) {
        if !iconNames.isEmpty {
            completion(iconNames)
            return
        }
        getIconNamesComplete.enter()
        ref.child("iconNames.json").getData(maxSize: 1 * 1024 * 1024) { (data, error) in
            defer {
                self.getIconNamesComplete.leave()
            }
            guard
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []),
                let dictionary = json as? [String: Any],
                let iconNames = dictionary["iconNames"] as? [NSString] else {
                    print(error ?? #function)
                    return
            }
            self.iconNames = iconNames as [String]
        }
        getIconNamesComplete.notify(queue: DispatchQueue.main) {
            completion(self.iconNames)
        }
    }

    func setIcon(_ icon: String, forImageView imageView: UIImageView) {
        if let iconImage = iconCache.object(forKey: icon as NSString) {
            imageView.image = iconImage
        }
        getIconURL(forIconName: icon) { (url) in
            DispatchQueue.global().async {
                guard
                    let data = try? Data(contentsOf: url),
                    let image = UIImage(data: data) else {
                        return
                }
                self.iconCache.setObject(image, forKey: icon as NSString)
                DispatchQueue.main.async {
                    imageView.image = image
                }
            }
        }
    }

    private func getIconURL(forIconName icon: String, completion: @escaping (URL) -> Void) {
        if let url = iconURLCache.object(forKey: icon as NSString) as URL? {
            completion(url)
            return
        }
        ref.child("\(icon)").downloadURL { (url, error) in
            guard let url = url else {
                print(error ?? #function)
                return
            }
            self.iconURLCache.setObject(url as NSURL, forKey: icon as NSString)
            completion(url)
        }
    }
}
