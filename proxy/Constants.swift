//
//  Constants.swift
//  proxy
//
//  Created by Quan Vo on 8/22/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

struct Path {
    // Objects
    static let Proxies = "proxies"
    static let Convos = "convos"
    static let Messages = "messages"
    static let WordBank = "wordbank"
    static let Icons = "icons"
    static let UserFiles = "userFiles"
    
    // User
    static let ProxiesInteractedWith = "proxiesInteractedWith"
    static let MessagesSent = "messagesSent"
    static let MessagesReceived = "messagesReceived"
    static let Blocked = "blocked"
    static let Present = "present"
    static let Typing = "typing"
    
    // Proxy
    static let Deleted = "deleted"
    
    // Convo
    static let SenderNickname = "senderNickname"
    static let SenderLeftConvo = "senderLeftConvo"
    static let SenderDeletedProxy = "senderDeletedProxy"
    static let SenderIsBlocking = "senderIsBlocking"
    static let ReceiverNickname = "receiverNickname"
    static let ReceiverLeftConvo = "receiverLeftConvo"
    static let ReceiverDeletedProxy = "receiverDeletedProxy"
    static let ReceiverIsBlocking = "receiverIsBlocking"
    
    // Message
    static let Read = "read"
    static let TimeRead = "timeRead"
    static let MediaType = "mediaType"
    static let MediaURL = "mediaURL"
    
    // Shared
    static let Key = "key"
    static let Name = "name"
    static let Nickname = "nickname"
    static let Icon = "icon"
    static let Message = "message"
    static let Timestamp = "timestamp"
    static let Unread = "unread"
}

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
    
    static let ProxyInfoTableViewController = "Proxy Info Table View Controller"
    static let ProxyCell = "Proxy Cell"
    static let SenderProxyInfoCell = "Sender Proxy Info Cell"
    static let ReceiverProxyInfoCell = "Receiver Proxy Info Cell"
    
    static let IconPickerCollectionViewController = "Icon Picker Collection View Controller"
    static let IconPickerCell = "Icon Picker Cell"
    
    static let NewMessageViewController = "New Message View Controller"
    static let SelectSenderTableViewController = "Select Sender Table View Controller"
    static let SelectReceiverViewController = "Select Receiver View Controller"
    
    static let ConvoViewController = "Convo View Controller"
    static let ConvoInfoTableViewController = "Convo Info Table View Controller"
    static let ConvoCell = "Convo Cell"
    
    static let MeTableViewCell = "Me Table View Cell"
    
    static let Cell = "Cell"
}

struct Notifications {
    static let CreatedNewProxyFromHomeTab = "Created New Proxy From Home Tab"
}
