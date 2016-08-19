//
//  KinveyManager.swift
//  proxy
//
//  Created by Quan Vo on 8/15/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import UIKit

class KinveyManager: NSObject {
    
    private var proxyStore: KCSAppdataStore
    private let proxyNameGenerator = ProxyNameGenerator()
    
    override init() {
        proxyStore = KCSAppdataStore.storeWithOptions([
            KCSStoreKeyCollectionName : "Proxies",
            KCSStoreKeyCollectionTemplateClass : Proxy.self
            ])
    }
    
    func getProxies() {
        let query = KCSQuery(onField: "owner", withExactMatchForValue: KCSUser.activeUser().userId)
        let dataSort = KCSQuerySortModifier(field: "lastEventTime", inDirection: KCSSortDirection.Descending)
        query.addSortModifier(dataSort)
        proxyStore.queryWithQuery(
            query,
            withCompletionBlock: { (objectsOrNil: [AnyObject]!, errorOrNil: NSError!) -> Void in
                if errorOrNil == nil {
                    NSNotificationCenter.defaultCenter().postNotificationName("Proxies Fetched", object: self, userInfo: ["proxies": objectsOrNil as! [Proxy]])
                } else {
                    print("Fetch proxies failed: \(errorOrNil)")
                }
            },
            withProgressBlock: nil
        )
    }
    
    func createProxy() {
        var proxy = Proxy()
        proxy.name = proxyNameGenerator.generateProxyName()
        proxyStore.saveObject(
            proxy,
            withCompletionBlock: { (objectsOrNil: [AnyObject]!, errorOrNil: NSError!) -> Void in
                if errorOrNil == nil {
                    proxy = objectsOrNil[0] as! Proxy
                    self.isUniqueProxy(proxy)
                } else {
                    print("Save proxy to Kinvey failed: \(errorOrNil)")
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
                    NSNotificationCenter.defaultCenter().postNotificationName("Proxy Created", object: self, userInfo: ["proxyName": proxy.name])
                } else {
                    self.deleteProxy(proxy)
                    self.createProxy()
                }
            } else {
                print("Check for other proxies with same name failed: \(errorOrNil)")
            }
        })
    }
    
    func deleteProxy(proxy: Proxy) {
        proxyStore.removeObject(
            proxy,
            withDeletionBlock: { (deletionDictOrNil: [NSObject : AnyObject]!, errorOrNil: NSError!) -> Void in
                if errorOrNil == nil {
                    NSNotificationCenter.defaultCenter().postNotificationName("Proxy Deleted", object: self, userInfo: nil)
                } else {
                    print("Delete proxy from Kinvey failed: \(errorOrNil)")
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
                    print("Fetch proxy to delete failed: \(errorOrNil)")
                }
            },
            withProgressBlock: nil
        )
    }
}