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
    
    var iconsRef = FIRDatabaseReference()
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
        iconsRef.removeObserverWithHandle(iconsRefHandle)
    }
    
    // MARK: - Utility
    /// Returns the Firebase reference with path `a`/`b`/`c`/`d`.
    /// Leave unneeded nodes blank starting from `d`, working back to `a`.
    /// There must be at least node `a`, else returns nil.
    func getRef(a a: String, b: String?, c: String?, d: String?) -> FIRDatabaseReference? {
        guard a != "" else { return nil }
        if let b = b, let c = c, let d = d
            where b != "" && c != "" && d != "" {
            return ref.child(a).child(b).child(c).child(d)
        }
        if let b = b, let c = c
            where b != "" && c != "" {
            return ref.child(a).child(b).child(c)
        }
        if let b = b
            where b != "" {
            return ref.child(a).child(b)
        }
        return ref.child(a)
    }
    
    /// Saves `anyObject` under `a`/`b`/`c`/`d`.
    /// Leave unneeded nodes blank starting from grandchild, working back to parent.
    /// There must be at least node `a`.
    func set(anyObject: AnyObject, a: String, b: String?, c: String?, d: String?) {
        if let ref = getRef(a: a, b: b, c: c, d: d) {
            ref.setValue(anyObject)
        }
    }
    
    /// Deletes object under `a`/`b`/`c`/`d`.
    /// Leave unneeded nodes blank starting from grandchild, working back to parent.
    /// There must be at least node `a`.
    func delete(a a: String, b: String?, c: String?, d: String?) {
        if let ref = getRef(a: a, b: b, c: c, d: d) {
            ref.removeValue()
        }
    }
    
    /// Increments object at `a`/`b`/`c`/`d` by `amount`.
    /// Leave unneeded nodes blank starting from grandchild, working back to parent.
    /// There must be at least node `a`.
    func increment(amount amount: Int, a: String, b: String?, c: String?, d: String?) {
        if let ref = getRef(a: a, b: b, c: c, d: d) {
            ref.runTransactionBlock( { (currentData: FIRMutableData) -> FIRTransactionResult in
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
    func getUIImage(fromURL url: NSURL, completion: (image: UIImage) -> Void) {
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
    
    /// Returns the UIImage for an icon.
    func getUIImage(forIcon icon: String, completion: (image: UIImage) -> Void) {
        
        /// Get url for icon in storage.
        getURL(forIcon: icon, completion: { (url) in
            
            /// Get image from url.
            self.getUIImage(fromURL: url, completion: { (image) in
                completion(image: image)
            })
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
    
    /// Uploads compressed version of image to storage.
    /// Returns url to the image in storage.
    func upload(image image: UIImage, completion: (url: NSURL) -> Void) {
        guard let data = UIImageJPEGRepresentation(image, 0) else { return }
        storageRef.child(Path.UserFiles).child(uid + String(NSDate().timeIntervalSince1970)).putData(data, metadata: nil) { (metadata, error) in
            guard let url = metadata?.downloadURL() else { return }
            completion(url: url)
            guard let urlString = url.absoluteString else { return }
            KingfisherManager.sharedManager.cache.storeImage(image, forKey: urlString, toDisk: true, completionHandler: nil)
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
    
    // MARK: - User
    /// Gives a user access to the default icons.
    func setDefaultIcons(forUser user: String) {
        let defaultIcons = DefaultIcons(id: user).defaultIcons
        ref.updateChildValues(defaultIcons as! [NSObject : AnyObject])
    }
    
    /// Keeps an up-to-date list of the icons the user has unlocked.
    /// These are Strings of the icon names used to build urls to the files in storage.
    func observeIcons() {
        iconsRef = ref.child(Path.Icons).child(uid)
        iconsRefHandle = iconsRef.observeEventType(.Value, withBlock: { (snapshot) in
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
    /// Returns a new proxy with a unique name.
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
    
    /// Loads proxyNameGenerator and returns a new proxy.
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
    
    /// Returns a new proxy with a unique name.
    func tryCreating(proxy completion: (proxy: Proxy) -> Void) {
        
        // Create a global proxy and save it.
        let uniqueKey = ref.child(Path.Proxies).childByAutoId().key
        let key = proxyNameGenerator.generateProxyName()
        let proxy = Proxy(key: key, ownerId: self.uid)
        set(proxy.toAnyObject(), a: Path.Proxies, b: uniqueKey, c: nil, d: nil)
        
        // Get all global proxies with this name.
        ref.child(Path.Proxies).queryOrderedByChild(Path.Key).queryEqualToValue(key).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            
            // If there's only one, we've got a unique proxy name.
            if snapshot.childrenCount == 1 {
                
                // Re-save the global proxy by name instead of the Firebase key.
                self.delete(a: Path.Proxies, b: uniqueKey, c: nil, d: nil)
                self.set(proxy.toAnyObject(), a: Path.Proxies, b: key, c: nil, d: nil)
                
                // Stop trying to create a proxy.
                self.isCreatingProxy = false
                
                // Create the user's copy of the proxy with a random icon.
                let proxy = Proxy(key: key, ownerId: self.uid, icon: self.getRandomIcon())
                
                // Save the user's proxy.
                self.set(proxy.toAnyObject(), a: Path.Proxies, b: self.uid, c: key, d: nil)
                
                completion(proxy: proxy)
                return
            }
            
            // Else name is taken so delete the proxy you just created.
            self.delete(a: Path.Proxies, b: uniqueKey, c: nil, d: nil)
            
            // Check if user has cancelled the process.
            if self.isCreatingProxy {
                
                // If not, try the process again.
                self.tryCreating(proxy: { (proxy) in
                    completion(proxy: proxy)
                })
            }
        })
    }
    
    /// Deletes `proxy` and returns a new one.
    func reroll(proxy proxy: Proxy, completion: (proxy: Proxy) -> Void) {
        delete(proxy: proxy)
        tryCreating(proxy: { (proxy) in
            completion(proxy: proxy)
        })
    }
    
    /// Stop trying to create a proxy.
    func cancelCreatingProxy() {
        isCreatingProxy = false
    }
    
    /// Returns the Proxy with `key` belonging to `user`.
    func getProxy(withKey key: String, belongingToUser user: String, completion: (proxy: Proxy) -> Void) {
        ref.child(Path.Proxies).child(user).child(key).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            completion(proxy: Proxy(anyObject: snapshot.value!))
        })
    }
    
    /// Sets a proxy's nickname.
    func set(nickname nickname: String, forProxy proxy: Proxy) {
        // Set for proxy
        set(nickname, a: Path.Proxies, b: proxy.ownerId, c: proxy.key, d: Path.Nickname)
        
        // Set for both copies of convo for all convos this proxy is in
        getConvos(forProxy: proxy) { (convos) in
            for convo in convos {
                self.set(nickname, a: Path.Convos, b: convo.senderId, c: convo.key, d: Path.SenderNickname)
                self.set(nickname, a: Path.Convos, b: convo.senderProxy, c: convo.key, d: Path.SenderNickname)
            }
        }
    }
    
    /// Sets a proxy's icon.
    func set(icon icon: String, forProxy proxy: Proxy) {
        // Set for proxy
        set(icon, a: Path.Proxies, b: proxy.ownerId, c: proxy.key, d: Path.Icon)
        
        // Set for both copies of receiver's convo for all convos this proxy is in
        getConvos(forProxy: proxy) { (convos) in
            for convo in convos {
                self.set(icon, a: Path.Convos, b: convo.receiverId, c: convo.key, d: Path.Icon)
                self.set(icon, a: Path.Convos, b: convo.receiverProxy, c: convo.key, d: Path.Icon)
            }
        }
    }
    
    /// Sets a proxy and its convos to deleted.
    func delete(proxy proxy: Proxy) {
        getConvos(forProxy: proxy) { (convos) in
            self.delete(proxy: proxy, withConvos: convos)
        }
    }
    
    /// Sets a proxy and its convos to deleted.
    func delete(proxy proxy: Proxy, withConvos convos: [Convo]) {
        // Delete the global proxy
        delete(a: Path.Proxies, b: proxy.key, c: nil, d: nil)
        
        // Set proxy to deleted
        set(true, a: Path.Proxies, b: uid, c: proxy.key, d: Path.Deleted)
        
        // Decrement user's unread by the proxy's unread
        increment(amount: -proxy.unread, a: Path.Unread, b: proxy.ownerId, c: Path.Unread, d: nil)
        
        // Loop through the proxy's convos
        for convo in convos {
            // Set convo to deleted for sender convos
            self.set(true, a: Path.Convos, b: convo.senderId, c: convo.key, d: Path.SenderDeletedProxy)
            self.set(true, a: Path.Convos, b: convo.senderProxy, c: convo.key, d: Path.SenderDeletedProxy)
            
            // Set convo to deleted for receiver convos
            self.set(true, a: Path.Convos, b: convo.receiverId, c: convo.key, d: Path.ReceiverDeletedProxy)
            self.set(true, a: Path.Convos, b: convo.receiverProxy, c: convo.key, d: Path.ReceiverDeletedProxy)
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
    
    // MARK: - Message
    /// Error checks before sending it off to the appropriate message sending fuction.
    /// Returns sender's convo and message on success.
    /// Returns an ErrorAlert on failure.
    func sendMessage(fromSenderProxy senderProxy: Proxy, toReceiverProxyName receiverProxyName: String, withText text: String, withMediaType mediaType: String, completion: (error: ErrorAlert?, convo: Convo?, message: Message?) -> Void ) {
        
        /// Check if receiver exists
        self.ref.child(Path.Proxies).queryOrderedByChild(Path.Key).queryEqualToValue(receiverProxyName).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            guard snapshot.childrenCount == 1 else {
                completion(error: ErrorAlert(title: "Recipient Not Found", message: "Perhaps there was a spelling error?"), convo: nil, message: nil)
                return
            }
            
            /// Check if sender is trying to send to him/herself
            let receiverProxy = Proxy(anyObject: snapshot.children.nextObject()!.value)
            guard senderProxy.ownerId != receiverProxy.ownerId else {
                completion(error: ErrorAlert(title: "Cannot Send To Self", message: "Did you enter yourself as a recipient by mistake?"), convo: nil, message: nil)
                return
            }
            
            /// Build convo key by sorting and concatenizing the proxy keys
            let convoKey = [senderProxy.key, receiverProxy.key].sort().joinWithSeparator("")
            
            /// Check if convo exists between proxies
            self.ref.child(Path.Convos).child(senderProxy.ownerId).queryEqualToValue(convoKey).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                
                /// Existing convo found, use it to send the message
                if snapshot.childrenCount == 1 {
                    let convo = Convo(anyObject: snapshot.value!)
                    self.sendMessage(withText: text, withMediaType: mediaType, usingSenderConvo: convo, completion: { (convo, message) in
                        completion(error: nil, convo: convo, message: message)
                    })
                }
                
                /// No convo found, set up a new convo before sending message
                self.setUpFirstMessage(fromSenderProxy: senderProxy, toReceiverProxy: receiverProxy, usingConvoKey: convoKey, withText: text, withMediaType: mediaType, completion: { (convo, message) in
                    completion(error: nil, convo: convo, message: message)
                })
            })
        })
    }
    
    /// Sets up the first message between two proxies.
    /// Returns sender's convo and message.
    func setUpFirstMessage(fromSenderProxy senderProxy: Proxy, toReceiverProxy receiverProxy: Proxy, usingConvoKey convoKey: String, withText text: String, withMediaType mediaType: String, completion: (convo: Convo, message: Message) -> Void) {
        
        /// Check if sender is in receiver's blocked list
        ref.child(Path.Blocked).child(receiverProxy.ownerId).child(senderProxy.ownerId).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            var senderConvo = Convo()
            var receiverConvo = Convo()
            let senderBlocked = snapshot.childrenCount == 1
            
            /// Set up sender side
            senderConvo.key = convoKey
            senderConvo.senderId = senderProxy.ownerId
            senderConvo.senderProxy = senderProxy.key
            senderConvo.receiverId = receiverProxy.ownerId
            senderConvo.receiverProxy = receiverProxy.key
            senderConvo.receiverIcon = receiverProxy.icon
            senderConvo.receiverIsBlocking = senderBlocked
            let senderConvoAnyObject = senderConvo.toAnyObject()
            self.set(senderConvoAnyObject, a: Path.Convos, b: senderConvo.senderId, c: senderConvo.key, d: nil)
            self.set(senderConvoAnyObject, a: Path.Convos, b: senderConvo.senderProxy, c: senderConvo.key, d: nil)
            self.increment(amount: 1, a: Path.ProxiesInteractedWith, b: senderProxy.ownerId, c: Path.ProxiesInteractedWith, d: nil)
            
            /// Set up receiver side
            receiverConvo.key = convoKey
            receiverConvo.senderId = receiverProxy.ownerId
            receiverConvo.senderProxy = receiverProxy.key
            receiverConvo.receiverId = senderProxy.ownerId
            receiverConvo.receiverProxy = senderProxy.key
            receiverConvo.receiverIcon = senderProxy.icon
            receiverConvo.senderIsBlocking = senderBlocked
            let receiverConvoAnyObject = receiverConvo.toAnyObject()
            self.set(receiverConvoAnyObject, a: Path.Convos, b: receiverConvo.senderId, c: receiverConvo.key, d: nil)
            self.set(receiverConvoAnyObject, a: Path.Convos, b: receiverConvo.senderProxy, c: receiverConvo.key, d: nil)
            self.increment(amount: 1, a: Path.ProxiesInteractedWith, b: receiverProxy.ownerId, c: Path.ProxiesInteractedWith, d: nil)
            
            /// Set message
            self.sendMessage(withText: text, withMediaType: mediaType, usingSenderConvo: senderConvo, completion: { (convo, message) in
                completion(convo: convo, message: message)
            })
        })
    }
    
    /// Sends a message using the sender's copy of the convo.
    /// Returns sender's convo and message.
    func sendMessage(withText text: String, withMediaType mediaType: String, usingSenderConvo convo: Convo, completion: (convo: Convo, message: Message) -> Void) {
        userIsPresent(user: convo.receiverId, convo: convo.key) { (receiverIsPresent) in
            let timestamp = NSDate().timeIntervalSince1970
            
            // Sender updates
            self.set(timestamp, a: Path.Proxies, b: convo.senderId, c: convo.senderProxy, d: Path.Timestamp)
            self.setConvoValuesOnMessageSend(convo.senderId, proxy: convo.senderProxy, convo: convo.key, message: "You: \(text)", timestamp: timestamp)
            self.increment(amount: 1, a: Path.MessagesSent, b: convo.receiverId, c: Path.MessagesSent, d: nil)
            
            // Receiver updates
            let increment = receiverIsPresent ? 0 : 1
            if !convo.receiverDeletedProxy && !convo.receiverIsBlocking {
                self.set(text, a: Path.Proxies, b: convo.receiverId, c: convo.receiverProxy, d: Path.Message)
                self.set(timestamp, a: Path.Proxies, b: convo.receiverId, c: convo.receiverProxy, d: Path.Timestamp)
                self.increment(amount: increment, a: Path.Proxies, b: convo.receiverId, c: convo.receiverProxy, d: Path.Unread)
                self.increment(amount: increment, a: Path.Unread, b: convo.receiverId, c: Path.Unread, d: nil)
            }
            if !convo.receiverDeletedProxy {
                self.setConvoValuesOnMessageSend(convo.receiverId, proxy: convo.receiverProxy, convo: convo.key, message: text, timestamp: timestamp)
                self.increment(amount: increment, a: Path.Convos, b: convo.receiverId, c: convo.key, d: Path.Unread)
                self.increment(amount: increment, a: Path.Convos, b: convo.receiverProxy, c: convo.key, d: Path.Unread)
            }
            self.increment(amount: 1, a: Path.MessagesReceived, b: convo.receiverId, c: Path.MessagesReceived, d: nil)
            
            // Write message
            let messageKey = self.ref.child(Path.Messages).child(convo.key).childByAutoId().key
            let timeRead = receiverIsPresent ? timestamp : 0.0
            let message = Message(key: messageKey, convo: convo.key, mediaType: mediaType, read: receiverIsPresent, timeRead: timeRead, senderId: convo.senderId, date: timestamp, text: text)
            self.set(message.toAnyObject(), a: Path.Messages, b: convo.key, c: messageKey, d: nil)
            
            completion(convo: convo, message: message)
        }
    }
    
    /// Sets `leftConvo`, `message`, & `timestamp` for a user's convo.
    func setConvoValuesOnMessageSend(user: String, proxy: String, convo: String, message: String, timestamp: Double) {
        set(false, a: Path.Convos, b: user, c: convo, d: Path.LeftConvo)
        set(false, a: Path.Convos, b: proxy, c: convo, d: Path.LeftConvo)
        set(message, a: Path.Convos, b: user, c: convo, d: Path.Message)
        set(message, a: Path.Convos, b: proxy, c: convo, d: Path.Message)
        set(timestamp, a: Path.Convos, b: user, c: convo, d: Path.Timestamp)
        set(timestamp, a: Path.Convos, b: proxy, c: convo, d: Path.Timestamp)
    }
    
    /// Returns a Bool indicating whether or not a user is in a convo.
    func userIsPresent(user user: String, convo: String, completion: (userIsPresent: Bool) -> Void) {
        ref.child(Path.Present).child(convo).child(user).child(Path.Present).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            completion(userIsPresent: snapshot.value as? Bool ?? false)
        })
    }
    
    /// Sets the message's `read` & `timeRead`.
    /// Decrements unread's for user.
    func setRead(forMessage message: Message, forUser user: String, forProxy proxy: String) {
        set(true, a: Path.Messages, b: message.convo, c: message.key, d: Path.Read)
        set(NSDate().timeIntervalSince1970, a: Path.Messages, b: message.convo, c: message.key, d: Path.TimeRead)
        increment(amount: -1, a: Path.Unread, b: user, c: Path.Unread, d: nil)
        increment(amount: -1, a: Path.Proxies, b: user, c: proxy, d: Path.Unread)
        increment(amount: -1, a: Path.Convos, b: user, c: message.convo, d: Path.Unread)
        increment(amount: -1, a: Path.Convos, b: proxy, c: message.convo, d: Path.Unread)
    }
    
    /// Sets a message's `mediaType` and `mediaURL`.
    func setMedia(forMessage message: Message, mediaType: String, mediaURL: String) {
        set(mediaType, a: Path.Messages, b: message.convo, c: message.key, d: Path.MediaType)
        set(mediaURL, a: Path.Messages, b: message.convo, c: message.key, d: Path.MediaURL)
    }
    
    /// Returns a message.
    func getMessage(withKey messageKey: String, inConvo convoKey: String, completion: (message: Message) -> Void) {
        ref.child(Path.Messages).child(convoKey).child(messageKey).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            completion(message: Message(anyObject: snapshot.value!))
        })
    }
    
    // MARK: - Conversation (Convo)
    /// Returns a convo.
    // TODO: prob don't need this
    func getConvo(withKey key: String, belongingToUser user: String, completion: (convo: Convo) -> Void) {
        ref.child(Path.Convos).child(user).child(key).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            completion(convo: Convo(anyObject: snapshot.value!))
        })
    }
    
    /// Sets receiver's nickname for the convo.
    /// (Only the sender sees this nickname).
    func set(nickname nickname: String, forReceiverInConvo convo: Convo) {
        set(nickname, a: Path.Convos, b: convo.senderId, c: convo.key, d: Path.Name)
        set(nickname, a: Path.Convos, b: convo.senderProxy, c: convo.key, d: Path.Name)
    }
    
    /// Leaves a convo.
    func leave(convo convo: Convo) {
        set(true, a: Path.Convos, b: convo.senderId, c: convo.key, d: Path.LeftConvo)
        set(true, a: Path.Convos, b: convo.senderProxy, c: convo.key, d: Path.LeftConvo)
        set(0, a: Path.Convos, b: convo.senderId, c: convo.key, d: Path.Unread)
        set(0, a: Path.Convos, b: convo.senderProxy, c: convo.key, d: Path.Unread)
        increment(amount: -convo.unread, a: Path.Unread, b: convo.senderId, c: Path.Unread, d: nil)
        increment(amount: -convo.unread, a: Path.Proxies, b: convo.senderId, c: convo.senderProxy, d: Path.Unread)
    }
    
    /// Returns an array of Convo's.
    /// Filters out convos we don't want to see.
    func getConvos(fromSnapshot snapshot: FIRDataSnapshot) -> [Convo] {
        var convos = [Convo]()
        for child in snapshot.children {
            let convo = Convo(anyObject: child.value)
            if !convo.leftConvo && !convo.senderDeletedProxy && !convo.senderIsBlocking {
                convos.append(convo)
            }
        }
        return convos.reverse()
    }
    
    /// Returns a convo title.
    func getConvoTitle(receiverNickname: String, receiverName: String, senderNickname: String, senderName: String) -> NSAttributedString {
        let grayAttribute = [NSForegroundColorAttributeName: UIColor.grayColor()]
        var first: NSMutableAttributedString
        var second: NSMutableAttributedString
        let comma = ", "
        
        if receiverNickname == "" {
            first = NSMutableAttributedString(string: receiverName + comma)
        } else {
            first = NSMutableAttributedString(string: receiverNickname + comma)
        }
        
        if senderNickname == "" {
            second = NSMutableAttributedString(string: senderName, attributes: grayAttribute)
        } else {
            second = NSMutableAttributedString(string: senderNickname, attributes: grayAttribute)
        }
        
        first.appendAttributedString(second)
        return first
    }
    
    // When you mute a convo, you stop getting push notifications for it.
    // TODO: Implement when get to push notifications
    func muteConvo() {}
}
