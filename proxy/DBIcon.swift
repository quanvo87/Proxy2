//
//  DBIcon.swift
//  proxy
//
//  Created by Quan Vo on 6/11/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import FirebaseStorage

struct DBIcon {
    static func getIconNames(completion: @escaping ([NSString]?, Error?) -> Void) {
        if let names = DataManager.shared.cache.object(forKey: NSString(string: "iconNames")) as? [NSString] {
            completion(names, nil)
            return
        }
        Storage.storage().reference(forURL: URLs.Storage + "/icons").child("iconNames.json").getData(maxSize: 1 * 1024 * 1024) { (data, error) in
            guard
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []),
                let dictionary = json as? [String: Any],
                let names = dictionary["iconNames"] as? [NSString] else {
                    completion(nil, error)  // TODO: - better error?
                    return
            }
            DataManager.shared.cache.setObject(names as AnyObject, forKey: NSString(string: "iconNames"))
            completion(names, nil)
        }
    }

    static func getImageForIcon(_ icon: NSString, tag: Int, completion: @escaping (UIImage?, Int, Error?) -> Void) {
        if let image = DataManager.shared.cache.object(forKey: icon) as? UIImage {
            completion(image, tag, nil)
            return
        }
        Storage.storage().reference(forURL: URLs.Storage + "/icons").child("\(icon)").downloadURL { (url, error) in
            guard let url = url else {
                completion(nil, tag, error)
                return
            }
            DispatchQueue.global().async {
                guard
                    let data = try? Data(contentsOf: url),
                    let image = UIImage(data: data) else {
                        // TODO: - return error
                        return
                }
                DataManager.shared.cache.setObject(image, forKey: icon)
                DispatchQueue.main.async {
                    completion(image, tag, nil)
                }
            }
        }
    }
}
