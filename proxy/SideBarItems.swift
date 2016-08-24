//
//  SideBarItems.swift
//  proxy
//
//  Created by Quan Vo on 8/20/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

struct SideBarItems {

    private let _sideBarItems =
        [SideBarItem(title: "Home"),
         SideBarItem(title: "Turn On Notifications"),
         SideBarItem(title: "Report An Issue"),
         SideBarItem(title: "Trash"),
         SideBarItem(title: "Log Out"),
         SideBarItem(title: "Delete Account"),
         SideBarItem(title: "About")]
    
    var sideBarItems: [SideBarItem] {
        return _sideBarItems
    }
}