//
//  Constants.swift
//  proxy
//
//  Created by Quan Vo on 8/22/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

struct Constants {
    
    struct UserFields {
        static let UID = "uid"
        static let Username = "username"
        static let Proxies = "proxies"
        static let Convos = "convos"
        static let ConvosWith = "convosWith"
        static let Unread = "unread"
    }
    
    struct ProxyFields {
        static let Key = "key"
        static let Owner = "owner"
        static let Name = "name"
        static let Nickname = "nickname"
        static let Message = "message"
        static let Timestamp = "timestamp"
        static let Unread = "unread"
    }
    
    struct ConvoFields {
        static let Key = "key"
        static let Name = "name"
        static let Nickname = "nickname"
        static let Message = "message"
        static let Timestamp = "timestamp"
    }
    
    struct Identifiers {
        static let TabBarController = "Tab Bar Controller"
        static let LogInViewController = "Log In View Controller"
        static let ProxyTableViewCell = "Proxy Table View Cell"
    }
    
    struct Segues {
        static let ProxyDetailSegue = "Proxy Detail Segue"
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