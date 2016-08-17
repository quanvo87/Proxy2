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
//    private let context: NSManagedObjectContext
    private let proxyNameGenerator: ProxyNameGenerator
    
    override init() {
        proxyStore = KCSAppdataStore.storeWithOptions([
            KCSStoreKeyCollectionName : "Proxies",
            KCSStoreKeyCollectionTemplateClass : Proxy.self
            ])
//        context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        proxyNameGenerator = ProxyNameGenerator()
    }
    
    func getProxy() {
        let entity =  NSEntityDescription.entityForName("Proxy", inManagedObjectContext: ProxyAPI.sharedInstance.context)
        let proxy = Proxy(entity: entity!, insertIntoManagedObjectContext: ProxyAPI.sharedInstance.context)
        var tryProxy = (Proxy(), Bool())
        repeat {
            tryProxy = createProxy(proxyNameGenerator.generateProxyName())
        } while (!tryProxy.1 || !isUniqueProxy(tryProxy.0))
        NSNotificationCenter.defaultCenter().postNotificationName("Proxy Created", object: self, userInfo: ["proxy": tryProxy.0])
    }
    
    func isUniqueProxy(proxy: Proxy) -> Bool {
        var result = true
        let query = KCSQuery(onField: "name", withExactMatchForValue: proxy.name)
        proxyStore.countWithQuery(query, completion: { (count: UInt, errorOrNil: NSError!) -> Void in
            if count > 1 {
                result = false
                self.deleteProxy(proxy)
            }
        })
        return result
    }
    
    func deleteProxy(proxy: Proxy) {
        proxyStore.removeObject(
            proxy,
            withDeletionBlock: { (deletionDictOrNil: [NSObject : AnyObject]!, errorOrNil: NSError!) -> Void in
                if errorOrNil != nil {
                    print("Delete failed, with error: %@", errorOrNil.localizedFailureReason)
                } else {
                    NSLog("deleted response: %@", deletionDictOrNil)
                    ProxyAPI.sharedInstance.deleteProxyLocal(proxy)
                }
            },
            withProgressBlock: nil
        )
    }
    
    func isUniqueProxyName(name: String) -> Bool {
        var result = false
        let query = KCSQuery(onField: "name", withExactMatchForValue: name)
        proxyStore.countWithQuery(query, completion: { (count: UInt, errorOrNil: NSError!) -> Void in
            if count == 0 {
                result = true
            }
        })
        return result
    }
    
    func createProxy(name: String) -> (Proxy, Bool) {
        var success = false
        let entity =  NSEntityDescription.entityForName("Proxy", inManagedObjectContext: ProxyAPI.sharedInstance.context)
        let proxy = Proxy(entity: entity!, insertIntoManagedObjectContext: ProxyAPI.sharedInstance.context)
        proxy.owner = KCSUser.activeUser().userId
        proxy.name = name
        proxy.lastEventTime = NSDate()
        proxyStore.saveObject(
            proxy,
            withCompletionBlock: { (objectsOrNil: [AnyObject]!, errorOrNil: NSError!) -> Void in
                if errorOrNil == nil {
                    proxy.id = (objectsOrNil[0] as! NSObject).kinveyObjectId()
                    success = true
                    ProxyAPI.sharedInstance.saveLocal()
                } else {
                    print("Save failed, with error: %@", errorOrNil.localizedFailureReason)
                    ProxyAPI.sharedInstance.deleteProxyLocal(proxy)
                }
            },
            withProgressBlock: nil
        )
        return (proxy, success)
    }
}