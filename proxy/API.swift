//
//  API.swift
//  proxy
//
//  Created by Quan Vo on 8/15/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseAuth

class API {
    
    static let sharedInstance = API()
    private init() {}
    
//    private var userDisplayName: String?
////    private var userLoggedIn = false
//    
//    func setUserInfo(user: FIRUser) {
//        //        MeasurementHelper.sendLoginEvent()
//        //        NSNotificationCenter.defaultCenter().postNotificationName(Constants.NotificationKeys.UserLoggedIn, object: nil, userInfo: nil)
//        userDisplayName = user.displayName ?? user.email
////        userLoggedIn = true
//    }
//    
//    func clearUserInfo() {
//        userDisplayName = ""
////        userLoggedIn = false
//    }
//    
//    func getUserDisplayName() -> String {
//        return userDisplayName!
//    }
//
//    func getProxies() {
//        
//    }
    
    func createProxy() {
        
    }
    
    func refreshProxyFromOldProxyWithName(oldProxyName: String) {
        
    }
    
    func updateProxyNickname(name: String, nickname: String) {
        
    }
    
    func deleteProxyWithName(name: String) {
        
    }
}