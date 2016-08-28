//
//  SettingsItems.swift
//  proxy
//
//  Created by Quan Vo on 8/20/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

struct SettingsItems {

    private let _settingsItems = 
        [SettingsItem(title: Constants.SettingsItemNames.TurnOnNotifications),
         SettingsItem(title: Constants.SettingsItemNames.ReportAnIssue),
         SettingsItem(title: Constants.SettingsItemNames.LogOut),
         SettingsItem(title: Constants.SettingsItemNames.DeleteAccount),
         SettingsItem(title: Constants.SettingsItemNames.ReviewInAppStore),
         SettingsItem(title: Constants.SettingsItemNames.About)]
    
    var settingsItems: [SettingsItem] {
        return _settingsItems
    }
}