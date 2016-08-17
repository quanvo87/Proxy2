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
    
    private var proxyStore: KCSAppdataStore
    private let proxyNameGenerator: ProxyNameGenerator
    
    override init() {
        proxyStore = KCSAppdataStore.storeWithOptions([
            KCSStoreKeyCollectionName : "Proxies",
            KCSStoreKeyCollectionTemplateClass : Proxy.self
            ])
        proxyNameGenerator = ProxyNameGenerator()
    }
    
    func createProxy() {
        let entity =  NSEntityDescription.entityForName("Proxy", inManagedObjectContext: ProxyAPI.sharedInstance.context)
        let proxy = Proxy(entity: entity!, insertIntoManagedObjectContext: ProxyAPI.sharedInstance.context)
        proxy.owner = KCSUser.activeUser().userId
        proxy.name = proxyNameGenerator.generateProxyName()
        proxy.lastEventTime = NSDate()
        proxyStore.saveObject(
            proxy,
            withCompletionBlock: { (objectsOrNil: [AnyObject]!, errorOrNil: NSError!) -> Void in
                if errorOrNil == nil {
                    proxy.id = (objectsOrNil[0] as! NSObject).kinveyObjectId()
                    ProxyAPI.sharedInstance.saveLocal()
                    self.isUniqueProxy(proxy)
                } else {
                    print("Save failed, with error: %@", errorOrNil.localizedFailureReason)
                    ProxyAPI.sharedInstance.deleteProxyLocal(proxy)
                }
            },
            withProgressBlock: nil
        )
    }
    
    func isUniqueProxy(proxy: Proxy) {
        let query = KCSQuery(onField: "name", withExactMatchForValue: proxy.name)
        proxyStore.countWithQuery(query, completion: { (count: UInt, errorOrNil: NSError!) -> Void in
            if errorOrNil == nil {
                if count == 1 {
                    NSNotificationCenter.defaultCenter().postNotificationName("Proxy Created", object: self, userInfo: ["proxy": proxy])
                } else {
                    self.deleteProxy(proxy)
                    self.createProxy()
                }
            } else {
                print("Error fetching proxy just created: %@", errorOrNil.localizedFailureReason)
            }
        })
    }
    
    func deleteProxy(proxy: Proxy) {
        proxyStore.removeObject(
            proxy,
            withDeletionBlock: { (deletionDictOrNil: [NSObject : AnyObject]!, errorOrNil: NSError!) -> Void in
                if errorOrNil == nil {
                    NSLog("deleted response: %@", deletionDictOrNil)
                    ProxyAPI.sharedInstance.deleteProxyLocal(proxy)
                } else {
                    print("Delete failed, with error: %@", errorOrNil.localizedFailureReason)
                }
            },
            withProgressBlock: nil
        )
    }
    
    func deleteProxyWithName(name: String) {
        let query = KCSQuery(onField: "name", withExactMatchForValue: name)
        proxyStore.queryWithQuery(
            query,
            withCompletionBlock: { (objectsOrNil: [AnyObject]!, errorOrNil: NSError!) -> Void in
                if errorOrNil == nil {
                    self.deleteProxy(objectsOrNil[0] as! Proxy)
                } else {
                    print("Error fetching proxy: %@", errorOrNil.localizedFailureReason)
                }
            },
            withProgressBlock: nil
        )
    }
}