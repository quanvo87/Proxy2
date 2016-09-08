//
//  Constants.swift
//  proxy
//
//  Created by Quan Vo on 8/22/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

struct Constants {
    
    struct URLs {
        static let Storage = "gs://proxy-98b45.appspot.com"
    }
    
    struct ChatOptions {
        static let TimestampInterval = 15.0
    }
    
    struct Identifiers {
        static let TabBarController = "Tab Bar Controller"
        static let LogInViewController = "Log In View Controller"
        static let NewMessageViewController = "New Message View Controller"
        static let NewProxyViewController = "New Proxy View Controller"
        static let ProxyInfoTableViewController = "Proxy Info Table View Controller"
        static let ConvoViewController = "Convo View Controller"
        static let ProxyCell = "Proxy Cell"
        static let ProxyNicknameCell = "Proxy Nickname Cell"
        static let ConvoNicknameCell = "Convo Nickname Cell"
        static let BasicCell = "Basic Cell"
    }
    
    struct Segues {
        static let NewMessageSegue = "New Message Segue"
        static let SelectProxySegue = "Select Proxy Segue"
        static let ProxySegue = "Proxy Segue"
        static let ConvoSegue = "Convo Segue"
        static let ConvoDetailSegue = "Convo Detail Segue"
    }
    
    struct SettingsItemNames {
        static let TurnOnNotifications = "Turn On Notifications"
        static let ReportAnIssue = "Report An Issue"
        static let LogOut = "Log Out"
        static let DeleteAccount = "Delete Account"
        static let ReviewInAppStore = "Review In App Store"
        static let About = "About Proxy"
    }
}