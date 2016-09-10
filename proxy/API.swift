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
    var wordbankIsLoaded = false
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
    
    /// Gives a user access to the default icons.
    func setIcons(id: String) {
        let defaultIcons = DefaultIcons(id: id).defaultIcons
        ref.updateChildValues(defaultIcons as! [NSObject : AnyObject])
    }
    
    // MARK: - The Proxy
    
    // TODO: - Controllers that pull proxies must add checks to determine if they will display them
    
    /// Loads word bank if needed, else call `tryCreateProxy`.
    func createProxy(completion: (proxy: Proxy?) -> Void) {
        isCreatingProxy = true
        if wordbankIsLoaded {
            tryCreatingProxy({ (proxy) in
                completion(proxy: proxy)
            })
        } else {
            loadWordBank({ (proxy) in
                completion(proxy: proxy)
            })
        }
    }
    
    /// Loads and caches word bank. Calls `tryCreateProxy` when done.
    func loadWordBank(completion: (proxy: Proxy?) -> Void) {
        ref.child("wordbank").observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            if let words = snapshot.value, let adjectives = words["adjectives"], let nouns = words["nouns"] {
                self.proxyNameGenerator.adjs = adjectives as! [String]
                self.proxyNameGenerator.nouns = nouns as! [String]
                self.wordbankIsLoaded = true
                self.tryCreatingProxy({ (proxy) in
                    completion(proxy: proxy)
                })
            }
        })
    }
    
    /// Returns a proxy with a randomly generated, unique name. Returns nil if
    /// the user has canceled creating a proxy.
    func tryCreatingProxy(completion: (proxy: Proxy?) -> Void) {
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
                    self.tryCreatingProxy({ (proxy) in
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
    func reroll(oldProxy: Proxy, completion: (proxy: Proxy?) -> Void) {
        delete(oldProxy)
        tryCreatingProxy { (proxy) in
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
    
    /// Saves the proxy with a new nickname and timestamp. Saved under user Id.
    func saveWithNickname(proxy: Proxy, nickname: String) {
        var _proxy = proxy
        let timestamp = NSDate().timeIntervalSince1970
        _proxy.nickname = nickname
        _proxy.timestamp = timestamp
        ref.child("proxies").child(uid).child(proxy.key).setValue(_proxy.toAnyObject())
    }
    
    /// Returns the icon's URL in our storage. Builds and caches it if
    /// necessary.
    func getURL(icon: String, completion: (URL: String) -> Void) {
        if let URL = iconURLCache[icon] {
            completion(URL: URL)
        } else {
            let storageRef = FIRStorage.storage().referenceForURL(Constants.URLs.Storage)
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
    func updateNickname(proxy: Proxy, convos: [Convo], nickname: String) {
        
        // In user's node.
        ref.child("proxies").child(proxy.owner).child(proxy.key).child("nickname").setValue(nickname)
        
        // For each convo the proxy is in.
        for convo in convos {
            ref.updateChildValues([
                "/convos/\(proxy.owner)/\(convo.key)/proxyNickname": nickname,
                "/convos/\(proxy.key)/\(convo.key)/proxyNickname": nickname])
        }
    }
    
    /// Updates the proxy's icon in the required places.
    func updateIcon(proxy: Proxy, icon: String) {
        
        // Global proxy list
        ref.child("proxies").child(proxy.globalKey).child("icon").setValue(icon)
        
        // User proxy list
        ref.child("proxies").child(proxy.owner).child(proxy.key).child("icon").setValue(icon)
        
        // Receiver's side of all convos this proxy is in
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
    func delete(proxy: Proxy, convos: [Convo]) {
        
        // Loop through all convos this proxy is in
        for convo in convos {
            
            // Notify receivers in convos that this proxy is deleted
            ref.child("convos").child(convo.receiverId).child(convo.key).child("receiverDeletedProxy").setValue(true)
            ref.child("convos").child(convo.receiverProxy).child(convo.key).child("receiverDeletedProxy").setValue(true)
            
            // Delete the convos on the sender's side
            ref.child("convos").child(convo.senderId).child(convo.key).removeValue()
            ref.child("convos").child(convo.senderProxy).child(convo.key).removeValue()
        }
        
        // Delete from global list
        ref.child("proxies").child(proxy.globalKey).removeValue()
        
        // Delete the proxy from the user's node
        ref.child("proxies").child(uid).child(proxy.key).removeValue()
        
        // Decrement user's unread by proxy's unread
        decrementUnreadForUser(proxy.owner, amount: proxy.unread)
    }
    
    /// Returns a proxy struct from the database using the given key.
    func getProxy(key: String, completion: (proxy: Proxy?) -> Void) {
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
    func sendMessage(senderProxy: Proxy, receiverProxyName: String, message: String, completion: (error: ErrorAlert?, convo: Convo?) -> Void ) {
        
        // Check if receiver exists
        self.ref.child("proxies").queryOrderedByChild("key").queryEqualToValue(receiverProxyName).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            guard snapshot.childrenCount == 1 else {
                completion(error: ErrorAlert(title: "Recipient Not Found", message: "Perhaps there was a spelling error?"), convo: nil)
                return
            }
            
            // Check if sender is trying to send to him/herself
            let receiverProxy = Proxy(anyObject: snapshot.children.nextObject()!.value)
            guard senderProxy.owner != receiverProxy.owner else {
                completion(error: ErrorAlert(title: "Cannot Send To Self", message: "Did you enter yourself as a recipient by mistake?"), convo: nil)
                return
            }
            
            // Build convo key from sorting and concatenizing the proxy names
            let convoKey = [senderProxy.key, receiverProxy.key].sort().joinWithSeparator("")
            
            // Check if existing convo between the proxies exists
            self.ref.child("convos").child(senderProxy.owner).queryEqualToValue(convoKey).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                
                // Existing convo found, use it to send the message
                if snapshot.childrenCount == 1 {
                    let convo = Convo(anyObject: snapshot.value!)
                    self.sendMessage(convo, messageText: message, completion: { (convo) -> Void in
                        completion(error: nil, convo: convo)
                        return
                    })
                }
                
                // No convo found, must set up convo before sending message
                self.setUpFirstMessage(senderProxy, receiverProxy: receiverProxy, convoKey: convoKey, message: message, completion: { (convo) in
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
    func setUpFirstMessage(senderProxy: Proxy, receiverProxy: Proxy, convoKey: String, message: String, completion: (convo: Convo) -> Void) {
        
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
            
            self.updateConvo(senderConvo)
            self.updateProxyConvo(senderConvo)
            self.incremementProxiesInteractedWith(senderProxy.owner)
            
            self.updateConvo(receiverConvo)
            self.updateProxyConvo(receiverConvo)
            self.incremementProxiesInteractedWith(receiverProxy.owner)
            
            self.sendMessage(senderConvo, messageText: message, completion: { (convo) in
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
     - 'leftConvo' for both users
     */
    func sendMessage(convo: Convo, messageText: String, completion: (convo: Convo) -> Void) {
        
        let timestamp = NSDate().timeIntervalSince1970
        
        let messageKey = self.ref.child("messages").child(convo.key).childByAutoId().key
        let message = Message(key: messageKey, sender: uid, message: messageText, timestamp: timestamp)
        saveMessage(convo.key, message: message)
        
        // Sender updates
        var _convo = convo
        _convo.message = "you: " + messageText
        _convo.timestamp = timestamp
        _convo.leftConvo = false
        updateConvo(_convo)
        updateProxyConvo(_convo)
        updateProxy(convo.senderId, proxy: convo.senderProxy, timestamp: timestamp)
        incrementMessagesSent(convo.senderId)
        
        // Receiver updates
        if !convo.receiverDeletedProxy && !convo.receiverIsBlocking {
            incrementUnread(convo.receiverId)
            updateProxyIncludingUnread(convo.receiverId, proxy: convo.receiverProxy, timestamp: timestamp)
        }
        
        if !convo.receiverDeletedProxy {
            updateConvo(convo.receiverId, convo: convo.key, message: messageText, timestamp: timestamp)
            updateProxyConvo(convo.receiverProxy, convo: convo.key, message: messageText, timestamp: timestamp)
            incrementMessagesReceived(convo.receiverId)
        }
        
        completion(convo: _convo)
    }
    
    // MARK: Helper functions for writing to database
    
    func saveMessage(convo: String, message: Message) {
        ref.child("messages").child(convo).child(message.key).setValue(message.toAnyObject())
    }
    
    func updateConvo(convo: Convo) {
        ref.child("convos").child(convo.senderId).child(convo.key).setValue(convo.toAnyObject())
    }
    
    func updateConvo(id: String, convo: String, message: String, timestamp: Double) {
        self.ref.child("convos").child(id).child(convo).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if var convo = currentData.value as? [String: AnyObject] {
                let unread = convo["unread"] as? Int ?? 0
                convo["unread"] = unread + 1
                convo["message"] = message
                convo["timestamp"] = timestamp
                convo["leftConvo"] = false
                currentData.value = convo
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        })
    }
    
    func updateProxyConvo(convo: Convo) {
        ref.child("convos").child(convo.senderProxy).child(convo.key).setValue(convo.toAnyObject())
    }
    
    func updateProxyConvo(proxy: String, convo: String, message: String, timestamp: Double) {
        self.ref.child("convos").child(proxy).child(convo).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if var convo = currentData.value as? [String: AnyObject] {
                let unread = convo["unread"] as? Int ?? 0
                convo["unread"] = unread + 1
                convo["message"] = message
                convo["timestamp"] = timestamp
                convo["leftConvo"] = false
                currentData.value = convo
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        })
    }
    
    func updateProxy(id: String, proxy: String, timestamp: Double) {
        ref.child("proxies").child(id).child(proxy).child("timestamp").setValue(timestamp)
    }
    
    func updateProxyIncludingUnread(id: String, proxy: String, timestamp: Double) {
        self.ref.child("proxies").child(id).child(proxy).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
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
    
    func incremementProxiesInteractedWith(id: String) {
        self.ref.child("proxiesInteractedWith").child(id).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if let count = currentData.value {
                let _count = count as? Int ?? 0
                currentData.value = _count + 1
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        })
    }
    
    func incrementMessagesSent(id: String) {
        self.ref.child("messagesSent").child(id).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if let count = currentData.value {
                let _count = count as? Int ?? 0
                currentData.value = _count + 1
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        })
    }
    
    func incrementMessagesReceived(id: String) {
        self.ref.child("messagesReceived").child(id).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if let count = currentData.value {
                let _count = count as? Int ?? 0
                currentData.value = _count + 1
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        })
    }
    
    func incrementUnread(id: String) {
        self.ref.child("unread").child(id).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
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
    func updateConvoNickname(convo: Convo, nickname: String) {
        ref.updateChildValues([
            // User's copy of convo
            "users/\(uid)/convos/\(convo.key)/convoNickname": nickname,
            
            // The convo saved by proxy
            "convos/\(convo.senderProxy)/\(convo.key)/convoNickname": nickname])
    }
    
    /// Decrements user, convo, proxy convo, and proxy unread by `amount`.
    func decrementAllUnreadFor(convo: Convo, amount: Int) {
        // User
        self.ref.child("unread").child(convo.senderId).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if let unread = currentData.value {
                let _unread = unread as? Int ?? 0
                currentData.value = _unread - amount
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        })
        
        // Convo
        self.ref.child("convos").child(convo.senderId).child(convo.key).child("unread").runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if let unread = currentData.value {
                let _unread = unread as? Int ?? 0
                currentData.value = _unread - amount
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        })
        
        // Proxy convo
        self.ref.child("convos").child(convo.senderProxy).child(convo.key).child("unread").runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if let unread = currentData.value {
                let _unread = unread as? Int ?? 0
                currentData.value = _unread - amount
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        })
        
        // Proxy
        self.ref.child("proxies").child(convo.senderId).child(convo.senderProxy).child("unread").runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if let unread = currentData.value {
                let _unread = unread as? Int ?? 0
                currentData.value = _unread - amount
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        })
    }
    
    func decrementUnreadForUser(id: String, amount: Int) {
        self.ref.child("unread").child(id).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
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