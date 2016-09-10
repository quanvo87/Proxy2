//
//  API.swift
//  proxy
//
//  Created by Quan Vo on 8/15/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class API {
    
    static let sharedInstance = API()
    
    let ref = FIRDatabase.database().reference()
    var iconsRefHandle = FIRDatabaseHandle()
    var proxyNameGenerator = ProxyNameGenerator()
    var isCreatingProxy = false
    var icons = [String]()
    var iconURLCache = [String: String]()
    
    var uid: String = "" {
        didSet {
            observeIcons()
        }
    }
    
    private init() {}
    
    deinit {
        ref.child("icons").child(uid).removeObserverWithHandle(iconsRefHandle)
    }
    
    /// Give the user access to the default icons.
    func setDefaultIcons(forUser user: String) {
        let defaultIcons = DefaultIcons(id: user).defaultIcons
        ref.updateChildValues(defaultIcons as! [NSObject : AnyObject])
    }
    
    // MARK: - The Proxy
    
    // TODO: - Controllers that pull proxies must add checks to determine if they will display them
    
    /// Loads word bank if needed, else call `tryCreateProxy`.
    func create(proxy completion: (proxy: Proxy?) -> Void) {
        isCreatingProxy = true
        if proxyNameGenerator.isLoaded {
            tryCreating(proxy: { (proxy) in
                completion(proxy: proxy)
            })
        } else {
            load(proxyNameGenerator: { (proxy) in
                completion(proxy: proxy)
            })
        }
    }
    
    /// Loads and caches word bank. Calls `tryCreateProxy` when done.
    func load(proxyNameGenerator completion: (proxy: Proxy?) -> Void) {
        ref.child("wordbank").observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            if let words = snapshot.value, let adjectives = words["adjectives"], let nouns = words["nouns"] {
                self.proxyNameGenerator.adjs = adjectives as! [String]
                self.proxyNameGenerator.nouns = nouns as! [String]
                self.proxyNameGenerator.isLoaded = true
                self.tryCreating(proxy: { (proxy) in
                    completion(proxy: proxy)
                })
            }
        })
    }
    
    /// Returns a proxy with a randomly generated, unique name. Returns nil if
    /// the user has canceled creating a proxy.
    func tryCreating(proxy completion: (proxy: Proxy?) -> Void) {
        let globalKey = ref.child("proxies").childByAutoId().key
        let key = proxyNameGenerator.generateProxyName()
        let icon = getRandomIcon()
        let proxy = Proxy(globalKey: globalKey, key: key, owner: uid, icon: icon)
        ref.child("proxies").child(globalKey).setValue(proxy.toAnyObject())
        ref.child("proxies").queryOrderedByChild("key").queryEqualToValue(key).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            if snapshot.childrenCount == 1 {
                self.isCreatingProxy = false
                completion(proxy: proxy)
            } else {
                self.delete(proxy)
                if self.isCreatingProxy {
                    self.tryCreating(proxy: { (proxy) in
                        completion(proxy: proxy)
                    })
                } else {
                    completion(proxy: nil)
                }
            }
        })
    }
    
    /// Keeps an up-to-date list of the icons the user has unlocked. These are
    /// actually partial file paths to the image locations in our storage.
    func observeIcons() {
        iconsRefHandle = ref.child("icons").child(uid).observeEventType(.Value, withBlock: { (snapshot) in
            if let icons = snapshot.value?.allKeys as? [String] {
                self.icons = icons
            }
        })
    }
    
    /// Returns a random icon from the user's available icons.
    func getRandomIcon() -> String {
        let count = UInt32(icons.count)
        return icons[Int(arc4random_uniform(count))]
    }
    
    /// Deletes the old proxy and returns a new one.
    func reroll(fromOldProxy proxy: Proxy, completion: (proxy: Proxy?) -> Void) {
        delete(proxy)
        tryCreating { (proxy) in
            completion(proxy: proxy)
        }
    }
    
    /// Deletes the proxy stored under its global key.
    func delete(proxy: Proxy) {
        ref.child("proxies").child(proxy.globalKey).removeValue()
    }
    
    /// Deletes the proxy stored under its global key. Notifies API to stop
    /// trying to create a new proxy.
    func cancelCreating(proxy: Proxy) {
        isCreatingProxy = false
        delete(proxy)
    }
    
    /// Saves the proxy with a new `nickname` and timestamp. Saved under user
    /// Id.
    func save(proxy proxy: Proxy, withNickname nickname: String) {
        var _proxy = proxy
        let timestamp = NSDate().timeIntervalSince1970
        _proxy.nickname = nickname
        _proxy.timestamp = timestamp
        ref.child("proxies").child(uid).child(proxy.key).setValue(_proxy.toAnyObject())
    }
    
    /// Returns the icon's URL in our storage. Builds and caches it if
    /// necessary.
    func getURL(forIcon icon: String, completion: (URL: String) -> Void) {
        if let URL = iconURLCache[icon] {
            completion(URL: URL)
        } else {
            let storageRef = FIRStorage.storage().referenceForURL(URLs.Storage)
            let starsRef = storageRef.child("\(icon).png")
            starsRef.downloadURLWithCompletion { (URL, error) -> Void in
                if error == nil, let URL = URL?.absoluteString {
                    self.iconURLCache[icon] = URL
                    completion(URL: URL)
                }
            }
        }
    }
    
    /// Updates the proxy's nickname in the required places.
    func update(nickname nickname: String, forProxy proxy: Proxy, withConvos convos: [Convo]) {
        
        /// In user's node.
        ref.child("proxies").child(proxy.owner).child(proxy.key).child("nickname").setValue(nickname)
        
        /// For each convo the proxy is in.
        for convo in convos {
            ref.updateChildValues([
                "/convos/\(proxy.owner)/\(convo.key)/senderNickname": nickname,
                "/convos/\(proxy.key)/\(convo.key)/senderNickname": nickname])
        }
    }
    
    /// Updates the proxy's icon in the required places.
    func update(icon icon: String, forProxy proxy: Proxy) {
        
        /// Global proxy list
        ref.child("proxies").child(proxy.globalKey).child("icon").setValue(icon)
        
        /// User proxy list
        ref.child("proxies").child(proxy.owner).child(proxy.key).child("icon").setValue(icon)
        
        /// Receiver's side of all convos this proxy is in
        ref.child("convos").child(proxy.key).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            for child in snapshot.children {
                let convo = Convo(anyObject: child.value)
                self.ref.child("convos").child(convo.receiverId).child(convo.key).child("icon").setValue(icon)
                self.ref.child("convos").child(convo.receiverProxy).child(convo.key).child("icon").setValue(icon)
            }
        })
    }
    
    /// Deletes the given proxy for the user and global list.
    /// Deletes all sender side convos under that proxy.
    /// Notifies all receivers of those convos that this proxy has been deleted.
    /// (The actual user is not notified.)
    /// Decrement's user's unread by the remaining unread in the proxy.
    func delete(proxy proxy: Proxy, withConvos convos: [Convo]) {
        
        /// Loop through all convos this proxy is in
        for convo in convos {
            
            /// Notify receivers in convos that this proxy is deleted
            ref.child("convos").child(convo.receiverId).child(convo.key).child("receiverDeletedProxy").setValue(true)
            ref.child("convos").child(convo.receiverProxy).child(convo.key).child("receiverDeletedProxy").setValue(true)
            
            /// Delete the convos on the sender's side
            ref.child("convos").child(convo.senderId).child(convo.key).removeValue()
            ref.child("convos").child(convo.senderProxy).child(convo.key).removeValue()
        }
        
        /// Delete from global list
        ref.child("proxies").child(proxy.globalKey).removeValue()
        
        /// Delete the proxy from the user's node
        ref.child("proxies").child(uid).child(proxy.key).removeValue()
        
        /// Decrement user's unread by proxy's unread
        decrementUnread(forUser: proxy.owner, byAmount: proxy.unread)
    }
    
    /// Returns a proxy struct from the database using the given `key`.
    func getProxy(withKey key: String, completion: (proxy: Proxy?) -> Void) {
        ref.child("proxies").child(uid).queryOrderedByChild("key").queryEqualToValue(key).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            if snapshot.childrenCount == 1 {
                let proxy = Proxy(anyObject: snapshot.children.nextObject()!.value)
                completion(proxy: proxy)
            } else {
                completion(proxy: nil)
            }
        })
    }
    
    // MARK: - The Message
    
    /// Error checks before sending it off to the appropriate message sending
    /// fuction. Returns the sender's convo on success. Returns an ErrorAlert on
    /// failure.
    func send(message message: String, fromSenderProxy senderProxy: Proxy, toReceiverProxyName receiverProxyName: String, completion: (error: ErrorAlert?, convo: Convo?) -> Void ) {
        
        /// Check if receiver exists
        self.ref.child("proxies").queryOrderedByChild("key").queryEqualToValue(receiverProxyName).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            guard snapshot.childrenCount == 1 else {
                completion(error: ErrorAlert(title: "Recipient Not Found", message: "Perhaps there was a spelling error?"), convo: nil)
                return
            }
            
            /// Check if sender is trying to send to him/herself
            let receiverProxy = Proxy(anyObject: snapshot.children.nextObject()!.value)
            guard senderProxy.owner != receiverProxy.owner else {
                completion(error: ErrorAlert(title: "Cannot Send To Self", message: "Did you enter yourself as a recipient by mistake?"), convo: nil)
                return
            }
            
            /// Build convo key from sorting and concatenizing the proxy names
            let convoKey = [senderProxy.key, receiverProxy.key].sort().joinWithSeparator("")
            
            /// Check if existing convo between the proxies exists
            self.ref.child("convos").child(senderProxy.owner).queryEqualToValue(convoKey).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                
                /// Existing convo found, use it to send the message
                if snapshot.childrenCount == 1 {
                    let convo = Convo(anyObject: snapshot.value!)
                    
                    self.send(message: message, usingSenderConvo: convo, completion: { (convo) in
                        completion(error: nil, convo: convo)
                    })
                }
                
                /// No convo found, must set up convo before sending message
                self.setUpFirstMessage(fromSenderProxy: senderProxy, toReceiverProxy: receiverProxy, usingConvoKey: convoKey, withMessage: message, completion: { (convo) in
                    completion(error: nil, convo: convo)
                })
            })
        })
    }
    
    /// Creates a different convo struct for each user.
    /// Checks if sender is blocked by receiver. 
    /// Saves the convo structs.
    /// Increments both users' `proxiesInteractedWith`.
    /// Sends off to `sendMessage`.
    /// Returns updated sender's `convo`.
    func setUpFirstMessage(fromSenderProxy senderProxy: Proxy, toReceiverProxy receiverProxy: Proxy, usingConvoKey convoKey: String, withMessage message: String, completion: (convo: Convo) -> Void) {
        
        /// Check if sender is in receiver's blocked list
        ref.child("blocked").child(receiverProxy.owner).child(senderProxy.owner).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            
            let senderBlocked = snapshot.childrenCount == 1
            
            var senderConvo = Convo()
            senderConvo.key = convoKey
            var receiverConvo = senderConvo
            
            senderConvo.senderId = senderProxy.owner
            senderConvo.senderProxy = senderProxy.key
            senderConvo.receiverId = receiverProxy.owner
            senderConvo.receiverProxy = receiverProxy.key
            senderConvo.icon = receiverProxy.icon
            senderConvo.receiverIsBlocking = senderBlocked
            
            receiverConvo.senderId = receiverProxy.owner
            receiverConvo.senderProxy = receiverProxy.key
            receiverConvo.receiverId = senderProxy.owner
            receiverConvo.receiverProxy = senderProxy.key
            receiverConvo.icon = senderProxy.icon
            receiverConvo.senderIsBlocking = senderBlocked
            
            self.update(senderConvo)
            self.update(proxyConvo: senderConvo)
            self.incremementProxiesInteractedWith(forUser: senderProxy.owner)
            
            self.update(receiverConvo)
            self.update(proxyConvo: receiverConvo)
            self.incremementProxiesInteractedWith(forUser: receiverProxy.owner)
            
            self.send(message: message, usingSenderConvo: senderConvo, completion: { (convo) in
                completion(convo: convo)
            })
        })
    }
    
    /**
     Returns updated sender's convo.
     
     Also updates:
     
     Sender's side:
     - convo
     - proxy convo
     - proxy
     - `Messages Sent`
     
     Receiver's side:
     
     if !receiverDeletedProxy && !receiverBlocking
     - unread
     - proxy
     
     if !receiverDeletedProxy
     - convo
     - proxy convo
     - `Messages Received`
     
     Neutral side:
     - the message
     - 'didLeaveConvo' for both users
     */
    func send(message message: String, usingSenderConvo convo: Convo, completion: (convo: Convo) -> Void) {
        
        let timestamp = NSDate().timeIntervalSince1970
        
        let messageKey = self.ref.child("messages").child(convo.key).childByAutoId().key
        let _message = Message(key: messageKey, sender: uid, message: message, timestamp: timestamp)
        save(message: _message, toConvo: convo.key)
        
        // Sender updates
        var _convo = convo
        _convo.message = "you: " + message
        _convo.timestamp = timestamp
        _convo.didLeaveConvo = false
        update(_convo)
        update(proxyConvo: _convo)
        update(timestamp: timestamp, forProxy: convo.senderProxy, forUser: convo.senderId)
        incrementMessagesSent(forUser: convo.senderId)
        
        // Receiver updates
        if !convo.receiverDeletedProxy && !convo.receiverIsBlocking {
            incrementUnread(forUser: convo.receiverId)
            update(proxy: convo.receiverProxy, forUser: convo.receiverId, withTimestamp: timestamp)
        }
        
        if !convo.receiverDeletedProxy {
            update(convo: convo.key, forUser: convo.receiverId, withMessage: message, withTimestamp: timestamp)
            update(proxyConvo: convo.key, forProxy: convo.receiverProxy, withMessage: message, withTimestamp: timestamp)
            incrementMessagesReceived(forUser: convo.receiverId)
        }
        
        completion(convo: _convo)
    }
    
    // MARK: Helper functions for writing to database
    
    /// Save a message using a convo key.
    func save(message message: Message, toConvo convo: String) {
        ref.child("messages").child(convo).child(message.key).setValue(message.toAnyObject())
    }
    
    /// Overwrite the given convo at its user's convos location in the database.
    func update(convo: Convo) {
        ref.child("convos").child(convo.senderId).child(convo.key).setValue(convo.toAnyObject())
    }
    
    /// Update the convo's `unread`, `message`, `timestamp`, & `didLeaveConvo`.
    func update(convo convo: String, forUser user: String, withMessage message: String, withTimestamp timestamp: Double) {
        self.ref.child("convos").child(user).child(convo).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if var convo = currentData.value as? [String: AnyObject] {
                let unread = convo["unread"] as? Int ?? 0
                convo["unread"] = unread + 1
                convo["message"] = message
                convo["timestamp"] = timestamp
                convo["didLeaveConvo"] = false
                currentData.value = convo
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        })
    }
    
    /// Overwrite the given proxy convo at it's users proxies location in the
    /// database.
    func update(proxyConvo proxyConvo: Convo) {
        ref.child("convos").child(proxyConvo.senderProxy).child(proxyConvo.key).setValue(proxyConvo.toAnyObject())
    }
    
    /// Update the proxy convo's `unread`, `message`, `timestamp`, &
    /// `didLeaveConvo`.
    func update(proxyConvo convo: String, forProxy proxy: String, withMessage message: String, withTimestamp timestamp: Double) {
        self.ref.child("convos").child(proxy).child(convo).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if var convo = currentData.value as? [String: AnyObject] {
                let unread = convo["unread"] as? Int ?? 0
                convo["unread"] = unread + 1
                convo["message"] = message
                convo["timestamp"] = timestamp
                convo["didLeaveConvo"] = false
                currentData.value = convo
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        })
    }
    
    /// Update the proxy's `timestamp`.
    func update(timestamp timestamp: Double, forProxy proxy: String, forUser user: String) {
        ref.child("proxies").child(user).child(proxy).child("timestamp").setValue(timestamp)
    }
    
    /// Update the proxy's `unread` & `timestamp`.
    func update(proxy proxy: String, forUser user: String, withTimestamp timestamp: Double) {
        self.ref.child("proxies").child(user).child(proxy).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if var proxy = currentData.value as? [String: AnyObject] {
                let unread = proxy["unread"] as? Int ?? 0
                proxy["unread"] = unread + 1
                proxy["timestamp"] = timestamp
                currentData.value = proxy
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        })
    }
    
    /// Increment the user's `proxiesInteractedWith`.
    func incremementProxiesInteractedWith(forUser user: String) {
        self.ref.child("proxiesInteractedWith").child(user).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if let count = currentData.value {
                let _count = count as? Int ?? 0
                currentData.value = _count + 1
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        })
    }
    
    /// Increment the user's `messagesSent`.
    func incrementMessagesSent(forUser user: String) {
        self.ref.child("messagesSent").child(user).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if let count = currentData.value {
                let _count = count as? Int ?? 0
                currentData.value = _count + 1
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        })
    }
    
    /// Increment the user's `messagesReceived`.
    func incrementMessagesReceived(forUser user: String) {
        self.ref.child("messagesReceived").child(user).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if let count = currentData.value {
                let _count = count as? Int ?? 0
                currentData.value = _count + 1
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        })
    }
    
    /// Increment the user's `unread`.
    func incrementUnread(forUser user: String) {
        self.ref.child("unread").child(user).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if let unread = currentData.value {
                let _unread = unread as? Int ?? 0
                currentData.value = _unread + 1
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        })
    }
    
    // MARK: - The Conversation (Convo)
    
    // Update the convo's nickname in both places
    // TODO: New Implementation
    func updateReceiverNickname(convo: Convo, nickname: String) {
        ref.updateChildValues([
            // User's copy of convo
            "users/\(uid)/convos/\(convo.key)/receiverNickname": nickname,
            
            // The convo saved by proxy
            "convos/\(convo.senderProxy)/\(convo.key)/receiverNickname": nickname])
    }
    
    /// Decrements user, convo, proxy convo, and proxy `unread` by `amount`.
    func decrementAllUnreadFor(convo convo: Convo, byAmount amount: Int) {
        decrementUnread(forUser: convo.senderId, byAmount: amount)
        decrementUnread(forConvo: convo.key, forUser: convo.senderId, byAmount: amount)
        decrementUnread(forConvo: convo.key, underProxy: convo.senderProxy, byAmount: amount)
        decrementUnread(forProxy: convo.senderProxy, forUser: convo.senderId, byAmount: amount)
    }
    
    /// Derement the user's `unread` by `amount`.
    func decrementUnread(forUser user: String, byAmount amount: Int) {
        ref.child("unread").child(user).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if let unread = currentData.value {
                let _unread = unread as? Int ?? 0
                currentData.value = _unread - amount
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        })
    }
    
    /// Decrement the convo's `unread` by `amount`.
    func decrementUnread(forConvo convo: String, forUser user: String, byAmount amount: Int) {
        ref.child("convos").child(user).child(convo).child("unread").runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if let unread = currentData.value {
                let _unread = unread as? Int ?? 0
                currentData.value = _unread - amount
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        })
    }
    
    /// Decrement the proxy convo's `unread` by `amount`.
    func decrementUnread(forConvo convo: String, underProxy proxy: String, byAmount amount: Int) {
        ref.child("convos").child(proxy).child(convo).child("unread").runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if let unread = currentData.value {
                let _unread = unread as? Int ?? 0
                currentData.value = _unread - amount
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        })
    }
    
    /// Decrement the proxy's `unread` by `amount`.
    func decrementUnread(forProxy proxy: String, forUser user: String, byAmount amount: Int) {
        ref.child("proxies").child(user).child(proxy).child("unread").runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if let unread = currentData.value {
                let _unread = unread as? Int ?? 0
                currentData.value = _unread - amount
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        })
    }
    
    /**
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
    
    /**
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
     your global unread by that convo's unread.
     
     Then delete that user's entry in your /blocked/uid/blockedUserId.
     */
    // TODO: Implement
    func blockUser() {}
}