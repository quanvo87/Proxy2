//
//  DBIcon.swift
//  proxy
//
//  Created by Quan Vo on 6/11/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import FirebaseStorage

struct DBIcon {
    static func getImageForIcon(_ icon: AnyObject, tag: Int, completion: @escaping (UIImage?, Int) -> Void) {
        if let image = Shared.shared.cache.object(forKey: icon) as? UIImage {
            completion(image, tag)
            return
        }
        Storage.storage().reference(forURL: URLs.Storage + "/icons").child("\(icon)").downloadURL { (url, error) in
            guard
                error == nil,
                let url = url else {
                    return
            }
            DispatchQueue.global().async {
                guard
                    let data = try? Data(contentsOf: url),
                    let image = UIImage(data: data) else {
                        return
                }
                Shared.shared.cache.setObject(image, forKey: icon)
                DispatchQueue.main.async {
                    completion(image, tag)
                }
            }
        }
    }
}
