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
    
    private var _uid = ""
    private let ref = FIRDatabase.database().reference()
    private var proxiesRef = FIRDatabaseReference()
    private var userProxiesRef = FIRDatabaseReference()
    private var proxyNameGenerator = ProxyNameGenerator()
    private var fetchingProxy = false
    
    private init() {
        proxiesRef = self.ref.child("proxies")
    }
    
    var uid: String {
        get {
            return _uid
        }
        set (newValue) {
            _uid = newValue
            userProxiesRef = self.ref.child("users").child(uid).child("proxies")
        }
    }
    
    func loadWordBank(adjs: [String], nouns: [String]) {
        proxyNameGenerator.adjs = adjs
        proxyNameGenerator.nouns = nouns
        proxyNameGenerator.loaded = true
    }
    
    func wordBankIsLoaded() -> Bool {
        return proxyNameGenerator.loaded
    }
    
    func createProxy() {
        fetchingProxy = true
        tryCreateProxy()
    }
    
    func tryCreateProxy() {
        let key = proxiesRef.childByAutoId().key
        let name = proxyNameGenerator.generateProxyName()
        let timestamp = 0 - NSDate().timeIntervalSince1970
        let proxy = [Constants.ProxyFields.Key: key,
                     Constants.ProxyFields.Owner: uid,
                     Constants.ProxyFields.Name: name,
                     Constants.ProxyFields.Timestamp: timestamp,
                     Constants.ProxyFields.Unread: 0]
        proxiesRef.child(key).setValue(proxy)
        proxiesRef.queryOrderedByChild("name").queryEqualToValue(name).observeSingleEventOfType(.Value, withBlock: { snapshot in
            if snapshot.childrenCount == 1 {
                self.fetchingProxy = false
                self.userProxiesRef.child(key).setValue(proxy)
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.NotificationKeys.ProxyCreated, object: self, userInfo: ["proxy": proxy])
            } else {
                self.deleteProxyWithKey(key)
                if self.fetchingProxy {
                    self.tryCreateProxy()
                }
            }
        })
    }
    
    func saveProxyWithKeyAndNickname(key: String, nickname: String) {
        let timestamp = 0 - NSDate().timeIntervalSince1970
        ref.updateChildValues([
            "/proxies/\(key)/nickname": nickname,
            "/proxies/\(key)/timestamp": timestamp,
            "/users/\(uid)/proxies/\(key)/nickname": nickname,
            "/users/\(uid)/proxies/\(key)/timestamp": timestamp])
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
        fetchingProxy = false
        deleteProxyWithKey(key)
    }
}