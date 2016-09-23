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
import AVFoundation

class API {
    
    static let sharedInstance = API()
    
    let ref = FIRDatabase.database().reference()
    let storageRef = FIRStorage.storage().referenceForURL(URLs.Storage)
    
    var proxyNameGenerator = ProxyNameGenerator()
    var isCreatingProxy = false
    
    var iconsRefHandle = FIRDatabaseHandle()
    var icons = [String]()
    var iconURLCache = [String: NSURL]()
    
    var uid: String = "" {
        didSet {
            observeIcons()
        }
    }
    
    private init() {}
    
    deinit {
        ref.child("icons").child(uid).removeObserverWithHandle(iconsRefHandle)
    }
    
    // MARK: - Utility
    /// Saves `anyObject` under `itemType`/`parent`/`child`/`grandchild`.
    /// Leave unneeded nodes blank starting from grandchild, working back to parent.
    func set(anyObject anyObject: AnyObject, itemType: String, parent: String, child: String, grandchild: String) {
        
        if parent != "" && child == "" && grandchild == "" {
            ref.child(itemType).child(parent).setValue(anyObject)
            return
        }
        
        if parent != "" && child != "" && grandchild == "" {
            ref.child(itemType).child(parent).child(child).setValue(anyObject)
            return
        }
        
        if parent != "" && child != "" && grandchild != "" {
            ref.child(itemType).child(parent).child(child).child(grandchild).setValue(anyObject)
        }
    }
    
    /// Deletes object under `itemType`/`parent`/`child`/`grandchild`.
    /// Leave unneeded nodes blank starting from grandchild, working back to parent.
    func delete(itemType: String, parent: String, child: String, grandchild: String) {
        
        if parent != "" && child == "" && grandchild == "" {
            ref.child(itemType).child(parent).removeValue()
            return
        }
        
        if parent != "" && child != "" && grandchild == "" {
            ref.child(itemType).child(parent).child(child).removeValue()
            return
        }
        
        if parent != "" && child != "" && grandchild != "" {
            ref.child(itemType).child(parent).child(child).child(grandchild).removeValue()
        }
    }
    
    /// Returns the UIImage for a url.
    func getImage(fromURL url: NSURL, completion: (image: UIImage) -> Void) {
        guard let urlString = url.absoluteString else { return }
        
        // Check cache first.
        KingfisherManager.sharedManager.cache.retrieveImageForKey(urlString, options: nil) { (image, cacheType) -> () in
            if let image = image {
                completion(image: image)
                return
            }
        
            // Not in cache, retrieve online.
            KingfisherManager.sharedManager.downloader.downloadImageWithURL(url, progressBlock: nil) { (image, error, imageURL, originalData) -> () in
                if let image = image {
                    KingfisherManager.sharedManager.cache.storeImage(image, forKey: urlString, toDisk: true, completionHandler: nil)
                    completion(image: image)
                }
            }
        }
    }
    
    /// Uploads compressed version of video to storage.
    /// Returns url to the video in storage.
    func uploadVideo(fromURL url: NSURL, completion: (url: NSURL) -> Void) {
        
        /// Compress video.
        let compressedURL = NSURL.fileURLWithPath(NSTemporaryDirectory() + NSUUID().UUIDString + ".m4v")
        compressVideo(fromURL: url, toURL: compressedURL) { (session) in
            if session.status == .Completed {
                
                /// Upload to storage.
                self.storageRef.child("userFiles").child(String(NSDate().timeIntervalSince1970)).putFile(compressedURL, metadata: nil) { metadata, error in
                    guard let url = metadata?.downloadURL() else { return }
                    completion(url: url)
                }
            }
        }
    }
    
    /// Compresses a video. Returns the export session.
    func compressVideo(fromURL url: NSURL, toURL outputURL: NSURL, handler: (session: AVAssetExportSession) -> Void) {
        let urlAsset = AVURLAsset(URL: url, options: nil)
        if let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPresetMediumQuality) {
            exportSession.outputURL = outputURL
            exportSession.outputFileType = AVFileTypeQuickTimeMovie
            exportSession.shouldOptimizeForNetworkUse = true
            exportSession.exportAsynchronouslyWithCompletionHandler { () -> Void in
                handler(session: exportSession)
            }
        }
    }
    
    /// Uploads compressed version of image to storage.
    /// Returns url to the image in storage.
    func upload(image: UIImage, completion: (url: NSURL) -> Void) {
        guard let data = UIImageJPEGRepresentation(image, 0) else { return }
        storageRef.child("userFiles").child(String(NSDate().timeIntervalSince1970)).putData(data, metadata: nil) { (metadata, error) in
            guard let url = metadata?.downloadURL() else { return }
            completion(url: url)
            guard let urlString = url.absoluteString else { return }
            KingfisherManager.sharedManager.cache.storeImage(image, forKey: urlString, toDisk: true, completionHandler: nil)
        }
    }
    
    // MARK: - User
    /// Gives a user access to the default icons.
    func setDefaultIcons(forUser user: String) {
        let defaultIcons = DefaultIcons(id: user).defaultIcons
        ref.updateChildValues(defaultIcons as! [NSObject : AnyObject])
    }
    
    /// Increments a user's `proxiesInteractedWith`.
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
    
    /// Increments a user's `messagesSent`.
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
    
    /// Increments a user's `messagesReceived`.
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
    
    /// Increments a user's `unread` by `amount`.
    func incrementUnread(forUser user: String, byAmount amount: Int) {
        self.ref.child("unread").child(user).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if let unread = currentData.value {
                let _unread = unread as? Int ?? 0
                currentData.value = _unread + amount
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        })
    }
    
    /// Derements a user's `unread` by `amount`.
    func decrementUnread(forUser user: String, byAmount amount: Int) {
        ref.child("unread").child(user).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if let unread = currentData.value {
                var _unread = unread as? Int ?? 0
                _unread -= amount
                currentData.value = _unread > -1 ? _unread : 0
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        })
    }
    
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
    
    // MARK: - Proxy
    /// Loads word bank if needed, else call `tryCreateProxy`.
    func create(proxy completion: (proxy: Proxy) -> Void) {
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
    
    /// Loads and caches the `proxyNameGenerator`.
    /// Calls `tryCreateProxy` when done.
    func load(proxyNameGenerator completion: (proxy: Proxy) -> Void) {
        ref.child("wordbank").observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            if let words = snapshot.value, let adjs = words["adjectives"], let nouns = words["nouns"] {
                self.proxyNameGenerator.adjs = adjs as! [String]
                self.proxyNameGenerator.nouns = nouns as! [String]
                self.proxyNameGenerator.isLoaded = true
                self.tryCreating(proxy: { (proxy) in
                    completion(proxy: proxy)
                })
            }
        })
    }
    
    /// Returns a proxy with a randomly generated, unique name.
    func tryCreating(proxy completion: (proxy: Proxy) -> Void) {
        
        /// Create a proxy and save it.
        let key = ref.child("proxies").childByAutoId().key
        let name = proxyNameGenerator.generateProxyName()
        let proxy = Proxy(key: key, name: name, ownerId: "", timeCreated: 0.0)
        ref.child("proxies").child(key).setValue(proxy.toAnyObject())
        
        /// Get all proxies with this name.
        ref.child("proxies").queryOrderedByChild("name").queryEqualToValue(name).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            
            /// If there's only one, it's the one you just created and you're done.
            if snapshot.childrenCount == 1 {
                
                /// Stop trying to create a proxy.
                self.isCreatingProxy = false
                
                /// Create the user's copy of the proxy and save it.
                let proxy = Proxy(key: key, name: name, ownerId: self.uid, timeCreated: NSDate().timeIntervalSince1970)
                self.ref.child("proxies").child(self.uid).child(key).setValue(proxy.toAnyObject())
                
                /// Give the proxy a random icon.
                self.ref.child("icons").child(name).setValue(self.getRandomIcon())
                
                completion(proxy: proxy)
                return
            }
            
            /// Else delete the proxy you just created.
            self.delete(globalProxy: proxy)
            
            /// Check if user has cancelled the process.
            if self.isCreatingProxy {
                
                /// Try the process again.
                self.tryCreating(proxy: { (proxy) in
                    completion(proxy: proxy)
                })
            }
        })
    }
    
    /// Keeps an up-to-date list of the icons the user has unlocked.
    /// These are Strings of the icon names used to build urls to the files in storage.
    func observeIcons() {
        iconsRefHandle = ref.child("icons").child(uid).observeEventType(.Value, withBlock: { (snapshot) in
            var icons = [String]()
            for child in snapshot.children {
                icons.append(child.value["name"] as! String)
            }
            self.icons = icons
        })
    }
    
    /// Returns a random icon name from the user's available icons.
    func getRandomIcon() -> String {
        let count = UInt32(icons.count)
        return icons[Int(arc4random_uniform(count))]
    }
    
    /// Deletes the given `proxy` and returns a new one.
    func reroll(proxy: Proxy, completion: (proxy: Proxy) -> Void) {
        delete(globalProxy: proxy)
        tryCreating(proxy: { (proxy) in
            completion(proxy: proxy)
        })
    }
    
    /// Deletes the newly created `proxy` being checked for uniqueness.
    /// Notifies API to stop trying to create a proxy.
    func cancelCreating(proxy: Proxy) {
        delete(globalProxy: proxy)
        isCreatingProxy = false
    }
    
    /// Returns the Proxy with `key` belonging to `user`.
    func getProxy(withKey key: String, belongingToUser user: String, completion: (proxy: Proxy) -> Void) {
        ref.child("proxies").child(user).child(key).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            completion(proxy: Proxy(anyObject: snapshot.value!))
        })
    }
    
    /// Returns the NSURL of an icon's url in storage.
    func getURL(forIcon icon: String, completion: (url: NSURL) -> Void) {
        
        /// Check cache first.
        if let url = iconURLCache[icon] {
            completion(url: url)
        
        /// Else get url from storage.
        } else {
            let iconRef = storageRef.child("icons").child("\(icon).png")
            iconRef.downloadURLWithCompletion { (url, error) -> Void in
                guard error == nil,
                    let url = url
                    else { return }
                self.iconURLCache[icon] = url
                completion(url: url)
            }
        }
    }
    
    /// Returns the UIImage for an icon.
    func getUIImage(forIcon icon: String, completion: (image: UIImage) -> Void) {
        
        /// Get url for icon in storage.
        getURL(forIcon: icon, completion: { (url) in
            
            /// Get image from url.
            self.getImage(fromURL: url, completion: { (image) in
                completion(image: image)
            })
        })
    }
    
    /// Sets a proxy's nickname to `nickname`.
    func set(nickname nickname: String, forProxy proxy: String) {
        ref.child("nicknames").child(proxy).setValue(nickname)
    }
    
    /// Sets a proxy's icon to `icon`.
    func set(icon icon: String, forProxy proxy: String) {
        ref.child("icons").child(proxy).setValue(icon)
    }
    
    /// Sets a proxy's timestamp to `timestamp`.
    func set(timestamp timestamp: Double, forProxy proxy: String, belongingTo user: String) {
        ref.child("proxies").child(user).child(proxy).child("timestamp").setValue(timestamp)
    }
    
    /// Increments a proxy's unread by `amount`.
    func incrementUnread(forProxy proxy: String, byAmount amount: Int) {
        self.ref.child("unread").child(proxy).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if let unread = currentData.value {
                let _unread = unread as? Int ?? 0
                currentData.value = _unread + amount
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        })
    }
    
    /// Decrements a proxy's unread by `amount`.
    func decrementUnread(forProxy proxy: String, byAmount amount: Int) {
        self.ref.child("unread").child(proxy).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if let unread = currentData.value {
                var _unread = unread as? Int ?? 0
                _unread -= amount
                currentData.value = _unread > -1 ? _unread : 0
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        })
    }
    
    /// Deletes the global copy of a proxy.
    func delete(globalProxy proxy: Proxy) {
        ref.child("proxies").child(proxy.key).removeValue()
    }
    
    /// Deletes a proxy and it's side of the convos it's in.
    func delete(proxy: Proxy) {
        getConvos(forProxy: proxy) { (convos) in
            self.delete(proxy: proxy, withConvos: convos)
        }
    }
    
    /// Returns the convos that a proxy is in.
    func getConvos(forProxy proxy: Proxy, completion: (convos: [Convo]) -> Void) {
        ref.child("convos").child(proxy.key).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            var convos = [Convo]()
            for child in snapshot.children {
                let convo = Convo(anyObject: child.value)
                convos.append(convo)
            }
            completion(convos: convos)
        })
    }
    
    /// Deletes a proxy's user and global copy.
    /// Deletes all sender side convos under that proxy.
    /// Notifies all receivers of those convos that this proxy has been deleted.
    /// (The actual receiver is not notified.)
    /// Decrement's user's unread by the remaining unread in the proxy.
    /// Deletes proxy's icon, nickname, and unread entries.
    func delete(proxy proxy: Proxy, withConvos convos: [Convo]) {
        
        /// Loop through all convos this proxy is in
        for convo in convos {
            
            /// Notify receivers in convos that this proxy is deleted
            set(receiverDeletedProxy: true, forConvo: convo.key, underParent: convo.receiverId)
            set(receiverDeletedProxy: true, forConvo: convo.key, underParent: convo.receiverProxy)
            
            /// Delete the convos on the sender's side
            delete(convo: convo.key, underParent: convo.senderId)
            delete(convo: convo.key, underParent: convo.senderProxy)
            
            /// Delete convo's metadata
            delete(item: "nicknames", forKey: convo.key, withParent: convo.senderId)
            delete(item: "unread", forKey: convo.key, withParent: convo.senderId)
        }
        
        /// Delete the global copy of the proxy
        delete(globalProxy: proxy)
        
        /// Delete the user's copy of the proxy
        ref.child("proxies").child(uid).child(proxy.key).removeValue()
        
        /// Delete icon
        delete(item: "icons", forKey: proxy.key)
        
        /// Delete nickname
        delete(item: "nicknames", forKey: proxy.key)
        
        /// Get unread
        ref.child("unread").child(proxy.key).observeEventType(.Value, withBlock: { (snapshot) in
            guard let unread = snapshot.value as? Int else { return }
            
            /// Decrement user's unread by proxy's unread
            self.decrementUnread(forUser: proxy.ownerId, byAmount: unread)
            
            /// Delete unread
            self.delete(item: "unread", forKey: proxy.key)
        })
    }
    
    /// Deletes metadata at the path built from parameters.
    func delete(item item: String, forKey key: String) {
        ref.child(item).child(key).removeValue()
    }
    
    /// Deletes metadata at the path built from parameters that requires a parent.
    func delete(item item: String, forKey key: String, withParent parent: String) {
        ref.child(item).child(parent).child(key).removeValue()
    }
    
    // MARK: - Message
    /// Error checks before sending it off to the appropriate message sending fuction.
    /// Returns the sender's convo and the message on success.
    /// Returns an ErrorAlert on failure.
    func sendMessage(fromSenderProxy senderProxy: Proxy, toReceiverProxyName receiverProxyName: String, withText text: String, withMediaType mediaType: String, completion: (error: ErrorAlert?, convo: Convo?, message: Message?) -> Void ) {
        
        /// Check if receiver exists
        self.ref.child("proxies").queryOrderedByChild("name").queryEqualToValue(receiverProxyName).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            guard snapshot.childrenCount == 1 else {
                completion(error: ErrorAlert(title: "Recipient Not Found", message: "Perhaps there was a spelling error?"), convo: nil, message: nil)
                return
            }
            
            /// Check if sender is trying to send to him/herself
            let receiverProxy = Proxy(anyObject: snapshot.value!)
            guard senderProxy.ownerId != receiverProxy.ownerId else {
                completion(error: ErrorAlert(title: "Cannot Send To Self", message: "Did you enter yourself as a recipient by mistake?"), convo: nil, message: nil)
                return
            }
            
            /// Build convo key from sorting and concatenizing the proxy names
            let convoKey = [senderProxy.key, receiverProxy.key].sort().joinWithSeparator("")
            
            /// Check if existing convo between the proxies exists
            self.ref.child("convos").child(senderProxy.ownerId).queryEqualToValue(convoKey).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                
                /// Existing convo found, use it to send the message
                if snapshot.childrenCount == 1 {
                    let convo = Convo(anyObject: snapshot.value!)
                    self.sendMessage(withText: text, withMediaType: mediaType, usingSenderConvo: convo, completion: { (convo, message) in
                        completion(error: nil, convo: convo, message: message)
                    })
                }
                
                /// No convo found, must set up convo before sending message
                self.setUpFirstMessage(fromSenderProxy: senderProxy, toReceiverProxy: receiverProxy, usingConvoKey: convoKey, withText: text, withMediaType: mediaType, completion: { (convo, message) in
                    completion(error: nil, convo: convo, message: message)
                })
            })
        })
    }
    
    /// Creates a different convo struct for each user.
    /// Checks if sender is blocked by receiver.
    /// Saves the convo structs.
    /// Increments both users' `proxiesInteractedWith`.
    /// Sends off to `sendMessage`.
    /// Returns updated sender's `convo` and the message.
    func setUpFirstMessage(fromSenderProxy senderProxy: Proxy, toReceiverProxy receiverProxy: Proxy, usingConvoKey convoKey: String, withText text: String, withMediaType mediaType: String, completion: (convo: Convo, message: Message) -> Void) {
        
        /// Check if sender is in receiver's blocked list
        ref.child("blocked").child(receiverProxy.ownerId).child(senderProxy.ownerId).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            
            let senderBlocked = snapshot.childrenCount == 1
            
            var senderConvo = Convo()
            senderConvo.key = convoKey
            var receiverConvo = senderConvo
            
            senderConvo.senderId = senderProxy.ownerId
            senderConvo.senderProxy = senderProxy.key
            senderConvo.receiverId = receiverProxy.ownerId
            senderConvo.receiverProxy = receiverProxy.key
            senderConvo.receiverIsBlocking = senderBlocked
            let senderConvoAnyObject = senderConvo.toAnyObject()
            self.set(anyObject: senderConvoAnyObject, itemType: "convos", parent: senderConvo.senderId, child: senderConvo.key, grandchild: "")
            self.set(anyObject: senderConvoAnyObject, itemType: "convos", parent: senderConvo.senderProxy, child: senderConvo.key, grandchild: "")
            self.incremementProxiesInteractedWith(forUser: senderProxy.ownerId)
            
            receiverConvo.senderId = receiverProxy.ownerId
            receiverConvo.senderProxy = receiverProxy.key
            receiverConvo.receiverId = senderProxy.ownerId
            receiverConvo.receiverProxy = senderProxy.key
            receiverConvo.senderIsBlocking = senderBlocked
            let receiverConvoAnyObject = receiverConvo.toAnyObject()
            self.set(anyObject: receiverConvoAnyObject, itemType: "convos", parent: receiverConvo.senderId, child: receiverConvo.key, grandchild: "")
            self.set(anyObject: receiverConvoAnyObject, itemType: "convos", parent: receiverConvo.senderProxy, child: receiverConvo.key, grandchild: "")
            self.incremementProxiesInteractedWith(forUser: receiverProxy.ownerId)
            
            self.sendMessage(withText: text, withMediaType: mediaType, usingSenderConvo: senderConvo, completion: { (convo, message) in
                completion(convo: convo, message: message)
            })
        })
    }
    
    /// Updates/writes:
    ///     - sender `convo`
    ///     - sender proxy `convo`
    ///     - sender `proxy`
    ///     - sender `messagesSent`
    ///
    ///     if !convo.receiverDeletedProxy && !convo.receiverIsBlocking && !
    ///     - receiver `unread`
    ///     - receiver `proxy`
    ///
    ///     if !convo.receiverDeletedProxy
    ///     - receiver `convo`
    ///     - receiver proxy `convo`
    ///     - receiver `messagesReceived`
    ///
    ///     if receiver present
    ///     - set message to read
    ///     - set unread increment to 0
    ///
    ///     - message
    ///
    /// Returns the sender's convo and the message.
    func sendMessage(withText text: String, withMediaType mediaType: String, usingSenderConvo convo: Convo, completion: (convo: Convo, message: Message) -> Void) {
        userIsPresent(user: convo.receiverId, convo: convo.key) { (receiverIsPresent) in
            let increment = receiverIsPresent ? 0 : 1
            let timestamp = NSDate().timeIntervalSince1970
            
            /// Sender updates
            self.setConvoValuesOnMessageSend(message: "You: \(text)", timestamp: timestamp, id: convo.senderId, proxy: convo.senderProxy, convo: convo.key)
            self.incrementMessagesSent(forUser: convo.senderId)
            
            /// Receiver updates
            if !convo.receiverDeletedProxy && !convo.receiverIsBlocking {
                self.incrementUnread(forUser: convo.receiverId, byAmount: increment)
                self.update(proxy: convo.receiverProxy, forUser: convo.receiverId, withUnreadIncrement: increment, withTimestamp: timestamp)
            }
            
            if !convo.receiverDeletedProxy {
                self.setConvoValuesOnMessageSend(message: text, timestamp: timestamp, id: convo.receiverId, proxy: convo.receiverProxy, convo: convo.key)
                self.incrementMessagesReceived(forUser: convo.receiverId)
            }
            
            /// Write message
            let messageKey = self.ref.child("messages").child(convo.key).childByAutoId().key
            let timeRead = receiverIsPresent ? timestamp : 0.0
            let message = Message(key: messageKey, convo: convo.key, mediaType: mediaType, read: receiverIsPresent, timeRead: timeRead, senderId: convo.senderId, date: timestamp, text: text)
            self.set(anyObject: message.toAnyObject(), itemType: "messages", parent: convo.key, child: messageKey, grandchild: "")
            
            completion(convo: _convo, message: message)
        }
    }
    
    /// Sets various user convo values when sending a message.
    func setConvoValuesOnMessageSend(message message: String, timestamp: Double, id: String, proxy: String, convo: String) {
        self.set(anyObject: message, itemType: "lastMessage", parent: id, child: convo, grandchild: "")
        self.set(anyObject: timestamp, itemType: "convos", parent: id, child: convo, grandchild: "timestamp")
        self.set(anyObject: timestamp, itemType: "convos", parent: proxy, child: convo, grandchild: "timestamp")
        self.set(anyObject: false, itemType: "convos", parent: id, child: convo, grandchild: "didLeaveConvo")
        self.set(anyObject: false, itemType: "convos", parent: proxy, child: convo, grandchild: "didLeaveConvo")
    }
    
    /// Returns a Bool indicating whether or not a user is in a convo.
    func userIsPresent(user user: String, convo: String, completion: (userIsPresent: Bool) -> Void) {
        ref.child("present").child(convo).child(user).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            completion(userIsPresent: snapshot.value as? Bool ?? false)
        })
    }
    
    /// Sets the message's `read` to true and gives it a current `timeRead`.
    func setRead(forMessage message: Message) {
        ref.child("messages").child(message.convo).child(message.key).child("read").setValue(true)
        ref.child("messages").child(message.convo).child(message.key).child("timeRead").setValue(NSDate().timeIntervalSince1970)
    }
    
    /// Sets a message's `mediaType` and `mediaURL`.
    func setMedia(forMessage message: Message, mediaType: String, mediaURL: String) {
        ref.child("messages").child(message.convo).child(message.key).child("mediaType").setValue(mediaType)
        ref.child("messages").child(message.convo).child(message.key).child("mediaURL").setValue(mediaURL)
    }
    
    // TODO: what is this used for?
    /// Return the message with the corresponding key.
    func getMessage(withKey messageKey: String, inConvo convoKey: String, completion: (message: Message) -> Void) {
        ref.child("messages").child(convoKey).child(messageKey).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            completion(message: Message(anyObject: snapshot.value!))
        })
    }
    
    // MARK: - Conversation (Convo)
    /// Sets a convo's `lastMessage`.
    func set(lastMessage message: String, forConvo convo: Convo) {
        
    }#imageLiteral(resourceName: ")
    
    /// Decrements user, convo, proxy convo, and proxy `unread` by `amount`.
    func decrementAllUnreadFor(convo convo: Convo, byAmount amount: Int) {
        decrementUnread(forUser: convo.senderId, byAmount: amount)
        decrementUnread(forConvo: convo.key, forUser: convo.senderId, byAmount: amount)
        decrementUnread(forConvo: convo.key, underProxy: convo.senderProxy, byAmount: amount)
        decrementUnread(forProxy: convo.senderProxy, forUser: convo.senderId, byAmount: amount)
    }
    
    /// Update the receiver's nickname for the convo.
    /// (Only the sender sees this nickname).
    func update(nickname nickname: String, forReceiverInConvo convo: Convo) {
        ref.child("convos").child(convo.senderId).child(convo.key).child("receiverNickname").setValue(nickname)
        ref.child("convos").child(convo.senderProxy).child(convo.key).child("receiverNickname").setValue(nickname)
    }
    
    /// Sets `didLeaveConvo` to true for the user's convo and proxy convo.
    /// Sets the convos' `unread` to 0.
    /// Decrements the user's `unread` and proxy's `unread` by the convo's original unread.
    func leave(convo convo: Convo) {
        var _convo = convo
        _convo.didLeaveConvo = true
        _convo.unread = 0
        update(convo: _convo)
        update(proxyConvo: _convo)
        decrementUnread(forProxy: convo.senderProxy, forUser: convo.senderId, byAmount: convo.unread)
        decrementUnread(forUser: convo.senderId, byAmount: convo.unread)
    }
    
    // When you mute a convo, you stop getting push notifications for it.
    // TODO: Implement when get to push notifications
    func muteConvo() {}
    
    /// Updates the convo.
    func update(convo convo: Convo) {
        ref.child("convos").child(convo.senderId).child(convo.key).setValue(convo.toAnyObject())
    }
    
    /// Updates the convo's `unread`, `message`, `timestamp`, & `didLeaveConvo`.
    func update(convo convo: String, forUser user: String, withUnreadIncrement increment: Int, withMessage message: String, withTimestamp timestamp: Double) {
        self.ref.child("convos").child(user).child(convo).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if var convo = currentData.value as? [String: AnyObject] {
                let unread = convo["unread"] as? Int ?? 0
                convo["unread"] = unread + increment
                convo["message"] = message
                convo["timestamp"] = timestamp
                convo["didLeaveConvo"] = false
                currentData.value = convo
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        })
    }
    
    /// Decrements the convo's `unread` by `amount`.
    func decrementUnread(forConvo convo: String, forUser user: String, byAmount amount: Int) {
        ref.child("convos").child(user).child(convo).child("unread").runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if let unread = currentData.value {
                var _unread = unread as? Int ?? 0
                _unread -= amount
                currentData.value = _unread > -1 ? _unread : 0
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        })
    }
    
    /// Updates the proxy convo.
    func update(proxyConvo proxyConvo: Convo) {
        ref.child("convos").child(proxyConvo.senderProxy).child(proxyConvo.key).setValue(proxyConvo.toAnyObject())
    }
    
    /// Updates the proxy convo's `unread`, `message`, `timestamp`, & `didLeaveConvo`.
    func update(proxyConvo convo: String, forProxy proxy: String, withUnreadIncrement increment: Int, withMessage message: String, withTimestamp timestamp: Double) {
        self.ref.child("convos").child(proxy).child(convo).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if var convo = currentData.value as? [String: AnyObject] {
                let unread = convo["unread"] as? Int ?? 0
                convo["unread"] = unread + increment
                convo["message"] = message
                convo["timestamp"] = timestamp
                convo["didLeaveConvo"] = false
                currentData.value = convo
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        })
    }
    
    /// Decrements the proxy convo's `unread` by `amount`.
    func decrementUnread(forConvo convo: String, underProxy proxy: String, byAmount amount: Int) {
        ref.child("convos").child(proxy).child(convo).child("unread").runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if let unread = currentData.value {
                var _unread = unread as? Int ?? 0
                _unread -= amount
                currentData.value = _unread > -1 ? _unread : 0
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        })
    }
    
    /// Sets `parents`'s copy of convo's receiverDeletedProxy to `receiverDeletedProxy`.
    func set(receiverDeletedProxy receiverDeletedProxy: Bool, forConvo convo: String, underParent parent: String) {
        ref.child("convos").child(parent).child(convo).child("receiverDeletedProxy").setValue(receiverDeletedProxy)
    }
    
    /// Deletes a convo under `parent`.
    func delete(convo convo: String, underParent parent: String) {
        ref.child("convos").child(parent).child(convo).removeValue()
    }
}
