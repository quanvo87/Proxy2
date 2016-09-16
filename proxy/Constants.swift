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
    
    static let ConvoViewController = "Convo View Controller"
    static let ConvoInfoTableViewController = "Convo Info Table View Controller"
    static let ConvoCell = "Convo Cell"
    
    static let ProxyInfoTableViewController = "Proxy Info Table View Controller"
    static let ProxyCell = "Proxy Cell"
    static let SenderProxyInfoCell = "Sender Proxy Info Cell"
    static let ReceiverProxyInfoCell = "Receiver Proxy Info Cell"
    
    static let IconPickerCollectionViewController = "Icon Picker Collection View Controller"
    static let IconPickerCell = "Icon Picker Cell"
    
    static let NewMessageViewController = "New Message View Controller"
    static let SelectProxyViewController = "Select Proxy View Controller"
    
    static let BasicCell = "Basic Cell"
}

struct Notifications {
    static let CreatedNewProxyFromHomeTab = "Created New Proxy From Home Tab"
}
