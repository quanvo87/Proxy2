//
//  Constants.swift
//  proxy
//
//  Created by Quan Vo on 8/22/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

struct URLs {
    static let Storage = "gs://proxy-98b45.appspot.com"
}

struct Settings {
    static let TimeBetweenTimestamps = 30.0
    static let NewProxyIndicatorDuration = 5.0
}

struct Identifiers {
    static let TabBarController = "Tab Bar Controller"
    static let LogInViewController = "Log In View Controller"
    
    static let NewMessageViewController = "New Message View Controller"
    static let ConvoViewController = "Convo View Controller"
    static let ConvoCell = "Convo Cell"
    
    static let ProxyInfoTableViewController = "Proxy Info Table View Controller"
    static let ProxyCell = "Proxy Cell"
    static let ProxyInfoHeaderCell = "Proxy Info Header Cell"
    static let IconPickerCell = "Icon Picker Cell"
    
    // delete these when ready
    static let NewProxyViewController = "New Proxy View Controller"
    static let ConvoNicknameCell = "Convo Nickname Cell"
    static let BasicCell = "Basic Cell"
}

struct Segues {
    static let NewMessageSegue = "New Message Segue"
    static let SelectProxySegue = "Select Proxy Segue"
    static let ProxyInfoSegue = "Proxy Info Segue"
    static let IconPickerSegue = "Icon Picker Segue"
    static let ConvoSegue = "Convo Segue"
    static let ConvoDetailSegue = "Convo Detail Segue"
}

struct Notifications {
    static let CreateNewProxyFromHomeTab = "Create New Proxy From Home Tab"
}