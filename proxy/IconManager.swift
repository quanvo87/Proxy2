//
//  IconManager.swift
//  proxy
//
//  Created by Quan Vo on 6/6/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import Firebase

class IconManager {
    static let singleton = IconManager()

    fileprivate let ref = Storage.storage().reference(forURL: URLs.Storage + "/icons")

    fileprivate let getIconNamesComplete = DispatchGroup()

    fileprivate var iconNames = [NSString]()
    fileprivate var iconURLCache = NSCache<NSString, NSURL>()
    fileprivate var iconCache = NSCache<NSString, UIImage>()

    private init() {
        getIconNames()
    }

    func getIconNames(completion: @escaping ([NSString]) -> Void) {
        getIconNamesComplete.notify(queue: DispatchQueue.main) {
            completion(self.iconNames)
        }
    }

    func getUIImage(forIconName icon: NSString, completion: @escaping (UIImage?) -> Void) {
        if let image = iconCache.object(forKey: icon) {
            completion(image)
            return
        }
        getIconURL(forIconName: icon) { (url) in
            DispatchQueue.global().async {
                guard
                    let data = try? Data(contentsOf: url),
                    let image = UIImage(data: data) else {
                        completion(nil)
                        return
                }
                completion(image)
                self.iconCache.setObject(image, forKey: icon)
            }
        }
    }
}

private extension IconManager {
    func getIconNames() {
        getIconNamesComplete.enter()
        ref.child("iconNames.json").getData(maxSize: 1 * 1024 * 1024) { (data, error) in
            guard
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []),
                let dictionary = json as? [String: Any],
                let iconNames = dictionary["iconNames"] as? [NSString] else {
                    print(error ?? "Error getting icons names.")
                    return
            }
            self.iconNames = iconNames
            self.getIconNamesComplete.leave()
        }
    }

    func getIconURL(forIconName icon: NSString, completion: @escaping (URL) -> Void) {
        if let url = iconURLCache.object(forKey: icon) as URL? {
            completion(url)
            return
        }
        ref.child("\(icon)").downloadURL { (url, error) in
            guard let url = url else {
                print(error ?? "")
                return
            }
            completion(url)
            self.iconURLCache.setObject(url as NSURL, forKey: icon)
        }
    }
}
