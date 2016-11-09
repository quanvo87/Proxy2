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
import JSQMessagesViewController

class API {
    static let sharedInstance = API()
    
    var uid = ""
    let ref = FIRDatabase.database().reference()
    let storageRef = FIRStorage.storage().referenceForURL(URLs.Storage)
    
    var proxyCount = -1
    var isCreatingProxy = false
    let dispatch_group = dispatch_group_create()
    var proxyNameGenerator = ProxyNameGenerator()
    var icons = [String]()
    var iconURLCache = [String: NSURL]()
    
    private init() {}
    
    // MARK: - Utility
    
    /// Returns the Firebase reference with path `a`/`b`/`c`/`d`.
    /// Leave unneeded nodes blank starting from `d`, working back to `a`.
    /// There must be at least node `a`, else returns nil.
    func getRef(a: String, b: String?, c: String?, d: String?) -> FIRDatabaseReference? {
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
    /// Leave unneeded nodes blank starting from `d`, working back to `a`.
    /// There must be at least node `a`.
    func set(anyObject: AnyObject, a: String, b: String?, c: String?, d: String?) {
        if let ref = getRef(a, b: b, c: c, d: d) {
            ref.setValue(anyObject)
        }
    }
    
    /// Deletes object under `a`/`b`/`c`/`d`.
    /// Leave unneeded nodes blank starting from `d`, working back to `a`.
    /// There must be at least node `a`.
    func delete(a: String, b: String?, c: String?, d: String?) {
        if let ref = getRef(a, b: b, c: c, d: d) {
            ref.removeValue()
        }
    }
    
    /// Increments object at `a`/`b`/`c`/`d` by `amount`.
    /// Leave unneeded nodes blank starting from `d`, working back to `a`.
    /// There must be at least node `a`.
    func increment(amount: Int, a: String, b: String?, c: String?, d: String?) {
        if let ref = getRef(a, b: b, c: c, d: d) {
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
    
    /// Returns the UIImage for `url`.
    func getUIImage(fromURL url: NSURL, completion: (image: UIImage?) -> Void) {
        guard let urlString = url.absoluteString else { return }
        
        // Check cache first.
        KingfisherManager.sharedManager.cache.retrieveImageForKey(urlString, options: nil) { (image, cacheType) -> () in
            if let image = image {
                completion(image: image)
                return
            }
        
            // Not in cache, retrieve online.
            KingfisherManager.sharedManager.downloader.downloadImageWithURL(url, progressBlock: nil) { (image, error, imageURL, originalData) -> () in
                guard let image = image else {
                    completion(image: nil)
                    return
                }
                KingfisherManager.sharedManager.cache.storeImage(image, forKey: urlString, toDisk: true, completionHandler: nil)
                completion(image: image)
            }
        }
    }
    
    /// Returns the UIImage for `icon`.
    func getUIImage(forIcon icon: String, completion: (image: UIImage?) -> Void) {
        
        // Get url for icon in storage.
        getURL(forIcon: icon, completion: { (url) in
            guard let url = url else { return }
                
            // Get image from url.
            self.getUIImage(fromURL: url, completion: { (image) in
                guard let image = image else {
                    completion(image: nil)
                    return
                }
                completion(image: image)
            })
        })
    }
    
    /// Returns the NSURL for `icon`.
    func getURL(forIcon icon: String, completion: (url: NSURL?) -> Void) {
        
        // Check cache first.
        if let url = iconURLCache[icon] {
            completion(url: url)
            
        // Else get url from storage.
        } else {
            let iconRef = storageRef.child(Path.Icons).child("\(icon).png")
            iconRef.downloadURLWithCompletion { (url, error) -> Void in
                guard error == nil, let url = url else {
                    completion(url: nil)
                    return
                }
                self.iconURLCache[icon] = url
                completion(url: url)
            }
        }
    }
    
    /// Uploads compressed version of `image` to storage.
    /// Returns NSURL to the image in storage.
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
        
        // Compress video.
        let compressedURL = NSURL.fileURLWithPath(NSTemporaryDirectory() + NSUUID().UUIDString + ".m4v")
        compressVideo(fromURL: url, toURL: compressedURL) { (session) in
            if session.status == .Completed {
                
                // Upload to storage.
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
    
    func loadProxyCount(completion: () -> ()) {
        ref.child(Path.ProxyCount).child(uid).child(Path.ProxyCount).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            let value = snapshot.value
            self.proxyCount = value as? Int ?? 0
            completion()
        })
    }
    
    func updateProxyCount(amount: Int, completion: () -> ()) {
        ref.child(Path.ProxyCount).child(uid).child(Path.ProxyCount).runTransactionBlock( { (currentData: FIRMutableData) -> FIRTransactionResult in
            if let value = currentData.value {
                let _value = (value as? Int ?? 0) + amount
                currentData.value = _value
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        }) { (error, committed, snapshot) in
            guard error == nil else { return }
            self.proxyCount = snapshot?.value as! Int
            completion()
        }
    }
    
    /// Gives a user access to the default icons.
    func setDefaultIcons(forUser user: String) {
        let defaultIcons = DefaultIcons(id: user).defaultIcons
        ref.updateChildValues(defaultIcons as! [NSObject : AnyObject])
    }
    
    func loadIcons() {
        dispatch_group_enter(dispatch_group)
        ref.child(Path.Icons).child(uid).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            for child in snapshot.children {
                self.icons.append(child.value[Path.Name] as! String)
            }
            dispatch_group_leave(self.dispatch_group)
        })
    }
    
    /// Returns a random icon name from the user's available icons.
    func getRandomIcon() -> String {
        let count = UInt32(icons.count)
        return icons[Int(arc4random_uniform(count))]
    }
    
    func blockReceiverInConvo(convo: Convo) {
    
        // Add receiver to sender's blocked list
        let blockedUser = BlockedUser(id: convo.receiverId, icon: convo.icon, name: convo.receiverProxy, nickname: convo.receiverNickname)
        set(blockedUser.toAnyObject(), a: Path.Blocked, b: uid, c: convo.receiverId, d: nil)
        
        // Loop through sender's convos
        getConvos(convo.senderId) { (convos) in
            for _convo in convos {
                
                // For any convo with receiver
                if _convo.receiverId == convo.receiverId {
                    
                    // Set senderIsBlocking to true for sender's versions
                    self.set(true, a: Path.Convos, b: _convo.senderId, c: _convo.key, d: Path.SenderIsBlocking)
                    self.set(true, a: Path.Convos, b: _convo.senderProxy, c: _convo.key, d: Path.SenderIsBlocking)
                    
                    // Set receiverIsBlocking to true for receiver's versions
                    self.set(true, a: Path.Convos, b: _convo.receiverId, c: _convo.key, d: Path.ReceiverIsBlocking)
                    self.set(true, a: Path.Convos, b: _convo.receiverProxy, c: _convo.key, d: Path.ReceiverIsBlocking)
                
                    // Decrement unreads by convo's unread
                    self.increment(-_convo.unread, a: Path.Unread, b: _convo.senderId, c: Path.Unread, d: nil)
                    self.increment(-_convo.unread, a: Path.Proxies, b: _convo.senderId, c: _convo.senderProxy, d: Path.Unread)
                }
            }
        }
    }
    
    func unblockUser(blockedUser: String) {
        delete(Path.Blocked, b: uid, c: blockedUser, d: nil)
        
        getConvos(uid) { (convos) in
            for convo in convos {
                if convo.receiverId == blockedUser {
                    
                    self.set(false, a: Path.Convos, b: convo.senderId, c: convo.key, d: Path.SenderIsBlocking)
                    self.set(false, a: Path.Convos, b: convo.senderProxy, c: convo.key, d: Path.SenderIsBlocking)
                    
                    self.set(false, a: Path.Convos, b: convo.receiverId, c: convo.key, d: Path.ReceiverIsBlocking)
                    self.set(false, a: Path.Convos, b: convo.receiverProxy, c: convo.key, d: Path.ReceiverIsBlocking)
                    
                    self.increment(convo.unread, a: Path.Unread, b: convo.senderId, c: Path.Unread, d: nil)
                    self.increment(convo.unread, a: Path.Proxies, b: convo.senderId, c: convo.senderProxy, d: Path.Unread)
                }
            }
        }
    }
    
    // MARK: - Proxy
    
    func loadCreateProxyInfo(completion: () -> Void) {
        loadProxyNameGenerator()
        loadIcons()
        dispatch_group_notify(dispatch_group, dispatch_get_main_queue()) {
            completion()
        }
    }
    
    /// Returns a new proxy with a unique name.
    func create(proxy completion: (proxy: Proxy?) -> Void) {
        if proxyCount < 0 {
            loadProxyCount({ 
                if self.proxyCount > 49 {
                    completion(proxy: nil)
                } else {
                    self.loadCreateProxyInfo({
                        self.isCreatingProxy = true
                        self.tryCreating(proxy: { (proxy) in
                            completion(proxy: proxy)
                        })
                    })
                }
            })
        } else {
            if proxyCount > 49 {
                completion(proxy: nil)
            } else {
                isCreatingProxy = true
                tryCreating(proxy: { (proxy) in
                    completion(proxy: proxy)
                })
            }
        }
    }
    
    /// Loads proxyNameGenerator and returns a new proxy.
    func loadProxyNameGenerator() {
        dispatch_group_enter(dispatch_group)
        ref.child(Path.WordBank).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            if let words = snapshot.value, let adjs = words["adjectives"], let nouns = words["nouns"] {
                self.proxyNameGenerator.adjs = adjs as! [String]
                self.proxyNameGenerator.nouns = nouns as! [String]
                dispatch_group_leave(self.dispatch_group)
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
        ref.child(Path.Proxies).queryOrderedByChild(Path.Key).queryEqualToValue(key.lowercaseString).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            
            // If there's only one, we've got a unique proxy name.
            if snapshot.childrenCount == 1 {
                
                // Stop trying to create a proxy.
                self.isCreatingProxy = false
                
                // Re-save the global proxy by name instead of the Firebase key.
                self.delete(Path.Proxies, b: uniqueKey, c: nil, d: nil)
                self.set(proxy.toAnyObject(), a: Path.Proxies, b: key.lowercaseString, c: nil, d: nil)
                
                // Create the user's copy of the proxy with a random icon.
                let proxy = Proxy(key: key, ownerId: self.uid, icon: self.getRandomIcon())
                
                // Save the user's proxy.
                self.set(proxy.toAnyObject(), a: Path.Proxies, b: self.uid, c: key, d: nil)
                
                // Increment proxyCount
                self.updateProxyCount(1, completion: { 
                    completion(proxy: proxy)
                })
            } else {
                
                // Else name is taken so delete the proxy you just created.
                self.delete(Path.Proxies, b: uniqueKey, c: nil, d: nil)
                
                // Check if user has cancelled the process.
                if self.isCreatingProxy {
                    
                    // If not, try the process again.
                    self.tryCreating(proxy: { (proxy) in
                        completion(proxy: proxy)
                    })
                }
            }
        })
    }
    
    /// Stop trying to create a proxy.
    func cancelCreatingProxy() {
        isCreatingProxy = false
    }
    
    /// Returns the global Proxy with `key`.
    func getProxy(key: String, completion: (proxy: Proxy?) -> Void) {
        ref.child(Path.Proxies).child(key).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            let proxy = Proxy(anyObject: snapshot.value!)
            if proxy.key == "" {
                completion(proxy: nil)
            } else {
                completion(proxy: proxy)
            }
        })
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
    
    func delete(proxy proxy: Proxy) {
        getConvos(forProxy: proxy) { (convos) in
            self.delete(proxy: proxy, withConvos: convos)
        }
    }
    
    func delete(proxy proxy: Proxy, withConvos convos: [Convo]) {
        
        // Delete the global proxy
        delete(Path.Proxies, b: proxy.key.lowercaseString, c: nil, d: nil)
        
        // Delete proxy
        delete(Path.Proxies, b: uid, c: proxy.key, d: nil)
        
        // Decrement user's proxy count
        updateProxyCount(-1) {}
        
        // Decrement user's unread by the proxy's unread
        increment(-proxy.unread, a: Path.Unread, b: proxy.ownerId, c: Path.Unread, d: nil)
        
        // Loop through the proxy's convos
        for convo in convos {
            
            // Delete sender's convos
            self.delete(Path.Convos, b: convo.senderId, c: convo.key, d: nil)
            self.delete(Path.Convos, b: convo.senderProxy, c: convo.key, d: nil)
            
            // Set convo to deleted for receiver convos
            self.set(true, a: Path.Convos, b: convo.receiverId, c: convo.key, d: Path.ReceiverDeletedProxy)
            self.set(true, a: Path.Convos, b: convo.receiverProxy, c: convo.key, d: Path.ReceiverDeletedProxy)
        }
    }
    
    // MARK: - Message
    
    func sendMessage(sender: Proxy, receiver: Proxy, text: String, completion: (convo: Convo) -> Void) {
        let convoKey = createConvoKey(sender.key, senderOwner: sender.ownerId, receiverKey: receiver.key, receiverOwner: receiver.ownerId)
        
        // Check if convo exists
        ref.child(Path.Convos).child(sender.ownerId).queryEqualToValue(convoKey).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            
            // Convo exists, use it to send the message
            if snapshot.childrenCount == 1 {
                let convo = Convo(anyObject: snapshot.value!)
                self.sendMessage(withText: text, withMediaType: "", usingSenderConvo: convo, completion: { (convo, message) in
                    completion(convo: convo)
                })
            }
            
            // Convo does not exist, create the convo before sending message
            self.createConvo(sender, receiver: receiver, convoKey: convoKey, text: text, completion: { (convo) in
                self.sendMessage(withText: text, withMediaType: "", usingSenderConvo: convo, completion: { (convo, message) in
                    completion(convo: convo)
                })
            })
        })
    }
    
    func sendMessage(withText text: String, withMediaType mediaType: String, usingSenderConvo convo: Convo, completion: (convo: Convo, message: Message) -> Void) {
        
        // Check if receiver is present to mark message as read
        userIsPresent(user: convo.receiverId, convo: convo.key) { (receiverIsPresent) in
            let timestamp = NSDate().timeIntervalSince1970
            
            // Sender updates
            self.set(timestamp, a: Path.Proxies, b: convo.senderId, c: convo.senderProxy, d: Path.Timestamp)
            self.setConvoValuesOnMessageSend(convo.senderId, proxy: convo.senderProxy, convo: convo.key, message: "You: \(text)", timestamp: timestamp)
            if convo.senderLeftConvo {
                self.set(false, a: Path.Convos, b: convo.senderId, c: convo.key, d: Path.SenderLeftConvo)
                self.set(false, a: Path.Convos, b: convo.senderProxy, c: convo.key, d: Path.SenderLeftConvo)
                self.set(false, a: Path.Convos, b: convo.receiverId, c: convo.key, d: Path.ReceiverLeftConvo)
                self.set(false, a: Path.Convos, b: convo.receiverProxy, c: convo.key, d: Path.ReceiverLeftConvo)
                self.increment(1, a: Path.Proxies, b: convo.senderId, c: convo.senderProxy, d: Path.Convos)
            }
            self.increment(1, a: Path.MessagesSent, b: convo.senderId, c: Path.MessagesSent, d: nil)
            
            // Receiver updates
            if !convo.receiverDeletedProxy && !convo.receiverIsBlocking {
                self.set(text, a: Path.Proxies, b: convo.receiverId, c: convo.receiverProxy, d: Path.Message)
                self.set(timestamp, a: Path.Proxies, b: convo.receiverId, c: convo.receiverProxy, d: Path.Timestamp)
                if receiverIsPresent {
                    self.increment(1, a: Path.Proxies, b: convo.receiverId, c: convo.receiverProxy, d: Path.Unread)
                    self.increment(1, a: Path.Unread, b: convo.receiverId, c: Path.Unread, d: nil)
                }
            }
            if !convo.receiverDeletedProxy {
                self.setConvoValuesOnMessageSend(convo.receiverId, proxy: convo.receiverProxy, convo: convo.key, message: text, timestamp: timestamp)
                if receiverIsPresent {
                    self.increment(1, a: Path.Convos, b: convo.receiverId, c: convo.key, d: Path.Unread)
                    self.increment(1, a: Path.Convos, b: convo.receiverProxy, c: convo.key, d: Path.Unread)
                }
            }
            if convo.receiverLeftConvo {
                self.set(false, a: Path.Convos, b: convo.senderId, c: convo.key, d: Path.ReceiverLeftConvo)
                self.set(false, a: Path.Convos, b: convo.senderProxy, c: convo.key, d: Path.ReceiverLeftConvo)
                self.set(false, a: Path.Convos, b: convo.receiverId, c: convo.key, d: Path.SenderLeftConvo)
                self.set(false, a: Path.Convos, b: convo.receiverProxy, c: convo.key, d: Path.SenderLeftConvo)
                self.increment(1, a: Path.Proxies, b: convo.receiverId, c: convo.receiverProxy, d: Path.Convos)
            }
            self.increment(1, a: Path.MessagesReceived, b: convo.receiverId, c: Path.MessagesReceived, d: nil)
            
            // Write message
            let messageKey = self.ref.child(Path.Messages).child(convo.key).childByAutoId().key
            let timeRead = receiverIsPresent ? timestamp : 0.0
            let message = Message(key: messageKey, convo: convo.key, mediaType: mediaType, read: receiverIsPresent, timeRead: timeRead, senderId: convo.senderId, date: timestamp, text: text)
            self.set(message.toAnyObject(), a: Path.Messages, b: convo.key, c: messageKey, d: nil)
            
            completion(convo: convo, message: message)
        }
    }
    
    /// Sets `message` & `timestamp` for `user`'s `convo`.
    func setConvoValuesOnMessageSend(user: String, proxy: String, convo: String, message: String, timestamp: Double) {
        set(message, a: Path.Convos, b: user, c: convo, d: Path.Message)
        set(message, a: Path.Convos, b: proxy, c: convo, d: Path.Message)
        set(timestamp, a: Path.Convos, b: user, c: convo, d: Path.Timestamp)
        set(timestamp, a: Path.Convos, b: proxy, c: convo, d: Path.Timestamp)
    }
    
    /// Sets `message`'s `read` & `timeRead`.
    /// Decrements unread's for `user`.
    func setRead(forMessage message: Message, forUser user: String, forProxy proxy: String) {
        let ref = getRef(Path.Messages, b: message.convo, c: message.key, d: nil)
        let update = [Path.TimeRead: NSDate().timeIntervalSince1970, Path.Read: true]
        ref!.updateChildValues(update as [NSObject : AnyObject])
        increment(-1, a: Path.Unread, b: user, c: Path.Unread, d: nil)
        increment(-1, a: Path.Proxies, b: user, c: proxy, d: Path.Unread)
        increment(-1, a: Path.Convos, b: user, c: message.convo, d: Path.Unread)
        increment(-1, a: Path.Convos, b: proxy, c: message.convo, d: Path.Unread)
    }
    
    /// Sets `message`'s `mediaType` and `mediaURL`.
    func setMedia(forMessage message: Message, mediaType: String, mediaURL: String) {
        set(mediaType, a: Path.Messages, b: message.convo, c: message.key, d: Path.MediaType)
        set(mediaURL, a: Path.Messages, b: message.convo, c: message.key, d: Path.MediaURL)
    }
    
    // MARK: - Conversation (Convo)
    
    func createConvoKey(senderKey: String, senderOwner: String, receiverKey: String, receiverOwner: String) -> String {
        return [senderKey, senderOwner, receiverKey, receiverOwner].sort().joinWithSeparator("")
    }
    
    func createConvo(sender: Proxy, receiver: Proxy, convoKey: String, text: String, completion: (convo: Convo) -> Void) {
        
        // Check if sender is in receiver's blocked list
        ref.child(Path.Blocked).child(receiver.ownerId).child(sender.ownerId).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            var senderConvo = Convo()
            var receiverConvo = Convo()
            let senderBlocked = snapshot.childrenCount == 1
            
            // Set up sender side
            senderConvo.key = convoKey
            senderConvo.senderId = sender.ownerId
            senderConvo.senderProxy = sender.key
            senderConvo.receiverId = receiver.ownerId
            senderConvo.receiverProxy = receiver.key
            senderConvo.icon = receiver.icon
            senderConvo.receiverIsBlocking = senderBlocked
            let senderConvoAnyObject = senderConvo.toAnyObject()
            self.set(senderConvoAnyObject, a: Path.Convos, b: senderConvo.senderId, c: senderConvo.key, d: nil)
            self.set(senderConvoAnyObject, a: Path.Convos, b: senderConvo.senderProxy, c: senderConvo.key, d: nil)
            self.increment(1, a: Path.ProxiesInteractedWith, b: sender.ownerId, c: Path.ProxiesInteractedWith, d: nil)
            
            // Set up receiver side
            receiverConvo.key = convoKey
            receiverConvo.senderId = receiver.ownerId
            receiverConvo.senderProxy = receiver.key
            receiverConvo.receiverId = sender.ownerId
            receiverConvo.receiverProxy = sender.key
            receiverConvo.icon = sender.icon
            receiverConvo.senderIsBlocking = senderBlocked
            let receiverConvoAnyObject = receiverConvo.toAnyObject()
            self.set(receiverConvoAnyObject, a: Path.Convos, b: receiverConvo.senderId, c: receiverConvo.key, d: nil)
            self.set(receiverConvoAnyObject, a: Path.Convos, b: receiverConvo.senderProxy, c: receiverConvo.key, d: nil)
            self.increment(1, a: Path.ProxiesInteractedWith, b: receiver.ownerId, c: Path.ProxiesInteractedWith, d: nil)
            
            completion(convo: senderConvo)
        })
    }
    
    func getConvo(withKey key: String, belongingToUser user: String, completion: (convo: Convo?) -> Void) {
        ref.child(Path.Convos).child(user).child(key).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            let convo = Convo(anyObject: snapshot.value!)
            if convo.key == "" {
                completion(convo: nil)
            } else {
                completion(convo: convo)
            }
        })
    }
    
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
    
    func getConvos(user: String, completion: (convos: [Convo]) -> Void) {
        ref.child(Path.Convos).child(user).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            var convos = [Convo]()
            for child in snapshot.children {
                let convo = Convo(anyObject: child.value)
                convos.append(convo)
            }
            completion(convos: convos)
        })
    }
    
    /// Returns an array of Convo's from `snapshot`.
    /// Filters out Convo's that should not be shown.
    func getConvos(fromSnapshot snapshot: FIRDataSnapshot) -> [Convo] {
        var convos = [Convo]()
        for child in snapshot.children {
            let convo = Convo(anyObject: child.value)
            if !convo.senderLeftConvo && !convo.senderIsBlocking {
                convos.append(convo)
            }
        }
        return convos.reverse()
    }
    
    /// Returns a Convo title.
    func getConvoTitle(receiverNickname receiverNickname: String, receiverName: String, senderNickname: String, senderName: String) -> NSAttributedString {
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
    
    /// Sets `nickname` for `convo`.
    /// (Only the sender sees this nickname).
    func set(nickname nickname: String, forReceiverInConvo convo: Convo) {
        set(nickname, a: Path.Convos, b: convo.senderId, c: convo.key, d: Path.ReceiverNickname)
        set(nickname, a: Path.Convos, b: convo.senderProxy, c: convo.key, d: Path.ReceiverNickname)
    }
    
    /// Returns a Bool indicating whether or not `user` is currently in `convo`.
    func userIsPresent(user user: String, convo: String, completion: (userIsPresent: Bool) -> Void) {
        ref.child(Path.Present).child(convo).child(user).child(Path.Present).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            completion(userIsPresent: snapshot.value as? Bool ?? false)
        })
    }
    
    /// Leaves a convo.
    func leave(convo convo: Convo) {
        set(true, a: Path.Convos, b: convo.senderId, c: convo.key, d: Path.SenderLeftConvo)
        set(true, a: Path.Convos, b: convo.senderProxy, c: convo.key, d: Path.SenderLeftConvo)
        set(true, a: Path.Convos, b: convo.receiverId, c: convo.key, d: Path.ReceiverLeftConvo)
        set(true, a: Path.Convos, b: convo.receiverProxy, c: convo.key, d: Path.ReceiverLeftConvo)
        set(0, a: Path.Convos, b: convo.senderId, c: convo.key, d: Path.Unread)
        set(0, a: Path.Convos, b: convo.senderProxy, c: convo.key, d: Path.Unread)
        increment(-1, a: Path.Proxies, b: convo.senderId, c: convo.senderProxy, d: Path.Convos)
        increment(-convo.unread, a: Path.Unread, b: convo.senderId, c: Path.Unread, d: nil)
        increment(-convo.unread, a: Path.Proxies, b: convo.senderId, c: convo.senderProxy, d: Path.Unread)
    }
}
