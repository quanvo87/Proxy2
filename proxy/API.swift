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
    
    let ref = FIRDatabase.database().reference()
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
    
    private init() {}
    
    deinit {
        iconsRef.removeObserverWithHandle(iconsRefHandle)
    }
    
    
    // MARK: - The Proxy
    
    
    // TODO: - Controllers that pull proxies must add checks to determine if they will display them
    
    /**
     # Creating The Proxy
     
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
     their -ing form to the list of adjectives (ie runningDog89). I don't know
     the term for this I'm a CS major.
     
     To create a proxy, we first must make sure the word bank is loaded. If it's
     not, load it from the database, cache it, then proceed. If it's already
     loaded, we proceed as usual.
     
     The next step after that is to go ahead and create and write a proxy. Our
     ProxyNameGenerator struct handles the randomization for us. Once it's
     created, we request from the database all proxies with this name. Nodes are
     indexed by name to help with search performance. If there is only one, it
     will be the one you just created, and you can have that proxy. The
     appropriate controllers are notified. If there is more than one, you tried
     creating a proxy that already existed and we delete the one you just made
     and try again.
     
     In addition, proxies are given a random icon (actually a path to the icon
     in our online storage) based on the icons the user has unlocked.
     */
    func createProxy(completion: (proxy: Proxy?) -> Void) {
        creatingProxy = true
        if wordsLoaded {
            tryCreateProxy({ (proxy) in
                completion(proxy: proxy)
            })
        } else {
            loadWords({ (proxy) in
                completion(proxy: proxy)
            })
        }
    }
    
    /**
     Load our word bank from our database, cache it, and then call
     tryCreateProxy().
     */
    func loadWords(completion: (proxy: Proxy?) -> Void) {
        ref.child("wordbank").observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            if let words = snapshot.value, let adjectives = words["adjectives"], let nouns = words["nouns"] {
                self.proxyNameGenerator.adjs = adjectives as! [String]
                self.proxyNameGenerator.nouns = nouns as! [String]
                self.wordsLoaded = true
                self.tryCreateProxy({ (proxy) in
                    completion(proxy: proxy)
                })
            }
        })
    }
    
    /**
     Attempts to create a unique proxy. We must first get a unique key from 
     Firebase to create the test proxy. We call this 'globalKey'. Then we 
     generate a proxy name with our proxyNameGenerator and assign it to 'key'.
     We then query our database for any proxies with the same 'key'. If we've 
     only found one, then it will be the one we just created, so we've 
     successfully created a unique proxy. At this point on, we can use 'key' as
     the proxy's unique identifier in the database as well as it's name. We only
     need the 'globalKey' again when we go to delete the proxy from the global
     node of all proxies in the database. We also assign a random icon from the
     user's array of available icons on success.
     
     On failure, deletes the proxy it just created and tries again. Will exit if
     the user cancels the CreateNewProxy view.
     */
    func tryCreateProxy(completion: (proxy: Proxy?) -> Void) {
        let globalKey = ref.child("proxies").childByAutoId().key
        let key = proxyNameGenerator.generateProxyName()
        var proxy = Proxy(globalKey: globalKey, key: key)
        ref.child("proxies").child(globalKey).setValue(proxy.toAnyObject())
        ref.child("proxies").queryOrderedByChild("key").queryEqualToValue(key).observeSingleEventOfType(.Value, withBlock: { snapshot in
            if snapshot.childrenCount == 1 {
                proxy.icon = self.getRandomIcon()
                self.creatingProxy = false
                completion(proxy: proxy)
            } else {
                self.deleteProxy(proxy)
                if self.creatingProxy {
                    self.tryCreateProxy({ (proxy) in
                        completion(proxy: proxy)
                    })
                } else {
                    completion(proxy: nil)
                }
            }
        })
    }
    
    /// Observe the icons the user has unlocked
    func observeIcons() {
        iconsRef = ref.child("users").child(uid).child("icons")
        iconsRefHandle = iconsRef.observeEventType(.Value, withBlock: { (snapshot) in
            if let icons = snapshot.value?.allKeys as? [String] {
                self.icons = icons
            }
        })
    }
    
    /// Get a random icon path from the user's available icons
    func getRandomIcon() -> String {
        let count = UInt32(icons.count)
        return icons[Int(arc4random_uniform(count))]
    }
    
    /// We must be sure to delete the old proxy when we reroll for a new one
    func rerollProxy(oldProxy: Proxy, completion: (proxy: Proxy?) -> Void) {
        deleteProxy(oldProxy)
        tryCreateProxy { (proxy) in
            completion(proxy: proxy)
        }
    }
    
    /// Deletes the proxy in the global proxy list
    func deleteProxy(proxy: Proxy) {
        ref.child("proxies").child(proxy.globalKey).removeValue()
    }
    
    /**
     The creatingProxy Bool is there in case the user taps cancel on the
     CreateNewProxy view while the API is currently trying to create a proxy.
     When creatingProxy is false, the proxy creation loop eventually stops.
     */
    func cancelCreateProxy(proxy: Proxy) {
        creatingProxy = false
        deleteProxy(proxy)
    }
    
    /*
     At this point on, we use the proxy's name as it's key in the database.
     We know it will be unique and this makes it easier to recall the proxy in
     later operations.
     */
    func saveProxyWithNickname(proxy: Proxy, nickname: String) {
        var _proxy = proxy
        let timestamp = NSDate().timeIntervalSince1970
        _proxy.nickname = nickname
        _proxy.timestamp = timestamp
        ref.child("users").child(uid).child("proxies").child(proxy.key).setValue(_proxy.toAnyObject())
        ref.child("proxies").child(proxy.globalKey).setValue(_proxy.toAnyObject())
    }
    
    /// Update the proxy's nickname in the required places
    func updateProxyNickname(proxy: Proxy, convos: [Convo], nickname: String) {
        
        /// In the user's node
        ref.child("users").child(proxy.owner).child("proxies").child(proxy.key).child("nickname").setValue(nickname)
        
        /// For each convo the proxy is in
        for convo in convos {
            ref.updateChildValues([
                "/users/\(proxy.owner)/convos/\(convo.key)/proxyNickname": nickname,
                "/convos/\(proxy.key)/\(convo.key)/proxyNickname": nickname])
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
            leaveConvo(proxy.key, convo: convo)
        }
        
        // Delete the proxy from the global list of used proxies
        ref.child("proxies").child(proxy.key).removeValue()
        
        // Delete the proxy from the user's node
        ref.child("users").child(uid).child("proxies").child(proxy.key).removeValue()
    }
    
    // Retrieve a user's proxy from its name. The proxy is passed back to the
    // user upon success.
    func getProxyWithName(name: String, completion: (success: Bool, proxy: Proxy) -> Void) {
        ref.child("users").child(uid).child("proxies").queryOrderedByChild("name").queryEqualToValue(name).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
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
     Server side error checking before sending it off to the message sender
     function.
     */
    func sendMessage(senderProxy: Proxy, receiverProxyName: String, message: String, completion: (error: ErrorAlert?, convo: Convo?) -> Void ) {
        
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
            self.ref.child("users").child(senderProxy.owner).child("convos").queryEqualToValue(convoKey).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                
                /// Existing convo found. Use it to send the message.
                if snapshot.childrenCount == 1 {
                    let convo = Convo(anyObject: snapshot.value!)
                    self.sendMessage(convo, messageText: message, completion: { (convo) -> Void in
                        completion(error: nil, convo: convo)
                        return
                    })
                }
                
                // No convo found, must set up convo before sending message
                self.setupFirstMessage(senderProxy, receiverProxy: receiverProxy, convoKey: convoKey, message: message, completion: { (convo) in
                    completion(error: nil, convo: convo)
                })
            })
        })
    }
    
    /*
     # Sending The First Message Between Two Proxies
     
     Create a different convo struct for each user and save it at the required
     locations. A convo holds all the needed info to send a message.
     
     We also must pull the receiver's users/uid/blocked and see if we the
     sender's uid is on that list.
     
     Increment both user's 'Proxies Interacted With'.
     
     Then send off the sender's version of the convo and the messageText to the
     message sending function to finish the job.
     */
    func setupFirstMessage(senderProxy: Proxy, receiverProxy: Proxy, convoKey: String, message: String, completion: (convo: Convo) -> Void) {
        
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
    
    /*
     # Sending A Message
     
     We must update/save:
     
     sender's side:
     
     - convo last message and timestamp
     - proxy/convo last message and timestamp
     - proxy timestamp
     - 'Messages Sent' incremented
     
     receiver's side:
     
     if !receiverDeletedProxy && !receiverBlocking
     - unread
     
     if !receiverDeletedProxy
     - convo
     - proxy convo
     - proxy
     - 'Messages Received'*
     
     * Note: This means you can see when people you have blocked are still
     sending you messages, because your 'Messages Received' goes up.
     
     neutral side:
     
     - the actual message
     - set 'leftConvo' to false for both users
     */
    func sendMessage(convo: Convo, messageText: String, completion: (convo: Convo) -> Void) {
        
        let timestamp = NSDate().timeIntervalSince1970
        
        let messageKey = self.ref.child("messages").child(convo.key).childByAutoId().key
        let message = Message(key: messageKey, sender: uid, message: messageText, timestamp: timestamp)
        writeMessage(convo.key, message: message)
        
        /// Sender updates
        var _convo = convo
        _convo.message = "you: " + messageText
        _convo.timestamp = timestamp
        _convo.leftConvo = false
        updateConvo(_convo)
        updateProxyConvo(_convo)
        updateProxyTimestamp(convo.senderId, proxy: convo.senderProxy, timestamp: timestamp)
        incrementMessagesSent(convo.senderId)
        
        /// Receiver updates
        if !convo.receiverDeletedProxy && !convo.receiverIsBlocking {
            incrementUnread(convo.receiverId)
        }
        
        if !convo.receiverDeletedProxy {
            updateConvo(convo.receiverId, convo: convo.key, message: messageText, timestamp: timestamp)
            updateProxyConvo(convo.receiverProxy, convo: convo.key, message: messageText, timestamp: timestamp)
            updateProxyTimestamp(convo.receiverId, proxy: convo.receiverProxy, timestamp: timestamp)
            incrementMessagesReceived(convo.receiverId)
        }
        
        completion(convo: _convo)
    }
    
    
    // MARK: Helper functions for writing to database
    
    
    func writeMessage(convo: String, message: Message) {
        ref.child("messages").child(convo).child(message.key).setValue(message.toAnyObject())
    }
    
    func updateConvo(convo: Convo) {
        ref.child("users").child(convo.senderId).child("convos").child(convo.key).setValue(convo.toAnyObject())
    }
    
    func updateConvo(id: String, convo: String, message: String, timestamp: Double) {
        self.ref.child("users").child(id).child("convos").child(convo).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
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
    
    func updateProxyTimestamp(id: String, proxy: String, timestamp: Double) {
        ref.child("users").child(id).child("proxies").child(proxy).child("timestamp").setValue(timestamp)
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
        self.ref.child("users").child(id).child("unread").runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if let unread = currentData.value {
                let _unread = unread as? Int ?? 0
                currentData.value = _unread + 1
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        })
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
     your global unread by that convo's unread.
     
     Then delete that user's entry in your /blocked/uid/blockedUserId.
     */
    // TODO: Implement
    func blockUser() {}
}