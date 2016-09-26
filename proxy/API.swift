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
    
    /// Returns an Int for the amount of unread messages the user has.
    /// Filters out messages we don't want to count.
    /// - Parameter snapshot: the query result for `unread` for the user.
    func getUnread(forProxies proxies: FIRDataSnapshot, completion: (unread: Int) -> Void) {
        var convoCount = getNumberOfConvos(inProxies: proxies)
        var unread = 0
        for proxy in proxies.children {
            self.getUnread(forProxy: proxy as! FIRDataSnapshot, completion: { (unread_) in
                unread += unread_
                convoCount -= proxy.childrenCount
                if convoCount == 0 {
                    completion(unread: unread)
                }
            })
        }
    }
    
    /// Returns the number of convos in `proxies`.
    func getNumberOfConvos(inProxies proxies: FIRDataSnapshot) -> UInt {
        var convoCount: UInt = 0
        for proxy in proxies.children {
            convoCount += proxy.childrenCount
        }
        return convoCount
    }
    
    /// Returns the number of unread messages in `proxy`.
    func getUnread(forProxy proxy: FIRDataSnapshot, completion: (unread: Int) -> Void) {
        var convoCount = proxy.childrenCount
        var unread = 0
        for convo in proxy.children {
            let convo = convo as! FIRDataSnapshot
            self.getConvo(withKey: convo.key, belongingToUser: self.uid, completion: { (convo_) in
                if !convo_.didLeaveConvo && !convo_.senderDidDeleteProxy && !convo_.senderIsBlocking {
                    unread += convo.value as! Int
                }
                convoCount -= 1
                if convoCount == 0 {
                    completion(unread: unread)
                }
            })
        }
    }
    
    // MARK: - Proxy
    /// Loads word bank if needed, else call `tryCreateProxy`.
    /// Returns a newly created proxy with a unique name.
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
        let uniqueKey = ref.child(Path.Proxies).childByAutoId().key
        let key = proxyNameGenerator.generateProxyName()
        let proxy = Proxy(key: key, ownerId: self.uid, timeCreated: 0.0, timestamp: 0.0, isDeleted: false)
        set(proxy.toAnyObject(), a: Path.Proxies, b: uniqueKey, c: nil, d: nil)
        
        /// Get all proxies with this name.
        ref.child(Path.Proxies).queryOrderedByChild(Path.Key).queryEqualToValue(key).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            
            /// If there's only one, it's the one you just created and you're done.
            if snapshot.childrenCount == 1 {
                
                /// Delete the proxy saved under `uniqueKey` and save it under name.
                /// Makes it easier to retreive/delete later.
                /// We just needed a unique key so that when creating our temp proxy,
                /// we dont overwrite an existing one.
                self.delete(a: Path.Proxies, b: uniqueKey, c: nil, d: nil)
                self.set(proxy.toAnyObject(), a: Path.Proxies, b: key, c: nil, d: nil)
                
                /// Stop trying to create a proxy.
                self.isCreatingProxy = false
                
                /// Create the user's copy of the proxy and save it.
                /// The proxy's name is used as its key here.
                let timestamp = NSDate().timeIntervalSince1970
                let proxy = Proxy(key: key, ownerId: self.uid, timeCreated: timestamp, timestamp: timestamp, isDeleted: false)
                self.set(proxy.toAnyObject(), a: Path.Proxies, b: self.uid, c: key, d: nil)
                
                /// Give the proxy a random icon.
                self.set(self.getRandomIcon(), a: Path.Icon, b: key, c: Path.Icon, d: nil)
                
                completion(proxy: proxy)
                return
            }
            
            /// Else delete the proxy you just created.
            self.delete(a: Path.Proxies, b: proxy.key, c: nil, d: nil)
            
            /// Check if user has cancelled the process.
            if self.isCreatingProxy {
                
                /// Try the process again.
                self.tryCreating(proxy: { (proxy) in
                    completion(proxy: proxy)
                })
            }
        })
    }
    
    /// Deletes the given `proxy` and returns a new one.
    func reroll(proxy proxy: Proxy, completion: (proxy: Proxy) -> Void) {
        delete(proxy: proxy)
        tryCreating(proxy: { (proxy) in
            completion(proxy: proxy)
        })
    }
    
    /// Deletes the newly created `proxy` being checked for uniqueness.
    /// Notifies API to stop trying to create a proxy.
    func cancelCreating(proxy proxy: Proxy) {
        delete(proxy: proxy)
        isCreatingProxy = false
    }
    
    /// Returns the Proxy with `name` belonging to `user`.
    func getProxy(withKey key: String, belongingToUser user: String, completion: (proxy: Proxy) -> Void) {
        ref.child(Path.Proxies).child(user).child(key).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            completion(proxy: Proxy(anyObject: snapshot.value!))
        })
    }
    
    /// Sets a proxy's nickname to `nickname`.
    func set(nickname nickname: String, forProxy proxy: String) {
        set(nickname, a: Path.Nickname, b: proxy, c: Path.Nickname, d: nil)
    }
    
    /// Sets a proxy's icon to `icon`.
    func set(icon icon: String, forProxy proxy: String) {
        set(icon, a: Path.Icon, b: proxy, c: Path.Icon, d: nil)
    }
    
    /// Deletes a proxy and it's copies of its convos.
    func delete(proxy proxy: Proxy) {
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
    
    /// Deletes a proxy's global copy.
    /// Sets the proxy to deleted.
    /// Sets sender's copies of the proxy's convos to deleted.
    func delete(proxy proxy: Proxy, withConvos convos: [Convo]) {
        delete(a: Path.Proxies, b: proxy.key, c: nil, d: nil)
        set(true, a: Path.Proxies, b: uid, c: proxy.key, d: Path.IsDeleted)
        for convo in convos {
            set(true, a: Path.Convos, b: convo.senderId, c: convo.key, d: Path.SenderDidDeleteProxy)
            set(true, a: Path.Convos, b: convo.senderProxy, c: convo.key, d: Path.SenderDidDeleteProxy)
        }
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
            
            /// Build convo key from sorting and concatenizing the proxy keys
            let convoKey = [senderProxy.key, receiverProxy.key].sort().joinWithSeparator("")
            
            /// Check if existing convo between the proxies exists
            self.ref.child(Path.Convos).child(senderProxy.ownerId).queryEqualToValue(convoKey).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                
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
            
            /// Sender updates
            self.set(timestamp, a: Path.Proxies, b: convo.senderId, c: convo.senderProxy, d: Path.Timestamp)
            self.setConvoValuesOnMessageSend(convo.senderId, proxy: convo.senderProxy, convo: convo.key, timestamp: timestamp, unread: 0, messagePath: Path.MessagesSent)
            
            /// Receiver updates
            if !convo.receiverIsBlocking {
                self.set(timestamp, a: Path.Proxies, b: convo.receiverId, c: convo.receiverProxy, d: Path.Timestamp)
            }
            self.setConvoValuesOnMessageSend(convo.receiverId, proxy: convo.receiverProxy, convo: convo.key, timestamp: timestamp, unread: receiverIsPresent ? 0 : 1, messagePath: Path.MessagesReceived)
            
            /// Write message
            let messageKey = self.ref.child(Path.Messages).child(convo.key).childByAutoId().key
            let timeRead = receiverIsPresent ? timestamp : 0.0
            let message = Message(key: messageKey, convo: convo.key, mediaType: mediaType, read: receiverIsPresent, timeRead: timeRead, senderId: convo.senderId, date: timestamp, text: text)
            self.set(message.toAnyObject(), a: Path.Messages, b: convo.key, c: messageKey, d: nil)
            
            completion(convo: convo, message: message)
        }
    }
    
    /// Sets `timestamp`, and `didLeaveConvo` for both copies of convo.
    /// Increments unread by `unread`.
    /// Increments `messagePath` by 1.
    func setConvoValuesOnMessageSend(user: String, proxy: String, convo: String, timestamp: Double, unread: Int, messagePath: String) {
        self.set(false, a: Path.Convos, b: user, c: convo, d: Path.DidLeaveConvo)
        self.set(false, a: Path.Convos, b: proxy, c: convo, d: Path.DidLeaveConvo)
        self.set(timestamp, a: Path.Convos, b: user, c: convo, d: Path.Timestamp)
        self.set(timestamp, a: Path.Convos, b: proxy, c: convo, d: Path.Timestamp)
        self.increment(amount: unread, a: Path.Unread, b: user, c: proxy, d: convo)
        self.increment(amount: 1, a: messagePath, b: user, c: messagePath, d: nil)
    }
    
    /// Returns a Bool indicating whether or not a user is in a convo.
    func userIsPresent(user user: String, convo: String, completion: (userIsPresent: Bool) -> Void) {
        ref.child(Path.Present).child(convo).child(user).child(Path.Present).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            completion(userIsPresent: snapshot.value as? Bool ?? false)
        })
    }
    
    /// Sets the message's `read` to true.
    /// Gives the message a current `timeRead`.
    /// Decrements `user`'s convo's unread by 1.
    func setRead(forMessage message: Message, forUser user: String, forProxy proxy: String) {
        set(true, a: Path.Messages, b: message.convo, c: message.key, d: Path.Read)
        set(NSDate().timeIntervalSince1970, a: Path.Messages, b: message.convo, c: message.key, d: Path.TimeRead)
        increment(amount: -1, a: Path.Unread, b: user, c: proxy, d: message.convo)
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
    func getConvo(withKey key: String, belongingToUser user: String, completion: (convo: Convo) -> Void) {
        ref.child(Path.Convos).child(user).child(key).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            completion(convo: Convo(anyObject: snapshot.value!))
        })
    }
    
    /// Update the receiver's nickname for the convo.
    /// (Only the sender sees this nickname).
    func set(nickname nickname: String, forReceiverInConvo convo: Convo) {
        set(nickname, a: Path.Nickname, b: convo.senderId, c: convo.key, d: Path.Nickname)
    }
    
    /// Returns an array of Convo's.
    /// Filters out convos we don't want to see.
    func getConvos(fromSnapshot snapshot: FIRDataSnapshot) -> [Convo] {
        var convos = [Convo]()
        for child in snapshot.children {
            let convo = Convo(anyObject: child.value)
            if !convo.didLeaveConvo && !convo.senderDidDeleteProxy && !convo.senderIsBlocking {
                convos.append(convo)
            }
        }
        return convos.reverse()
    }
    
    /// Leaves a convo.
    func leave(convo convo: Convo) {
        set(true, a: Path.Convos, b: convo.senderId, c: convo.key, d: Path.DidLeaveConvo)
        set(true, a: Path.Convos, b: convo.senderProxy, c: convo.key, d: Path.DidLeaveConvo)
    }
    
    // When you mute a convo, you stop getting push notifications for it.
    // TODO: Implement when get to push notifications
    func muteConvo() {}
}
