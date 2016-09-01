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
        set {
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
                if let adjs = json["adjectives"] as?[String], nouns = json["nouns"] as? [String] {
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
    
    func sendMessage(_convo: Convo, messageText: String, completion: (success: Bool) -> Void) {
        
        var convo = _convo
        
        let timestamp = NSDate().timeIntervalSince1970
        
        let messageKey = self.ref.child("messages").child(convo.key).childByAutoId().key
        let message = Message(key: messageKey, sender: uid, message: messageText, timestamp: timestamp).toAnyObject()
        
        convo.message = messageText
        convo.timestamp = timestamp
        let convoDict = convo.toAnyObject()
        
        let update = [
            "/messages/\(convo.key)/\(messageKey)": message,
            "/users/\(uid)/convos/\(convo.key)": convoDict,
            "/convos/\(convo.senderProxy)/\(convo.key)": convoDict]
        
        self.ref.updateChildValues(update, withCompletionBlock: { (error, ref) in
            
            // Sender proxy
            self.ref.child("users").child(self.uid).child("proxies").child(convo.senderProxy).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
                if var proxy = currentData.value as? [String: AnyObject] {
                    proxy["message"] = messageText
                    proxy["timestamp"] = timestamp
                    currentData.value = proxy
                    return FIRTransactionResult.successWithValue(currentData)
                }
                return FIRTransactionResult.successWithValue(currentData)
            })
            
            // Receiver global unread
            self.ref.child("users").child(convo.receiverId).child("unread").runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
                if let unread = currentData.value {
                    let _unread = unread as? Int ?? 0
                    currentData.value = _unread + 1
                    return FIRTransactionResult.successWithValue(currentData)
                }
                return FIRTransactionResult.successWithValue(currentData)
            })
            
            // Receiver convo unread
            self.ref.child("users").child(convo.receiverId).child("convos").child(convo.key).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
                if var convo = currentData.value as? [String: AnyObject] {
                    let unread = convo["unread"] as? Int ?? 0
                    convo["unread"] = unread + 1
                    convo["message"] = messageText
                    convo["timestamp"] = timestamp
                    currentData.value = convo
                    return FIRTransactionResult.successWithValue(currentData)
                }
                return FIRTransactionResult.successWithValue(currentData)
            })
            
            // Receiver convo by proxy unread
            self.ref.child("convos").child(convo.receiverProxy).child(convo.key).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
                if var convo = currentData.value as? [String: AnyObject] {
                    let unread = convo["unread"] as? Int ?? 0
                    convo["unread"] = unread + 1
                    convo["message"] = messageText
                    convo["timestamp"] = timestamp
                    currentData.value = convo
                    return FIRTransactionResult.successWithValue(currentData)
                }
                return FIRTransactionResult.successWithValue(currentData)
            })
            
            // Receiver proxy unread
            self.ref.child("users").child(convo.receiverId).child("proxies").child(convo.receiverProxy).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
                if var proxy = currentData.value as? [String: AnyObject] {
                    let unread = proxy["unread"] as? Int ?? 0
                    proxy["unread"] = unread + 1
                    proxy["message"] = messageText
                    proxy["timestamp"] = timestamp
                    currentData.value = proxy
                    return FIRTransactionResult.successWithValue(currentData)
                }
                return FIRTransactionResult.successWithValue(currentData)
            })
        })
        
        completion(success: true)
    }
    
    func decreaseUnreadForUserBy(amt: Int, user: String, convo: String, proxy: String) {
        // User global unread
        self.ref.child("users").child(user).child("unread").runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if let unread = currentData.value {
                let _unread = unread as? Int ?? 0
                if _unread != 0 {
                    currentData.value = _unread - amt
                }
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        })
        
        // Convo unread
        self.ref.child("users").child(user).child("convos").child(convo).child("unread").runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if let unread = currentData.value {
                let _unread = unread as? Int ?? 0
                if _unread != 0 {
                    currentData.value = _unread - amt
                }
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        })
        
        // Convo by proxy unread
        self.ref.child("convos").child(proxy).child(convo).child("unread").runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if let unread = currentData.value {
                let _unread = unread as? Int ?? 0
                if _unread != 0 {
                    currentData.value = _unread - amt
                }
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        })
        
        // Proxy unread
        self.ref.child("users").child(user).child("proxies").child(proxy).child("unread").runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if let unread = currentData.value {
                let _unread = unread as? Int ?? 0
                if _unread != 0 {
                    currentData.value = _unread - amt
                }
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        })
    }
}