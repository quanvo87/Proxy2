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
    
    var uid = ""
    let ref = FIRDatabase.database().reference()
    var proxiesRef = FIRDatabaseReference()
    var proxyNameGenerator = ProxyNameGenerator()
    var wordsLoaded = false
    var creatingProxy = false
    
    private init() {
        proxiesRef = self.ref.child("proxies")
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
    
    func updateProxyNickname(proxy: Proxy, convos: [Convo], nickname: String) {
        ref.updateChildValues([
            "/proxies/\(proxy.name)/nickname": nickname,
            "/users/\(uid)/proxies/\(proxy.name)/nickname": nickname])
        for convo in convos {
            ref.updateChildValues([
                "/members/\(convo.key)/\(proxy.name)/nickname": nickname,
                "/users/\(uid)/convos/\(convo.key)/proxyNickname": nickname])
        }
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
    
    func sendMessage(convo: Convo, messageText: String, completion: (success: Bool) -> Void) {
        
        var _convo = convo
        
        let timestamp = NSDate().timeIntervalSince1970
        
        let messageKey = self.ref.child("messages").child(_convo.key).childByAutoId().key
        let message = Message(key: messageKey, sender: uid, message: messageText, timestamp: timestamp).toAnyObject()
        
        _convo.message = messageText
        _convo.timestamp = timestamp
        let convoDict = _convo.toAnyObject()
        
        let update = [
            "/messages/\(_convo.key)/\(messageKey)": message,
            "/users/\(uid)/convos/\(_convo.key)": convoDict,
            "/convos/\(_convo.senderProxy)/\(_convo.key)": convoDict]
        
        self.ref.updateChildValues(update, withCompletionBlock: { (error, ref) in
            
            // Sender proxy
            self.ref.child("users").child(self.uid).child("proxies").child(_convo.senderProxy).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
                if var proxy = currentData.value as? [String: AnyObject] {
                    proxy["message"] = messageText
                    proxy["timestamp"] = timestamp
                    currentData.value = proxy
                    return FIRTransactionResult.successWithValue(currentData)
                }
                return FIRTransactionResult.successWithValue(currentData)
            })
            
            // Receiver global unread
            self.ref.child("users").child(_convo.receiverId).child("unread").runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
                if let unread = currentData.value {
                    let _unread = unread as? Int ?? 0
                    currentData.value = _unread + 1
                    return FIRTransactionResult.successWithValue(currentData)
                }
                return FIRTransactionResult.successWithValue(currentData)
            })
            
            // Receiver convo unread
            self.ref.child("users").child(_convo.receiverId).child("convos").child(_convo.key).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
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
            self.ref.child("convos").child(_convo.receiverProxy).child(_convo.key).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
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
            self.ref.child("users").child(_convo.receiverId).child("proxies").child(_convo.receiverProxy).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
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
    
    func sendFirstMessage(senderProxy: Proxy, receiverProxy: Proxy, messageText: String, completion: (success: Bool, convo: Convo) -> Void) {
        var convo = Convo()
        var receiverConvo = Convo()
        var _senderProxy = senderProxy
        
        let timestamp = NSDate().timeIntervalSince1970
        
        let convoKey = self.ref.child("users").child(uid).child("convos").childByAutoId().key
        
        let messageKey = self.ref.child("messages").child(convoKey).childByAutoId().key
        let message = Message(key: messageKey, sender: uid, message: messageText, timestamp: timestamp).toAnyObject()
        
        convo.key = convoKey
        convo.senderId = uid
        convo.senderProxy = _senderProxy.name
        convo.receiverId = receiverProxy.owner
        convo.receiverProxy = receiverProxy.name
        convo.message = messageText
        convo.timestamp = timestamp
        let convoDict = convo.toAnyObject()
        
        receiverConvo = convo
        receiverConvo.senderId = receiverProxy.owner
        receiverConvo.senderProxy = receiverProxy.name
        receiverConvo.receiverId = uid
        receiverConvo.receiverProxy = _senderProxy.name
        receiverConvo.unread = 1
        let receiverConvoDict = receiverConvo.toAnyObject()
        
        _senderProxy.message = messageText
        _senderProxy.timestamp = timestamp
        let proxyDict = _senderProxy.toAnyObject()
        
        let senderMember = Member(owner: uid, name: _senderProxy.name, nickname: _senderProxy.nickname).toAnyObject()
        let receiverMember = Member(owner: receiverProxy.owner, name: receiverProxy.name, nickname: receiverProxy.nickname).toAnyObject()
        
        let update = [
            "/messages/\(convoKey)/\(messageKey)": message,
            "/users/\(uid)/convos/\(convoKey)": convoDict,
            "/convos/\(_senderProxy.name)/\(convoKey)": convoDict,
            "/users/\(receiverProxy.owner)/convos/\(convoKey)": receiverConvoDict,
            "/convos/\(receiverProxy.name)/\(convoKey)": receiverConvoDict,
            "/users/\(uid)/proxies/\(_senderProxy.name)": proxyDict,
            "/members/\(convoKey)/\(senderProxy.name)": senderMember,
            "/members/\(convoKey)/\(receiverProxy.name)": receiverMember]
        
        self.ref.updateChildValues(update, withCompletionBlock: { (error, ref) in
            if error != nil {
                completion(success: false, convo: convo)
                return
            }
            
            // receiver user unread
            self.ref.child("users").child(receiverProxy.owner).child("unread").runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
                if let unread = currentData.value {
                    let _unread = unread as? Int ?? 0
                    currentData.value = _unread + 1
                    return FIRTransactionResult.successWithValue(currentData)
                }
                return FIRTransactionResult.successWithValue(currentData)
            })
            
            // receiver proxy unread
            self.ref.child("users").child(receiverProxy.owner).child("proxies").child(receiverProxy.name).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
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
            
            completion(success: true, convo: convo)
        })
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
    
    func deleteProxy(proxy: Proxy, convos: [Convo]) {
        for convo in convos {
            // dont remove this value, set a bool in members called 'present' to false
            // and then check if both members are !present, if so, delete members/convo
            // do this in another method
            ref.child("members").child(convo.key).child(proxy.name).removeValue()
            ref.child("convos").child(proxy.name).child(convo.key).removeValue()
        }
        
        ref.child("proxies").child(proxy.name).removeValue()
        ref.child("users").child(uid).child("proxies").child(proxy.name).removeValue()
        
        self.ref.child("users").child(uid).child("unread").runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if let unread = currentData.value {
                let _unread = unread as? Int ?? 0
                if _unread != 0 {
                    currentData.value = _unread - proxy.unread
                }
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        })
    }
}