//
//  TabBarManager.swift
//  proxy
//
//  Created by Quan Vo on 6/8/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

struct TabBarManager {
    static func setUpTabBarItems(_ items: [UITabBarItem]?) {
        guard let items = items else {
            return
        }
        let size = CGSize(width: 30, height: 30)
        let isAspectRatio = true
        items[0].image = UIImage(named: "messages-tab")?.resize(toNewSize: size, isAspectRatio: isAspectRatio)
        items[1].image = UIImage(named: "proxies-tab")?.resize(toNewSize: size, isAspectRatio: isAspectRatio)
        items[2].image = UIImage(named: "me-tab")?.resize(toNewSize: size, isAspectRatio: isAspectRatio)
    }
}
