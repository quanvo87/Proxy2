//
//  SideBarItems.swift
//  proxy
//
//  Created by Quan Vo on 8/20/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

struct SideBarItems {

    private let _sideBarItems =
        [SideBarItem(title: Constants.SideBarItemNames.Home),
         SideBarItem(title: Constants.SideBarItemNames.TurnOnNotifications),
         SideBarItem(title: Constants.SideBarItemNames.ReportAnIssue),
         SideBarItem(title: Constants.SideBarItemNames.Trash),
         SideBarItem(title: Constants.SideBarItemNames.LogOut),
         SideBarItem(title: Constants.SideBarItemNames.DeleteAccount),
         SideBarItem(title: Constants.SideBarItemNames.About)]
    
    var sideBarItems: [SideBarItem] {
        return _sideBarItems
    }
}