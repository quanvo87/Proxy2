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
        let fetchRequest = NSFetchRequest(entityName: "Proxy")
        let sortDescriptor = NSSortDescriptor(key: "lastEventTime", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        do {
            let result = try ProxyAPI.sharedInstance.context.executeFetchRequest(fetchRequest)
            proxies = result as! [Proxy]
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
        return proxies
    }
    
    func saveContext() {
        do {
            try ProxyAPI.sharedInstance.context.save()
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
    }
    
    func deleteProxy(proxy: Proxy) {
        ProxyAPI.sharedInstance.context.deleteObject(proxy as NSManagedObject)
        saveContext()
    }
}