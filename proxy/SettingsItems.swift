//
//  SettingsItems.swift
//  proxy
//
//  Created by Quan Vo on 8/20/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

struct SettingsItems {

    private let _settingsItems = 
        [SettingsItem(title: "TurnOnNotifications"),
         SettingsItem(title: "ReportAnIssue"),
         SettingsItem(title: "LogOut"),
         SettingsItem(title: "DeleteAccount"),
         SettingsItem(title: "ReviewInAppStore"),
         SettingsItem(title: "About")]
    
    var settingsItems: [SettingsItem] {
        return _settingsItems
    }
}