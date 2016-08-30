//
//  ConnectionStatusAlerter.swift
//  proxy
//
//  Created by Quan Vo on 8/29/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase

struct ConnectionStatusAlerter {

    init() {
        let connectedRef = FIRDatabase.database().referenceWithPath(".info/connected")
        connectedRef.observeEventType(.Value, withBlock: { snapshot in
            let timestamp = NSDateFormatter.localizedStringFromDate(NSDate(), dateStyle: .MediumStyle, timeStyle: .ShortStyle)
            var msg = ""
            if let connected = snapshot.value as? Bool where connected {
                msg = "Connected " + timestamp
            } else {
                msg = "Not connected " + timestamp
            }
            
            print(msg)
        })
    }
}