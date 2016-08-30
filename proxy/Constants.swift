//
//  Constants.swift
//  proxy
//
//  Created by Quan Vo on 8/22/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

struct Constants {
    
    struct Identifiers {
        static let TabBarController = "Tab Bar Controller"
        static let LogInViewController = "Log In View Controller"
        static let ConvoViewController = "Convo View Controller"
        static let ProxyTableViewCell = "Proxy Table View Cell"
    }
    
    struct Segues {
        static let NewMessageSegue = "New Message Segue"
        static let SelectProxySegue = "Select Proxy Segue"
        static let ProxySegue = "Proxy Segue"
        static let ConvoSeg = "Convo Segue"
    }
    
    struct NotificationKeys {
        static let ProxyCreated = "Proxy Created"
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