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
    
    var connectionStatusAlerter = ConnectionStatusAlerter()
    
    private var _uid = ""
    private let ref = FIRDatabase.database().reference()
    private var proxiesRef = FIRDatabaseReference()
    private var proxyNameGenerator = ProxyNameGenerator()
    private var wordsLoaded = false
    private var creatingProxy = false
    
    private init() {
        proxiesRef = self.ref.child("proxies")
    }
    
    var uid: String {
        get {
            return _uid
        }
        set (newValue) {
            _uid = newValue
        }
    }
    
    func loadWords() {
        let url = NSURL(string: "https://api.myjson.com/bins/4xqqn")!
        let urlRequest = NSMutableURLRequest(URL: url)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(urlRequest) { data, response, error -> Void in
            guard
                let httpResponse = response as? NSHTTPURLResponse
                where httpResponse.statusCode == 200 else {
                    print(error?.localizedDescription)
                    return
            }
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
                if let adjs = json["adjectives"] as? [String], nouns = json["nouns"] as? [String] {
                    self.proxyNameGenerator.adjs = adjs
                    self.proxyNameGenerator.nouns = nouns
                    self.wordsLoaded = true
                    self.tryCreateProxy()
                    
                }
            } catch let error as NSError {
                print(error.localizedDescription)
            }
        }
        task.resume()
    }
    
    func createProxy() {
        creatingProxy = true
        if wordsLoaded {
            tryCreateProxy()
        } else {
            loadWords()
        }
    }
    
    func tryCreateProxy() {
        let name = proxyNameGenerator.generateProxyName()
        let proxy = Proxy(name: name)
        proxiesRef.child(name).setValue(proxy.toAnyObject())
        proxiesRef.queryOrderedByChild("name").queryEqualToValue(name).observeSingleEventOfType(.Value, withBlock: { snapshot in
            if snapshot.childrenCount == 1 {
                self.creatingProxy = false
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.NotificationKeys.ProxyCreated, object: self, userInfo: ["proxy": proxy.toAnyObject()])
            } else {
                self.deleteProxy(proxy)
                if self.creatingProxy {
                    self.tryCreateProxy()
                }
            }
        })
    }
    
    func saveProxyWithNickname(proxy: Proxy, nickname: String) {
        let timestamp = NSDate().timeIntervalSince1970
        var _proxy = proxy
        _proxy.nickname = nickname
        _proxy.timestamp = timestamp
        ref.updateChildValues([
            "/users/\(uid)/proxies/\(proxy.name)": _proxy.toAnyObject(),
            "/proxies/\(proxy.name)/nickname": nickname,
            "/proxies/\(proxy.name)/timestamp": timestamp])
    }
    
    func updateProxyNickname(proxy: Proxy, nickname: String) {
        ref.updateChildValues([
            "/proxies/\(proxy.name)/nickname": nickname,
            "/users/\(uid)/proxies/\(proxy.name)/nickname": nickname])
    }
    
    func rerollProxy(oldProxy: Proxy) {
        deleteProxy(oldProxy)
        createProxy()
    }
    
    func deleteProxy(proxy: Proxy) {
        proxiesRef.child(proxy.name).removeValue()
    }
    
    func cancelCreateProxy(proxy: Proxy) {
        creatingProxy = false
        deleteProxy(proxy)
    }
}