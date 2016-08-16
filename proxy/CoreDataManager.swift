//
//  CoreDataManager.swift
//  proxy
//
//  Created by Quan Vo on 8/15/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import UIKit
import CoreData

class CoreDataManager: NSObject {
    
    func getProxies() -> [Proxy] {
        var proxies = [Proxy]()
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "Proxy")
        let sortDescriptor = NSSortDescriptor(key: "lastEventTime", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        do {
            let result = try context.executeFetchRequest(fetchRequest)
            proxies = result as! [Proxy]
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
        return proxies
    }
}