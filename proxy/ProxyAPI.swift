//
//  ProxyAPI.swift
//  proxy
//
//  Created by Quan Vo on 8/15/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import UIKit

class ProxyAPI: NSObject {
    
    private let kinveyManager = KinveyManager()
    
    class var sharedInstance: ProxyAPI {
        struct Singleton {
            static let instance = ProxyAPI()
        }
        return Singleton.instance
    }
    
    func getUsername() -> String {
        return kinveyManager.getUsername()
    }
    
    func getProxies() {
        kinveyManager.getProxies()
    }
    
    func createProxy() {
        kinveyManager.createProxy()
    }
    
    func deleteProxyWithName(name: String) {
        kinveyManager.doActionOnProxyWithName(name, action: KinveyAction.Delete, extra: "")
    }
    
    func updateProxyNickname(name: String, nickname: String) {
        kinveyManager.doActionOnProxyWithName(name, action: KinveyAction.Update, extra: nickname)
    }
}