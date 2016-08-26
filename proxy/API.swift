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
    
    private var _uid = ""
    private let ref = FIRDatabase.database().reference()
    private var proxiesRef = FIRDatabaseReference()
    private var userProxiesRef = FIRDatabaseReference()
    private var proxyNameGenerator = ProxyNameGenerator()
    private var currentlyCreatingProxy = false
    
    private init() {
        self.proxiesRef = self.ref.child("proxies")
    }
    
    var uid: String {
        get {
            return _uid
        }
        set (newValue) {
            _uid = newValue
            self.userProxiesRef = self.ref.child("users").child(self.uid).child("proxies")
        }
    }
    
    func loadWordBank(adjectives: [String], nouns: [String]) {
        proxyNameGenerator.adjectives = adjectives
        proxyNameGenerator.nouns = nouns
        proxyNameGenerator.wordBankLoaded = true
    }
    
    func wordBankIsLoaded() -> Bool {
        return proxyNameGenerator.wordBankLoaded
    }
    
    func createProxy() {
        currentlyCreatingProxy = true
        tryCreateProxy()
    }
    
    func tryCreateProxy() {
        let key = proxiesRef.childByAutoId().key
        let name = proxyNameGenerator.generateProxyName()
        let date = NSDate()
        let proxy = ["key": key,
                     "owner": uid,
                     "name": name,
                     "nickname": "",
                     "lastEventTime": 0 - date.timeIntervalSince1970,
                     "lastEvent": "Created at \(date).",
                     "unreadEvents": 0]
        
        proxiesRef.child(key).setValue(proxy)
        proxiesRef.queryOrderedByChild("name").queryEqualToValue(name).observeSingleEventOfType(.Value, withBlock: { snapshot in
            if snapshot.childrenCount == 1 {
                self.currentlyCreatingProxy = false
                self.userProxiesRef.child(key).setValue(proxy)
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.NotificationKeys.ProxyCreated, object: self, userInfo: ["proxy": proxy])
            } else {
                self.deleteProxyWithKey(key)
                if self.currentlyCreatingProxy {
                    self.tryCreateProxy()
                }
            }
        })
    }
    
    func updateNicknameForProxyWithKey(key: String, nickname: String) {
        ref.updateChildValues([
            "/proxies/\(key)/nickname": nickname,
            "/users/\(uid)/proxies/\(key)/nickname": nickname])
    }
    
    func refreshProxyFromOldProxyWithKey(oldProxyKey: String) {
        deleteProxyWithKey(oldProxyKey)
        createProxy()
    }
    
    func deleteProxyWithKey(key: String) {
        proxiesRef.child(key).removeValue()
        userProxiesRef.child(key).removeValue()
    }
    
    func cancelCreatingProxyWithKey(key: String) {
        currentlyCreatingProxy = false
        deleteProxyWithKey(key)
    }
}