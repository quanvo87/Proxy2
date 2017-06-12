//
//  Proxy.swift
//  proxy
//
//  Created by Quan Vo on 8/28/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

struct Proxy {
    var key = ""
    var name = ""
    var ownerId = ""
    var icon = ""
    var nickname = ""
    var message = ""
    var created = NSDate().timeIntervalSince1970
    var timestamp = NSDate().timeIntervalSince1970
    var convos = 0
    var unread = 0

    init() {}

    init(name: String, ownerId: String) {
        self.key = name.lowercased()
        self.name = name
        self.ownerId = ownerId
    }

    init(name: String, ownerId: String, icon: String) {
        self.key = name.lowercased()
        self.name = name
        self.ownerId = ownerId
        self.icon = icon
    }

    init?(_ json: AnyObject) {
        guard
            let key = json["key"] as? String,
            let name = json["name"] as? String,
            let ownerId = json["ownerId"] as? String,
            let icon = json["icon"] as? String,
            let nickname = json["nickname"] as? String,
            let message = json["message"] as? String,
            let created = json["created"] as? Double,
            let timestamp = json["timestamp"] as? Double,
            let convos = json["convos"] as? Int,
            let unread = json["unread"] as? Int else {
                return nil
        }
        self.key = key
        self.name = name
        self.ownerId = ownerId
        self.icon = icon
        self.nickname = nickname
        self.message = message
        self.created = created
        self.timestamp = timestamp
        self.convos = convos
        self.unread = unread
    }

    func toJSON() -> Any {
        return [
            "key": key,
            "name": name,
            "ownerId": ownerId,
            "icon": icon,
            "nickname": nickname,
            "message": message,
            "created": created,
            "timestamp": timestamp,
            "convos": convos,
            "unread": unread
        ]
    }
}
