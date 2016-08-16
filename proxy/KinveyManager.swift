//
//  KinveyManager.swift
//  proxy
//
//  Created by Quan Vo on 8/15/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import UIKit
import CoreData

class KinveyManager: NSObject {
    
    private var store: KCSAppdataStore
    
    override init() {
        store = KCSAppdataStore.storeWithOptions([
            KCSStoreKeyCollectionName : "Proxies",
            KCSStoreKeyCollectionTemplateClass : Proxy.self
            ])
    }
    
    func createProxy(name: String, nickname: String) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        let entity =  NSEntityDescription.entityForName("Proxy", inManagedObjectContext: context)
        let proxy = Proxy(entity: entity!, insertIntoManagedObjectContext: context)
        proxy.owner = KCSUser.activeUser().userId
        proxy.name = name
        proxy.nickname = nickname
        proxy.lastEventTime = NSDate()
        store.saveObject(
            proxy,
            withCompletionBlock: { (objectsOrNil: [AnyObject]!, errorOrNil: NSError!) -> Void in
                if errorOrNil == nil {
                    proxy.id = (objectsOrNil[0] as! NSObject).kinveyObjectId()
                    do {
                        try context.save()
                        NSNotificationCenter.defaultCenter().postNotificationName("ProxiesUpdated", object: self, userInfo: nil)
                    } catch let error as NSError  {
                        print("Could not save \(error), \(error.userInfo)")
                    }
                } else {
                    print("Save failed, with error: %@", errorOrNil.localizedFailureReason)
                }
            },
            withProgressBlock: nil
        )
    }
}