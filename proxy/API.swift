//
//  API.swift
//  proxy
//
//  Created by Quan Vo on 8/15/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase

class API {
    
    static let sharedInstance = API()
    
    private let ref = FIRDatabase.database().reference()
    private var proxiesRef = FIRDatabaseReference()
    private var proxyNameGenerator = ProxyNameGenerator()
    private var _currentlyCreatingProxy = false
    
    private init() {
        proxiesRef = ref.child("proxies")
    }
    
    func loadWordBank(adjectives: [String], nouns: [String]) {
        proxyNameGenerator.adjectives = adjectives
        proxyNameGenerator.nouns = nouns
        proxyNameGenerator.wordBankLoaded = true
    }
    
    func wordBankIsLoaded() -> Bool {
        return proxyNameGenerator.wordBankLoaded
    }
    
    var currentlyCreatingProxy: Bool {
        get {
            return _currentlyCreatingProxy
        }
        set (newValue) {
            _currentlyCreatingProxy = newValue
        }
    }
    
    func createProxy() {
        let key = proxiesRef.childByAutoId().key
        let proxy = Proxy(key: key, name: proxyNameGenerator.generateProxyName())
        proxiesRef.child(key).setValue(proxy.toAnyObject())
        proxiesRef.queryOrderedByChild("name").queryEqualToValue(proxy.name).observeSingleEventOfType(.Value, withBlock: { snapshot in
            if snapshot.childrenCount == 1 {
                self._currentlyCreatingProxy = false
                // save to user proxies
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.NotificationKeys.ProxyCreated, object: self, userInfo: ["proxy": proxy.toAnyObject()])
            } else {
                self.deleteProxy(proxy)
                if self._currentlyCreatingProxy {
                    self.createProxy()
                }
            }
        })
    }
    
    func updateProxyNickname(proxy: Proxy, nickname: String) {
        
    }
    
    func deleteProxy(proxy: Proxy) {
        
    }
}