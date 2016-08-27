//
//  API.swift
//  proxy
//
//  Created by Quan Vo on 8/15/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase

class API {
    
    static let sharedInstance = API()
    
    private let ref = FIRDatabase.database().reference()
    private var proxyNameGenerator = ProxyNameGenerator()
    private var currentlyFetchingProxy = false
    
    private init() {}
    
    func loadWordBank(adjectives: [String], nouns: [String]) {
        proxyNameGenerator.adjectives = adjectives
        proxyNameGenerator.nouns = nouns
        proxyNameGenerator.wordBankLoaded = true
    }
    
    func wordBankIsLoaded() -> Bool {
        return proxyNameGenerator.wordBankLoaded
    }
    
    func fetchProxy() {
        currentlyFetchingProxy = true
        tryFetchProxy()
    }
    
    func tryFetchProxy() {
        let uid = FIRAuth.auth()?.currentUser?.uid
        let proxiesRef = self.ref.child("proxies")
        let userProxiesRef = self.ref.child("users").child(uid!).child("proxies")
        let key = proxiesRef.childByAutoId().key
        let name = proxyNameGenerator.generateProxyName()
        let date = NSDate()
        let lastEventTime = 0 - date.timeIntervalSince1970
        let lastEvent = "Created at \(date)."
        let proxy = ["key": key,
                     "owner": uid!,
                     "name": name,
                     "lastEventTime": lastEventTime,
                     "lastEvent": lastEvent,
                     "unreadEvents": 0]
        proxiesRef.child(key).setValue(proxy)
        proxiesRef.queryOrderedByChild("name").queryEqualToValue(name).observeSingleEventOfType(.Value, withBlock: { snapshot in
            if snapshot.childrenCount == 1 {
                self.currentlyFetchingProxy = false
                userProxiesRef.child(key).setValue(proxy)
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.NotificationKeys.ProxyCreated, object: self, userInfo: ["proxy": proxy])
            } else {
                self.deleteProxyWithKey(key)
                if self.currentlyFetchingProxy {
                    self.tryFetchProxy()
                }
            }
        })
    }
    
    func updateNicknameForProxyWithKey(key: String, nickname: String) {
        let uid = FIRAuth.auth()?.currentUser?.uid
        ref.updateChildValues([
            "/proxies/\(key)/nickname": nickname,
            "/users/\(uid)/proxies/\(key)/nickname": nickname])
    }
    
    func refreshProxyFromOldProxyWithKey(oldProxyKey: String) {
        deleteProxyWithKey(oldProxyKey)
        fetchProxy()
    }
    
    func deleteProxyWithKey(key: String) {
        let uid = FIRAuth.auth()?.currentUser?.uid
        let proxiesRef = self.ref.child("proxies")
        let userProxiesRef = self.ref.child("users").child(uid!).child("proxies")
        proxiesRef.child(key).removeValue()
        userProxiesRef.child(key).removeValue()
    }
    
    func cancelCreatingProxyWithKey(key: String) {
        currentlyFetchingProxy = false
        deleteProxyWithKey(key)
    }
}