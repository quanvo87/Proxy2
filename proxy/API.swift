//
//  API.swift
//  proxy
//
//  Created by Quan Vo on 8/15/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

class API {
    
    static let sharedInstance = API()
    private init() {}
    
    var userDisplayName: String?
    var userLoggedIn = false
    
//    class var sharedInstance: API {
//        struct Singleton {
//            static let instance = API()
//        }
//        return Singleton.instance
//    }
    
    func getUsername() -> String {
        return ""
    }
    
    func getProxies() {
        
    }
    
    func createProxy() {
        
    }
    
    func refreshProxyFromOldProxyWithName(oldProxyName: String) {
        
    }
    
    func updateProxyNickname(name: String, nickname: String) {
        
    }
    
    func deleteProxyWithName(name: String) {
        
    }
}