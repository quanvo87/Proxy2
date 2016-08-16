//
//  Proxy+CoreDataProperties.swift
//  proxy
//
//  Created by Quan Vo on 8/15/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Proxy {

    @NSManaged var id: String?
    @NSManaged var owner: String?
    @NSManaged var name: String?
    @NSManaged var nickname: String?
    @NSManaged var lastEventMessage: String?
    @NSManaged var lastEventTime: NSDate?
    @NSManaged var conversationsWith: String?
    @NSManaged var invites: String?
}