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
        ref.child(Path.Icons).child(uid).removeObserverWithHandle(iconsRefHandle)
    }
    
    // MARK: - Utility
    /// Returns the Firebase reference with path `itemType`/`parent`/`child`/`grandchild`.
    /// Leave unneeded nodes blank starting from grandchild, working back to parent.
    func getRef(itemType: String, parent: String, child: String?, grandchild: String?) -> FIRDatabaseReference? {
        if let child = child, let grandchild = grandchild
            where parent != "" && child != "" && grandchild != "" {
            return ref.child(itemType).child(parent).child(child).child(grandchild)
        }
        if let child = child
            where parent != "" && child != "" {
            return ref.child(itemType).child(parent).child(child)
        }
        if parent != "" {
            return ref.child(itemType).child(parent)
        }
        return nil
    }
    
    /// Saves `anyObject` under `itemType`/`parent`/`child`/`grandchild`.
    /// Leave unneeded nodes blank starting from grandchild, working back to parent.
    func set(anyObject: AnyObject, itemType: String, parent: String, child: String?, grandchild: String?) {
        if let ref = getRef(itemType, parent: parent, child: child, grandchild: grandchild) {
            ref.setValue(anyObject)
        }
    }
    
    /// Deletes object under `itemType`/`parent`/`child`/`grandchild`.
    /// Leave unneeded nodes blank starting from grandchild, working back to parent.
    func delete(itemType: String, parent: String, child: String?, grandchild: String?) {
        if let ref = getRef(itemType, parent: parent, child: child, grandchild: grandchild) {
            ref.removeValue()
        }
    }
    
    /// Increments object at `itemType`/`parent`/`child`/`grandchild` by `amount`.
    /// Leave unneeded nodes blank starting from grandchild, working back to parent.
    func increment(amount: Int, itemType: String, parent: String, child: String?, grandchild: String?) {
        if let ref = getRef(itemType, parent: parent, child: child, grandchild: grandchild) {
            ref.runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
                if let value = currentData.value {
                    var _value = value as? Int ?? 0
                    _value += amount
                    currentData.value = _value > 0 ? _value : 0
                    return FIRTransactionResult.successWithValue(currentData)
                }
                return FIRTransactionResult.successWithValue(currentData)
            })
        }
    }
    
    /// Returns the UIImage for a url.
    func getImage(fromURL url: NSURL, completion: (image: UIImage) -> Void) {
        guard let urlString = url.absoluteString else { return }
        
        /// Check cache first.
        KingfisherManager.sharedManager.cache.retrieveImageForKey(urlString, options: nil) { (image, cacheType) -> () in
            if let image = image {
                completion(image: image)
                return
            }
        
            /// Not in cache, retrieve online.
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
                self.storageRef.child(Path.UserFiles).child(String(NSDate().timeIntervalSince1970)).putFile(compressedURL, metadata: nil) { metadata, error in
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
        storageRef.child(Path.UserFiles).child(String(NSDate().timeIntervalSince1970)).putData(data, metadata: nil) { (metadata, error) in
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
        ref.child(Path.WordBank).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
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
        let key = ref.child(Path.Proxies).childByAutoId().key
        let name = proxyNameGenerator.generateProxyName()
        let proxy = Proxy(key: key, name: name, ownerId: "", timeCreated: 0.0)
        set(proxy.toAnyObject(), itemType: Path.Proxies, parent: key, child: nil, grandchild: nil)
        
        /// Get all proxies with this name.
        ref.child(Path.Proxies).queryOrderedByChild(Path.Name).queryEqualToValue(name).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            
            /// If there's only one, it's the one you just created and you're done.
            if snapshot.childrenCount == 1 {
                
                /// Stop trying to create a proxy.
                self.isCreatingProxy = false
                
                /// Create the user's copy of the proxy and save it.
                let proxy = Proxy(key: key, name: name, ownerId: self.uid, timeCreated: NSDate().timeIntervalSince1970)
                self.set(proxy.toAnyObject(), itemType: Path.Proxies, parent: self.uid, child: key, grandchild: nil)
                
                /// Give the proxy a random icon.
                self.set(self.getRandomIcon(), itemType: Path.Icons, parent: name, child: nil, grandchild: nil)
                
                completion(proxy: proxy)
                return
            }
            
            /// Else delete the proxy you just created.
            self.delete(Path.Proxies, parent: proxy.key, child: nil, grandchild: nil)
            
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
        iconsRefHandle = ref.child(Path.Icons).child(uid).observeEventType(.Value, withBlock: { (snapshot) in
            var icons = [String]()
            for child in snapshot.children {
                icons.append(child.value[Path.Name] as! String)
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
        delete(Path.Proxies, parent: proxy.key, child: nil, grandchild: nil)
        tryCreating(proxy: { (proxy) in
            completion(proxy: proxy)
        })
    }
    
    /// Deletes the newly created `proxy` being checked for uniqueness.
    /// Notifies API to stop trying to create a proxy.
    func cancelCreating(proxy: Proxy) {
        delete(Path.Proxies, parent: proxy.key, child: nil, grandchild: nil)
        isCreatingProxy = false
    }
    
    /// Returns the Proxy with `key` belonging to `user`.
    func getProxy(withKey key: String, belongingToUser user: String, completion: (proxy: Proxy) -> Void) {
        ref.child(Path.Proxies).child(user).child(key).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
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
            let iconRef = storageRef.child(Path.Icons).child("\(icon).png")
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
        set(nickname, itemType: Path.Nickname, parent: proxy, child: nil, grandchild: nil)
    }
    
    /// Sets a proxy's icon to `icon`.
    func set(icon icon: String, forProxy proxy: String) {
        set(icon, itemType: Path.Icon, parent: proxy, child: nil, grandchild: nil)
    }
    
    /// Sets a proxy's timestamp to `timestamp`.
    func set(timestamp timestamp: Double, forProxy proxy: String, belongingTo user: String) {
        set(timestamp, itemType: Path.Proxies, parent: user, child: proxy, grandchild: Path.Timestamp)
    }
    
    /// Deletes a proxy and it's copies of its convos.
    func delete(proxy: Proxy) {
        getConvos(forProxy: proxy) { (convos) in
            self.delete(proxy: proxy, withConvos: convos)
        }
    }
    
    /// Returns the convos that a proxy is in.
    func getConvos(forProxy proxy: Proxy, completion: (convos: [Convo]) -> Void) {
        ref.child(Path.Convos).child(proxy.key).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
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
            set(true, itemType: Path.Convos, parent: convo.receiverId, child: convo.key, grandchild: nil)
            set(true, itemType: Path.Convos, parent: convo.receiverProxy, child: convo.key, grandchild: nil)
            
            /// Delete the sender's copies of the convo
            delete(Path.Convos, parent: convo.senderId, child: convo.key, grandchild: nil)
            delete(Path.Convos, parent: convo.senderProxy, child: convo.key, grandchild: nil)
            
            /// Delete convo's metadata
            delete(Path.Nickname, parent: convo.senderId, child: convo.key, grandchild: nil)
            delete(Path.Unread, parent: convo.senderId, child: convo.key, grandchild: nil)
        }
        
        /// Delete the global copy of the proxy
        delete(Path.Proxies, parent: proxy.key, child: nil, grandchild: nil)
        
        /// Delete the user's copy of the proxy
        delete(Path.Proxies, parent: uid, child: proxy.key, grandchild: nil)
        
        /// Delete icon
        delete(Path.Icons, parent: proxy.key, child: nil, grandchild: nil)
        
        /// Delete nickname
        delete(Path.Nickname, parent: proxy.key, child: nil, grandchild: nil)
        
        /// Get unread
        ref.child(Path.Nickname).child(proxy.key).observeEventType(.Value, withBlock: { (snapshot) in
            
            /// Delete unread
            self.delete(Path.Unread, parent: proxy.key, child: nil, grandchild: nil)
            
            /// Decrement user's unread by proxy's unread
            guard let unread = snapshot.value as? Int where unread != 0 else { return }
            self.increment(-unread, itemType: Path.Unread, parent: proxy.ownerId, child: nil, grandchild: nil)
        })
    }
    
    // MARK: - Message
    /// Error checks before sending it off to the appropriate message sending fuction.
    /// Returns the convoKey and message on success.
    /// Returns an ErrorAlert on failure.
    func sendMessage(fromSenderProxy senderProxy: Proxy, toReceiverProxyName receiverProxyName: String, withText text: String, withMediaType mediaType: String, completion: (error: ErrorAlert?, convoKey: String?, message: Message?) -> Void ) {
        
        /// Check if receiver exists
        self.ref.child(Path.Proxies).queryOrderedByChild(Path.Name).queryEqualToValue(receiverProxyName).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            guard snapshot.childrenCount == 1 else {
                completion(error: ErrorAlert(title: "Recipient Not Found", message: "Perhaps there was a spelling error?"), convoKey: nil, message: nil)
                return
            }
            
            /// Check if sender is trying to send to him/herself
            let receiverProxy = Proxy(anyObject: snapshot.value!)
            guard senderProxy.ownerId != receiverProxy.ownerId else {
                completion(error: ErrorAlert(title: "Cannot Send To Self", message: "Did you enter yourself as a recipient by mistake?"), convoKey: nil, message: nil)
                return
            }
            
            /// Build convo key from sorting and concatenizing the proxy names
            let convoKey = [senderProxy.key, receiverProxy.key].sort().joinWithSeparator("")
            
            /// Check if existing convo between the proxies exists
            self.ref.child(Path.Convos).child(senderProxy.ownerId).queryEqualToValue(convoKey).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                
                /// Existing convo found, use it to send the message
                if snapshot.childrenCount == 1 {
                    let convo = Convo(anyObject: snapshot.value!)
                    self.sendMessage(withText: text, withMediaType: mediaType, usingSenderConvo: convo, completion: { (convoKey, message) in
                        completion(error: nil, convoKey: convoKey, message: message)
                    })
                }
                
                /// No convo found, must set up convo before sending message
                self.setUpFirstMessage(fromSenderProxy: senderProxy, toReceiverProxy: receiverProxy, usingConvoKey: convoKey, withText: text, withMediaType: mediaType, completion: { (convoKey, message) in
                    completion(error: nil, convoKey: convoKey, message: message)
                })
            })
        })
    }
    
    /// Sets up the first message between two proxies.
    /// Returns convoKey and message.
    func setUpFirstMessage(fromSenderProxy senderProxy: Proxy, toReceiverProxy receiverProxy: Proxy, usingConvoKey convoKey: String, withText text: String, withMediaType mediaType: String, completion: (convoKey: String, message: Message) -> Void) {
        
        /// Check if sender is in receiver's blocked list
        ref.child(Path.Blocked).child(receiverProxy.ownerId).child(senderProxy.ownerId).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            var senderConvo = Convo()
            senderConvo.key = convoKey
            var receiverConvo = senderConvo
            let senderBlocked = snapshot.childrenCount == 1
            
            /// Set up sender side
            senderConvo.senderId = senderProxy.ownerId
            senderConvo.senderProxy = senderProxy.key
            senderConvo.receiverId = receiverProxy.ownerId
            senderConvo.receiverProxy = receiverProxy.key
            senderConvo.receiverIsBlocking = senderBlocked
            let senderConvoAnyObject = senderConvo.toAnyObject()
            self.set(senderConvoAnyObject, itemType: Path.Convos, parent: senderConvo.senderId, child: senderConvo.key, grandchild: nil)
            self.set(senderConvoAnyObject, itemType: Path.Convos, parent: senderConvo.senderProxy, child: senderConvo.key, grandchild: nil)
            self.increment(1, itemType: Path.ProxiesInteractedWith, parent: senderProxy.ownerId, child: nil, grandchild: nil)
            
            /// Set up receiver side
            receiverConvo.senderId = receiverProxy.ownerId
            receiverConvo.senderProxy = receiverProxy.key
            receiverConvo.receiverId = senderProxy.ownerId
            receiverConvo.receiverProxy = senderProxy.key
            receiverConvo.senderIsBlocking = senderBlocked
            let receiverConvoAnyObject = receiverConvo.toAnyObject()
            self.set(receiverConvoAnyObject, itemType: Path.Convos, parent: receiverConvo.senderId, child: receiverConvo.key, grandchild: nil)
            self.set(receiverConvoAnyObject, itemType: Path.Convos, parent: receiverConvo.senderProxy, child: receiverConvo.key, grandchild: nil)
            self.increment(1, itemType: Path.ProxiesInteractedWith, parent: receiverProxy.ownerId, child: nil, grandchild: nil)
            
            /// Set message
            self.sendMessage(withText: text, withMediaType: mediaType, usingSenderConvo: senderConvo, completion: { (convoKey, message) in
                completion(convoKey: convoKey, message: message)
            })
        })
    }
    
    /// Sends a message using the sender's copy of the convo.
    /// Returns the convo key and message.
    func sendMessage(withText text: String, withMediaType mediaType: String, usingSenderConvo convo: Convo, completion: (convoKey: String, message: Message) -> Void) {
        userIsPresent(user: convo.receiverId, convo: convo.key) { (receiverIsPresent) in
            let increment = receiverIsPresent ? 0 : 1
            let timestamp = NSDate().timeIntervalSince1970
            
            /// Sender updates
            self.setConvoValuesOnMessageSend(message: "You: \(text)", timestamp: timestamp, id: convo.senderId, proxy: convo.senderProxy, convo: convo.key)
            self.set(timestamp, itemType: Path.Timestamp, parent: convo.senderProxy, child: Path.Timestamp, grandchild: nil)
            self.increment(1, itemType: Path.MessagesSent, parent: convo.senderId, child: nil, grandchild: nil)
            
            /// Receiver updates
            if !convo.receiverDeletedProxy && !convo.receiverIsBlocking {
                self.increment(increment, itemType: Path.Unread, parent: convo.receiverId, child: nil, grandchild: nil)
                self.increment(increment, itemType: Path.Unread, parent: convo.receiverProxy, child: nil, grandchild: nil)
                self.set(timestamp, itemType: Path.Timestamp, parent: convo.receiverProxy, child: Path.Timestamp, grandchild: nil)
            }
            
            if !convo.receiverDeletedProxy {
                self.setConvoValuesOnMessageSend(message: text, timestamp: timestamp, id: convo.receiverId, proxy: convo.receiverProxy, convo: convo.key)
                self.increment(increment, itemType: Path.MessagesReceived, parent: convo.receiverId, child: nil, grandchild: nil)
            }
            
            /// Write message
            let messageKey = self.ref.child(Path.Messages).child(convo.key).childByAutoId().key
            let timeRead = receiverIsPresent ? timestamp : 0.0
            let message = Message(key: messageKey, convo: convo.key, mediaType: mediaType, read: receiverIsPresent, timeRead: timeRead, senderId: convo.senderId, date: timestamp, text: text)
            self.set(message.toAnyObject(), itemType: Path.Messages, parent: convo.key, child: messageKey, grandchild: "")
            
            completion(convoKey: convo.key, message: message)
        }
    }
    
    /// Sets various user convo values when sending a message.
    func setConvoValuesOnMessageSend(message message: String, timestamp: Double, id: String, proxy: String, convo: String) {
        self.set(message, itemType: Path.LastMessage, parent: id, child: convo, grandchild: nil)
        self.set(timestamp, itemType: Path.Convos, parent: id, child: convo, grandchild: Path.Timestamp)
        self.set(timestamp, itemType: Path.Convos, parent: proxy, child: convo, grandchild: Path.Timestamp)
        self.set(false, itemType: Path.Convos, parent: id, child: convo, grandchild: Path.DidLeaveConvo)
        self.set(false, itemType: Path.Convos, parent: proxy, child: convo, grandchild: Path.DidLeaveConvo)
    }
    
    /// Returns a Bool indicating whether or not a user is in a convo.
    func userIsPresent(user user: String, convo: String, completion: (userIsPresent: Bool) -> Void) {
        ref.child(Path.Present).child(convo).child(user).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            completion(userIsPresent: snapshot.value as? Bool ?? false)
        })
    }
    
    /// Sets the message's `read` to true and gives it a current `timeRead`.
    func setRead(forMessage message: Message) {
        set(true, itemType: Path.Messages, parent: message.convo, child: message.key, grandchild: Path.Read)
        set(NSDate().timeIntervalSince1970, itemType: Path.Messages, parent: message.convo, child: message.key, grandchild: Path.TimeRead)
    }
    
    /// Sets a message's `mediaType` and `mediaURL`.
    func setMedia(forMessage message: Message, mediaType: String, mediaURL: String) {
        set(mediaType, itemType: Path.Messages, parent: message.convo, child: message.key, grandchild: Path.MediaType)
        set(mediaURL, itemType: Path.Messages, parent: message.convo, child: message.key, grandchild: Path.MediaURL)
    }
    
    // TODO: what is this used for?
    /// Return the message with the corresponding key.
    func getMessage(withKey messageKey: String, inConvo convoKey: String, completion: (message: Message) -> Void) {
        ref.child(Path.Messages).child(convoKey).child(messageKey).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            completion(message: Message(anyObject: snapshot.value!))
        })
    }
    
    // MARK: - Conversation (Convo)
    /// Update the receiver's nickname for the convo.
    /// (Only the sender sees this nickname).
    func update(nickname nickname: String, forReceiverInConvo convo: Convo) {
        set(nickname, itemType: Path.Nickname, parent: convo.senderId, child: convo.key, grandchild: nil)
    }
    
    /// Leaves a convo.
    func leave(convo convo: Convo) {
        
        /// Set `didLeaveConvo` for both copies of convo to true.
        set(true, itemType: Path.Convos, parent: convo.senderId, child: convo.key, grandchild: Path.DidLeaveConvo)
        set(true, itemType: Path.Convos, parent: convo.senderProxy, child: convo.key, grandchild: Path.DidLeaveConvo)
        
        /// Get convo's `unread`.
        getRef(Path.Unread, parent: convo.senderId, child: convo.key, grandchild: nil)?.observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            
            /// Set convo's `unread` to 0.
            self.set(0, itemType: Path.Unread, parent: convo.senderId, child: convo.key, grandchild: nil)
            
            /// Decrement user's and proxy's `unread` by the convo's `unread`.
            guard let unread = snapshot.value as? Int where unread != 0 else { return }
            self.increment(-unread, itemType: Path.Unread, parent: convo.senderId, child: nil, grandchild: nil)
            self.increment(-unread, itemType: Path.Unread, parent: convo.senderProxy, child: nil, grandchild: nil)
        })
    }
    
    // When you mute a convo, you stop getting push notifications for it.
    // TODO: Implement when get to push notifications
    func muteConvo() {}
}
