//
//  API.swift
//  proxy
//
//  Created by Quan Vo on 8/15/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase

// API that read/writes to Firebase for proxy.
class API {
    /*
     - uid: Set when a user logs in. Used heavily throughout the app to build
     URLs to read/write.
     - ref: Reference to the root node of the database.
     */
    static let sharedInstance = API()
    
    let ref = FIRDatabase.database().reference()
    var proxiesRef = FIRDatabaseReference()
    var iconsRef = FIRDatabaseReference()
    var iconsRefHandle = FIRDatabaseHandle()
    var proxyNameGenerator = ProxyNameGenerator()
    var wordsLoaded = false
    var creatingProxy = false
    var icons = [String]()
    var iconURLCache = [String: String]()
    
    var uid: String = "" {
        didSet {
            observeIcons()
        }
    }
    
    private init() {
        proxiesRef = self.ref.child("proxies")
    }
    
    
    // MARK: - The Proxy
    
    
    // TODO: - Controllers that pull proxies must add checks to determine if they will display them
    
    /*
     Creating The Proxy
     
     Proxies are unique handles that users use to communicate with each other. A
     user can create as many proxies as they want, and communicate to any other
     proxy they want (as long as it's not their own). A proxy consists of a
     random adjective, capitalized noun, and then a number from 1-99. As of
     9/5/16, there are around 250,000,000 possible proxies.
     
     There will eventually be better system in place. This limit of possible
     proxies will decrease as the word bank is pruned for really long words or
     words I just don't want to be in the word bank. In addition, performance
     declines for the unique proxy finding algorithm as the user base grows. But
     I'll figure this out later.
     
     *The possible proxies limit will grow drastically when I add verbs in
     there -ing form to the list of adjectives (ie runningDog89). I don't know
     the term for this I'm a CS major.
     
     To create a proxy, we first must make sure the word bank is loaded. I am
     currently hosting a JSON of the words at some JSON hosting site. If it's
     not loaded, we load it then call create proxy again. If it's already
     loaded, we proceed as usual.
     
     The next step after that is to go ahead and create and write a proxy. Our
     ProxyNameGenerator struct handles the randomization for us. Once it's
     created, we request from the database all proxies with this name. Nodes are
     indexed by name to help with search performance. If there is ony one, it
     will be the one you just created, and you can have that proxy. The
     appropriate controllers are notified. If there is more than one, you tried
     creating a proxy that already existed and we delete the one you just made
     and try again.
     */
    func createProxy() {
        creatingProxy = true
        if wordsLoaded {
            tryCreateProxy()
        } else {
            loadWords()
        }
    }
    
    // Load the words from a JSON for the word generator to create a proxy.
    // Upon successful load, we call tryCreateProxy to get things going if this
    // was the first load.
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
    
    // Attempts to create a unique proxy. On failure, deletes the proxy it just
    // created and tries again. Will exit if the user cancels the
    // CreateNewProxy view.
    func tryCreateProxy() {
        let name = proxyNameGenerator.generateProxyName()
        var proxy = Proxy(name: name)
        proxiesRef.child(name).setValue(proxy.toAnyObject())
        proxiesRef.queryOrderedByChild("name").queryEqualToValue(name).observeSingleEventOfType(.Value, withBlock: { snapshot in
            if snapshot.childrenCount == 1 {
                self.creatingProxy = false
                proxy.icon = self.getRandomIcon()
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.NotificationKeys.ProxyCreated, object: self, userInfo: ["proxy": proxy.toAnyObject()])
            } else {
                self.deleteProxy(proxy)
                if self.creatingProxy {
                    self.tryCreateProxy()
                }
            }
        })
    }
    
    // Observe the icons the user has unlocked
    func observeIcons() {
        iconsRef = ref.child("users").child(uid).child("icons")
        iconsRefHandle = iconsRef.queryOrderedByKey().observeEventType(.Value, withBlock: { (snapshot) in
            if let icons = snapshot.value?.allKeys as? [String] {
                self.icons = icons
            }
        })
    }
    
    // Get a random icon from the user's available icons
    func getRandomIcon() -> String {
        let count = UInt32(icons.count)
        return icons[Int(arc4random_uniform(count))]
    }
    
    // We must be sure to delete the old proxy when we reroll for a new one
    func rerollProxy(oldProxy: Proxy) {
        deleteProxy(oldProxy)
        createProxy()
    }
    
    func deleteProxy(proxy: Proxy) {
        proxiesRef.child(proxy.name).removeValue()
    }
    
    // The creatingProxy Bool is there just in case the user taps back on the
    // CreateNewProxy view while the API is currently trying to create a proxy
    // for them. When creatingProxy is false, the proxy creation loop eventually
    // stops.
    func cancelCreateProxy(proxy: Proxy) {
        creatingProxy = false
        deleteProxy(proxy)
    }
    
    // Save the proxy to the user node with a fresh timestamp. This gives the
    // proxy a more up-to-date timestamp, because the user could have rolled the
    // proxy and then sat on the screen for a while before tapping 'Create'.
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
    
    // This is called to update a proxy's nickname sometime after it's creation.
    // We don't want to update the timestamp because the nickname update doesn't
    // need to be an event that triggers the proxy being displayed more
    // recently.
    func updateProxyNickname(proxy: Proxy, convos: [Convo], nickname: String) {
        ref.updateChildValues([
            "/proxies/\(proxy.name)/nickname": nickname,
            "/users/\(uid)/proxies/\(proxy.name)/nickname": nickname])
        for convo in convos {
            ref.updateChildValues([
                "/users/\(uid)/convos/\(convo.key)/proxyNickname": nickname,
                "/convos/\(proxy.name)/\(convo.key)/proxyNickname": nickname])
        }
    }
    
    /*
     Deleting A Proxy
     
     When you delete a proxy, you don't see that proxy or its convos, and stop
     receiving notifications for them (until you restore it). Any user
     attempting to contact that proxy will not know they are messaging a
     deleted proxy.
     
     When deleting a proxy, loop through all its conversations and set
     'proxyDeleted' to true for both your copies of that convo. Then set the
     proxy's 'deleted' to true. Then create an entry for it's key in
     
     /deleted/uid/proxy.key
     
     Also decrement your global unread by the proxy's unread.
     
     When loading proxies and convos, if 'deleted' and 'proxyDeleted' are true,
     don't load that proxy/convo, respectively.
     
     Deleted proxies show up in your 'Deleted Proxies' in 'Settings'. This view
     shows the proxies you have in /deleted/uid/. You can restore a proxy, and
     when that happens, set all it's conversation's 'proxyDeleted' to false for
     both copies of the convo, and set the proxy's 'deleted' to false. Then
     delete the proxy's entry in /deleted/uid/. Lastly, increment your global
     unread by the proxy's unread.
     */
    // TODO: New implementation
    func deleteProxy(proxy: Proxy, convos: [Convo]) {
        // Leave all the convos that this proxy is participating in
        for convo in convos {
            leaveConvo(proxy.name, convo: convo)
        }
        
        // Delete the proxy from the global list of used proxies
        ref.child("proxies").child(proxy.name).removeValue()
        
        // Delete the proxy from the user's node
        ref.child("users").child(uid).child("proxies").child(proxy.name).removeValue()
    }
    
    // Retrieve a user's proxy from its name. The proxy is passed back to the
    // user upon success.
    func getProxy(proxyName: String, completion: (success: Bool, proxy: Proxy) -> Void) {
        ref.child("users").child(uid).child("proxies").queryOrderedByKey().queryEqualToValue(proxyName).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            if snapshot.childrenCount == 1 {
                let proxy = Proxy(anyObject: snapshot.children.nextObject()!.value)
                completion(success: true, proxy: proxy)
            } else {
                completion(success: false, proxy: Proxy())
            }
        })
    }
    
    
    // MARK: - The Message
    
    
    /*
     Sending The First Message Between Two Proxies
     
     When sending a message, if we do not know if a conversation exists betweeen
     the two proxies (because the sender sent it from the 'New Message' view, we
     must check. If it is their first contact with each other, we must create a
     different convo struct for sender and receiver and then save it at all the
     appropriate places. More on these locations in 'The Conversation'.
     
     Each owner of a convo keeps track of their own:
     
     - senderId
     - senderProxy
     - recieverId
     - receiverProxy
     - convoNickname
     - proxyNickname
     - unread
     
     These all get set at this point.
     
     The convo's key in the database is the two proxys' names alphebatized and
     concatenated.
     
     We now pull the receiver's users/uid/blocked and see if we the sender's uid
     is on that list. If so, set the receiver's convos' 'blocked' to true.
     
     We can now save all this data atomically in a block.
     
     Then send it off our senderProxy and messageText to our normal messaging
     function to finish the job.
     
     In addition, we increment both user's 'Proxies Interacted With'.
     */
    // TODO: New implementation
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
        
        let update = [
            "/messages/\(convoKey)/\(messageKey)": message,
            "/users/\(uid)/convos/\(convoKey)": convoDict,
            "/convos/\(_senderProxy.name)/\(convoKey)": convoDict,
            "/users/\(receiverProxy.owner)/convos/\(convoKey)": receiverConvoDict,
            "/convos/\(receiverProxy.name)/\(convoKey)": receiverConvoDict,
            "/users/\(uid)/proxies/\(_senderProxy.name)": proxyDict]
        
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
    
    /*
     Sending A Message
     
     To send a message, we must update several nodes in the database:
     
     sender side:
     
     - sender's convo last message and timestamp
     - sender's proxy/convo last message and timestamp
     - sender's proxy last message and timestamp
     - sender's 'Messages Sent' incremented
     
     * Note: For your convos' 'left' value, set it to false. More on this in
     'Leaving A Conversation'.
     
     receiver side:
     
     - receiver's convo last message, timestamp, and unread
     - receiver's proxy/convo last message, timestamp, and unread
     - receiver's 'Messages Received' incremented*
     
     * Note: This means you can see when people you have blocked are still
     sending you messages because your 'Messages Received' goes up. That's
     okay.
     
     During one of these transactions, check 'blocked' and 'proxyDeleted'
     in the convo struct.
     
     if !blocked && !proxyDeleted
     - update receiver's global unread
     
     if !blocked
     - update receiver's proxy last message, timestamp, and unread
     
     neutral side:
     
     - the actual message
     
     All writes on the sender's side can be done atomically with
     updateChildValues().
     All writes on the receiver's side must be done in individual transactions
     since they involve incrementing an Int.
     */
    // TODO: New implementation
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
    
    
    // MARK: - The Conversation (Convo)
    
    
    /*
     Anytime a conversation is updated, you'll see me say something like "must
     be updated in both places". This is because each user "holds" two copies
     of each conversation they are in. One in their own node, and one in the
     /convos/proxy.key/convo.key node. This is so that a list of all of a user's
     convos can be pulled for the home screen, and a list of proxy specific
     convos can be pull for the ProxyInfoTableViewController.
     */
    
    // Update the convo's nickname in both places
    func updateConvoNickname(convo: Convo, nickname: String) {
        ref.updateChildValues([
            // User's copy of convo
            "users/\(uid)/convos/\(convo.key)/convoNickname": nickname,
            
            // The convo saved by proxy
            "convos/\(convo.senderProxy)/\(convo.key)/convoNickname": nickname])
    }
    
    // Called when the user enters a convo and as he/she stays in the convo and
    // receives more messages into that convo.
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
    
    /*
     Leaving A Conversation
     
     When you leave a convo, set 'left' to true.
     
     When loading up your convos, if left == true, don't add it to the convos
     array for table refresh.
     
     Also, decrement your corresponding proxy's and global unread by the
     convo's unread value.
     
     If someone sends you a message to a convo you have left, your convo's
     'left' value will be set back to fale, and you will see it again.
     
     They will continue to see your messages again until they block you.
     
     If you send a proxy a message in which a previous conversation existed
     between the two of you but you had left it, your convos' 'left' will be set
     back to false and you will see it again.
     */
    // TODO: New Implementation
    // TODO: Controllers that pull convos must add checks to determine if they will display them
    func leaveConvo(proxyName: String, convo: Convo) {
        // Delete the convo in the user's node
        ref.child("users").child(uid).child("convos").child(convo.key).removeValue()
        
        // Delete the convo in the convo/proxy node
        ref.child("convos").child(proxyName).child(convo.key).removeValue()
        
        // Decrement the user's global unread by the convo's unread
        self.ref.child("users").child(uid).child("unread").runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if let unread = currentData.value {
                let _unread = unread as? Int ?? 0
                if _unread != 0 {
                    currentData.value = _unread - convo.unread
                }
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        })
    }
    
    // When you mute a convo, you stop getting push notifications for it.
    // TODO: Implement when get to push notifications
    func muteConvo() {}
    
    /*
     Blocking Users
     
     When you block a user, set the 'blocked' in your two copies of the convo to
     true.
     
     Then loop through all your convos, if the receiverId matches this user's id,
     set that convo's 'blocked' to true as well, again for both your copies of
     the convo.
     
     When you load convos in your home view or proxy info view, if a convo's
     'blocked' is true, then don't load it.
     
     When someone sends you a message and it is the first message between the
     two proxies, they will pull your /blocked/uid. If their uid exists in your
     blocked, they will send you a message as normal, except that your two
     copies of the convo will have 'blocked' == true, and your proxy and global
     unread will not increment. This means if you unblock that user, you will
     then see all messages they have been sending you, from any proxy.
     
     Keep a copy of the users you have blocked as
     
     /blocked/uid/blockedUserId/blockedUserProxy
     
     blockedUserProxy is the proxy name you blocked the user as.
     
     You can see those you have blocked somewhere in Settings -> Blocked Users,
     represented as blockedUserProxy.
     
     You can unblock users, and when this happens, loop through all your convos,
     if the receiverId matches the userId you unblocked, set that convo's
     'blocked' to false, for both copies of your convo. Then increment your
     proxy for that convo's unread and your global unread by that convo's
     unread.
     
     Then delete that user's entry in your /blocked/uid/blockedUserId.
     */
    // TODO: Implement
    func blockUser() {}
}