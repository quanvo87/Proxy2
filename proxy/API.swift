//
//  API.swift
//  proxy
//
//  Created by Quan Vo on 8/15/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import AVFoundation
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import JSQMessagesViewController

class API {
    
    static let sharedInstance = API()
    
    var uid = ""
    let ref = FIRDatabase.database().reference()
    let storageRef = FIRStorage.storage().reference(forURL: URLs.Storage)
    var proxyNameGenerator = ProxyNameGenerator()
    var icons = [String]()
    var iconURLCache = [String: URL]()
    let dispatch_group = DispatchGroup()
    var createProxyInfoIsLoaded = false
    var isCreatingProxy = false
    
    fileprivate init() {}
    
    // MARK: - Utility
    
    /// Returns the Firebase reference with path `a`/`b`/`c`/`d`.
    /// Leave unneeded nodes blank starting from `d`, working back to `a`.
    /// There must be at least node `a`, else returns nil.
    func getRef(_ a: String, b: String?, c: String?, d: String?) -> FIRDatabaseReference? {
        guard a != "" else { return nil }
        if let b = b, let c = c, let d = d, b != "" && c != "" && d != "" {
            return ref.child(a).child(b).child(c).child(d)
        }
        if let b = b, let c = c, b != "" && c != "" {
            return ref.child(a).child(b).child(c)
        }
        if let b = b, b != "" {
            return ref.child(a).child(b)
        }
        return ref.child(a)
    }
    
    /// Saves `anyObject` under `a`/`b`/`c`/`d`.
    /// Leave unneeded nodes blank starting from `d`, working back to `a`.
    /// There must be at least node `a`.
    func set(_ anyObject: AnyObject, a: String, b: String?, c: String?, d: String?) {
        if let ref = getRef(a, b: b, c: c, d: d) {
            ref.setValue(anyObject)
        }
    }
    
    /// Deletes object under `a`/`b`/`c`/`d`.
    /// Leave unneeded nodes blank starting from `d`, working back to `a`.
    /// There must be at least node `a`.
    func delete(_ a: String, b: String?, c: String?, d: String?) {
        if let ref = getRef(a, b: b, c: c, d: d) {
            ref.removeValue()
        }
    }
    
    /// Increments object at `a`/`b`/`c`/`d` by `amount`.
    /// Leave unneeded nodes blank starting from `d`, working back to `a`.
    /// There must be at least node `a`.
    func increment(_ amount: Int, a: String, b: String?, c: String?, d: String?) {
        if let ref = getRef(a, b: b, c: c, d: d) {
            ref.runTransactionBlock( { (currentData: FIRMutableData) -> FIRTransactionResult in
                if let value = currentData.value {
                    var _value = value as? Int ?? 0
                    _value += amount
                    currentData.value = _value > 0 ? _value : 0
                    return FIRTransactionResult.success(withValue: currentData)
                }
                return FIRTransactionResult.success(withValue: currentData)
            })
        }
    }
    
    /// Returns the UIImage for `url`.
    func getUIImage(fromURL url: URL, completion: @escaping (_ image: UIImage) -> Void) {
        KingfisherManager.shared.cache.retrieveImage(forKey: url.absoluteString, options: nil) { (image, cachType) in
            if let image = image {
                completion(image)
            } else {
                KingfisherManager.shared.downloader.downloadImage(with: url, options: nil, progressBlock: nil, completionHandler: { (image, error, imageURL, data) in
                    guard error == nil, let image = image else { return }
                    completion(image)
                    KingfisherManager.shared.cache.store(image, original: nil, forKey: url.absoluteString, toDisk: true, completionHandler: nil)
                })
            }
        }
    }
    
    /// Returns the UIImage for `icon`.
    func getUIImage(forIcon icon: String, completion: @escaping (_ image: UIImage) -> Void) {
        
        // Get url for icon in storage.
        getURL(forIcon: icon, completion: { (url) in
            
            // Get image from url.
            self.getUIImage(fromURL: url, completion: { (image) in
                completion(image)
            })
        })
    }
    
    /// Returns the NSURL for `icon`.
    func getURL(forIcon icon: String, completion: @escaping (_ url: URL) -> Void) {
        
        // Check cache first.
        if let url = iconURLCache[icon] {
            completion(url)
            
            // Else get url from storage.
        } else {
            storageRef.child(Path.Icons).child("\(icon).png").downloadURL { (url, error) -> Void in
                if error == nil, let url = url {
                    self.iconURLCache[icon] = url
                    completion(url)
                }
            }
        }
    }
    
    /// Uploads compressed version of `image` to storage.
    /// Returns NSURL to the image in storage.
    func upload(image: UIImage, completion: @escaping (_ url: URL) -> Void) {
        guard let data = UIImageJPEGRepresentation(image, 0) else { return }
        storageRef.child(Path.UserFiles).child(uid + String(Date().timeIntervalSince1970)).put(data, metadata: nil) { (metadata, error) in
            guard error == nil, let url = metadata?.downloadURL() else { return }
            completion(url)
            KingfisherManager.shared.cache.store(image, forKey: url.absoluteString, toDisk: true, completionHandler: nil)
        }
    }
    
    /// Uploads compressed version of video to storage.
    /// Returns url to the video in storage.
    func uploadVideo(fromURL url: URL, completion: @escaping (_ url: URL) -> Void) {
        
        // Compress video.
        let compressedURL = URL(fileURLWithPath: NSTemporaryDirectory() + UUID().uuidString + ".m4v")
        compressVideo(fromURL: url, toURL: compressedURL) { (session) in
            if session.status == .completed {
                
                // Upload to storage.
                self.storageRef.child(Path.UserFiles).child(String(Date().timeIntervalSince1970)).putFile(compressedURL, metadata: nil) { metadata, error in
                    guard error == nil, let url = metadata?.downloadURL() else { return }
                    completion(url)
                }
            }
        }
    }
    
    /// Compresses a video. Returns the export session.
    func compressVideo(fromURL url: URL, toURL outputURL: URL, handler: @escaping (_ session: AVAssetExportSession) -> Void) {
        let urlAsset = AVURLAsset(url: url, options: nil)
        if let exportSession = AVAssetExportSession(asset: urlAsset, presetName: AVAssetExportPresetMediumQuality) {
            exportSession.outputFileType = AVFileTypeQuickTimeMovie
            exportSession.outputURL = outputURL
            exportSession.shouldOptimizeForNetworkUse = true
            exportSession.exportAsynchronously { () -> Void in
                handler(exportSession)
            }
        }
    }
    
    // MARK: - User
    
    /// Gives a user access to the default icons.
    func setDefaultIcons(forUser user: String) {
        let defaultIcons = DefaultIcons(id: user).defaultIcons
        ref.updateChildValues(defaultIcons as! [AnyHashable: Any])
    }
    
    func loadIcons() {
        dispatch_group.enter()
        ref.child(Path.Icons).child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            for child in snapshot.children {
                self.icons.append(((child as! FIRDataSnapshot).value as AnyObject)[Path.Name] as! String)
            }
            self.dispatch_group.leave()
        })
    }
    
    /// Returns a random icon name from the user's available icons.
    func getRandomIcon() -> String {
        let count = UInt32(icons.count)
        return icons[Int(arc4random_uniform(count))]
    }
    
    func blockReceiverInConvo(_ convo: Convo) {
        
        // Add receiver to sender's blocked list
        let blockedUser = BlockedUser(id: convo.receiverId, icon: convo.icon, name: convo.receiverProxyKey, nickname: convo.receiverNickname)
        set(blockedUser.toAnyObject() as AnyObject, a: Path.Blocked, b: uid, c: convo.receiverId, d: nil)
        
        // Loop through sender's convos
        getConvos(convo.senderId) { (convos) in
            for _convo in convos {
                
                // For any convo with receiver
                if _convo.receiverId == convo.receiverId {
                    
                    // Set senderIsBlocking to true for sender's versions
                    self.set(true as AnyObject, a: Path.Convos, b: _convo.senderId, c: _convo.key, d: Path.SenderIsBlocking)
                    self.set(true as AnyObject, a: Path.Convos, b: _convo.senderProxyKey, c: _convo.key, d: Path.SenderIsBlocking)
                    
                    // Set receiverIsBlocking to true for receiver's versions
                    self.set(true as AnyObject, a: Path.Convos, b: _convo.receiverId, c: _convo.key, d: Path.ReceiverIsBlocking)
                    self.set(true as AnyObject, a: Path.Convos, b: _convo.receiverProxyKey, c: _convo.key, d: Path.ReceiverIsBlocking)
                    
                    // Decrement unreads by convo's unread
                    self.increment(-_convo.unread, a: Path.Unread, b: _convo.senderId, c: Path.Unread, d: nil)
                    self.increment(-_convo.unread, a: Path.Proxies, b: _convo.senderId, c: _convo.senderProxyKey, d: Path.Unread)
                }
            }
        }
    }
    
    func unblockUser(_ blockedUser: String) {
        delete(Path.Blocked, b: uid, c: blockedUser, d: nil)
        
        getConvos(uid) { (convos) in
            for convo in convos {
                if convo.receiverId == blockedUser {
                    
                    self.set(false as AnyObject, a: Path.Convos, b: convo.senderId, c: convo.key, d: Path.SenderIsBlocking)
                    self.set(false as AnyObject, a: Path.Convos, b: convo.senderProxyKey, c: convo.key, d: Path.SenderIsBlocking)
                    
                    self.set(false as AnyObject, a: Path.Convos, b: convo.receiverId, c: convo.key, d: Path.ReceiverIsBlocking)
                    self.set(false as AnyObject, a: Path.Convos, b: convo.receiverProxyKey, c: convo.key, d: Path.ReceiverIsBlocking)
                    
                    self.increment(convo.unread, a: Path.Unread, b: convo.senderId, c: Path.Unread, d: nil)
                    self.increment(convo.unread, a: Path.Proxies, b: convo.senderId, c: convo.senderProxyKey, d: Path.Unread)
                }
            }
        }
    }
    
    // MARK: - Proxy
    
    func loadCreateProxyInfo(_ completion: @escaping () -> Void) {
        loadProxyNameGenerator()
        loadIcons()
        dispatch_group.notify(queue: DispatchQueue.main) {
            self.createProxyInfoIsLoaded = true
            completion()
        }
    }
    
    /// Returns a new proxy with a unique name.
    func create(proxy completion: @escaping (_ proxy: Proxy?) -> Void) {
        guard uid != "" else {
            completion(nil)
            return
        }
        ref.child(Path.Proxies).child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            guard snapshot.childrenCount <= 50 else {
                completion(nil)
                return
            }
            if !self.createProxyInfoIsLoaded {
                self.loadCreateProxyInfo({
                    self.isCreatingProxy = true
                    self.tryCreating(proxy: { (proxy) in
                        completion(proxy)
                    })
                })
            } else {
                self.isCreatingProxy = true
                self.tryCreating(proxy: { (proxy) in
                    completion(proxy)
                })
            }
        })
    }
    
    /// Load proxyNameGenerator.
    func loadProxyNameGenerator() {
        dispatch_group.enter()
        ref.child(Path.WordBank).observeSingleEvent(of: .value, with: { (snapshot) in
            let words = snapshot.value as AnyObject
            let adjs = words["adjectives"]
            let nouns = words["nouns"]
            self.proxyNameGenerator.adjs = adjs as! [String]
            self.proxyNameGenerator.nouns = nouns as! [String]
            self.dispatch_group.leave()
        })
    }
    
    /// Returns a new proxy with a unique name.
    func tryCreating(proxy completion: @escaping (_ proxy: Proxy) -> Void) {
        
        // Create a global proxy and save it.
        let autoId = ref.child(Path.Proxies).childByAutoId().key
        let name = proxyNameGenerator.generateProxyName()
        let key = name.lowercased()
        let proxy = Proxy(name: name, ownerId: self.uid)
        ref.child(Path.Proxies).child(autoId).setValue(proxy.toAnyObject()) { (error, proxyRef) in
            
            // Get all global proxies with this name.
            self.ref.child(Path.Proxies).queryOrdered(byChild: Path.Key).queryEqual(toValue: key).observeSingleEvent(of: .value, with: { (snapshot) in
                
                // If there's only one, we've got a unique proxy name.
                if snapshot.childrenCount == 1 {
                    
                    // Stop trying to create a proxy.
                    self.isCreatingProxy = false
                    
                    // Re-save the global proxy by name instead of the Firebase key.
                    self.delete(Path.Proxies, b: autoId, c: nil, d: nil)
                    self.set(proxy.toAnyObject() as AnyObject, a: Path.Proxies, b: key, c: nil, d: nil)
                    
                    // Create the user's copy of the proxy with a random icon.
                    let proxy = Proxy(name: name, ownerId: self.uid, icon: self.getRandomIcon())
                    
                    // Save the user's proxy.
                    self.set(proxy.toAnyObject() as AnyObject, a: Path.Proxies, b: self.uid, c: key, d: nil)
                    
                    completion(proxy)
                    
                } else {
                    
                    // Else name is taken so delete the proxy you just created.
                    self.delete(Path.Proxies, b: autoId, c: nil, d: nil)
                    
                    // Check if user has cancelled the process.
                    if self.isCreatingProxy {
                        
                        // If not, try the process again.
                        self.tryCreating(proxy: { (proxy) in
                            completion(proxy)
                        })
                    }
                }
            })
        }
    }
    
    /// Stop trying to create a proxy.
    func cancelCreatingProxy() {
        isCreatingProxy = false
    }
    
    /// Returns the Proxy with `key`.
    func getProxy(_ key: String, completion: @escaping (_ proxy: Proxy?) -> Void) {
        ref.child(Path.Proxies).child(key).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let proxy = Proxy(anyObject: snapshot.value! as AnyObject) else {
                completion(nil)
                return
            }
            self.getProxy(withKey: key, belongingToUser: proxy.ownerId, completion: { (proxy) in
                completion(proxy)
            })
        })
    }
    
    /// Returns the Proxy with `key` belonging to `user`.
    func getProxy(withKey key: String, belongingToUser user: String, completion: @escaping (_ proxy: Proxy) -> Void) {
        ref.child(Path.Proxies).child(user).child(key).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let proxy = Proxy(anyObject: snapshot.value! as AnyObject) else { return }
            completion(proxy)
        })
    }
    
    /// Sets a proxy's nickname.
    func set(nickname: String, forProxy proxy: Proxy) {
        
        // Set for proxy
        set(nickname as AnyObject, a: Path.Proxies, b: proxy.ownerId, c: proxy.key, d: Path.Nickname)
        
        // Set for both copies of convo for all convos this proxy is in
        getConvos(forProxy: proxy) { (convos) in
            for convo in convos {
                self.set(nickname as AnyObject, a: Path.Convos, b: convo.senderId, c: convo.key, d: Path.SenderNickname)
                self.set(nickname as AnyObject, a: Path.Convos, b: convo.senderProxyKey, c: convo.key, d: Path.SenderNickname)
            }
        }
    }
    
    /// Sets a proxy's icon.
    func set(icon: String, forProxy proxy: Proxy) {
        
        // Set for proxy
        set(icon as AnyObject, a: Path.Proxies, b: proxy.ownerId, c: proxy.key, d: Path.Icon)
        
        // Set for both copies of receiver's convo for all convos this proxy is in
        getConvos(forProxy: proxy) { (convos) in
            for convo in convos {
                self.set(icon as AnyObject, a: Path.Convos, b: convo.receiverId, c: convo.key, d: Path.Icon)
                self.set(icon as AnyObject, a: Path.Convos, b: convo.receiverProxyKey, c: convo.key, d: Path.Icon)
            }
        }
    }
    
    func delete(proxy: Proxy) {
        getConvos(forProxy: proxy) { (convos) in
            self.delete(proxy: proxy, withConvos: convos)
        }
    }
    
    func delete(proxy: Proxy, withConvos convos: [Convo]) {
        
        // Delete the global proxy
        delete(Path.Proxies, b: proxy.key.lowercased(), c: nil, d: nil)
        
        // Delete proxy
        delete(Path.Proxies, b: uid, c: proxy.key, d: nil)
        
        // Decrement user's unread by the proxy's unread
        increment(-proxy.unread, a: Path.Unread, b: proxy.ownerId, c: Path.Unread, d: nil)
        
        // Loop through the proxy's convos
        for convo in convos {
            
            // Delete sender's convos
            self.delete(Path.Convos, b: convo.senderId, c: convo.key, d: nil)
            self.delete(Path.Convos, b: convo.senderProxyKey, c: convo.key, d: nil)
            
            // Set convo to deleted for receiver convos
            self.set(true as AnyObject, a: Path.Convos, b: convo.receiverId, c: convo.key, d: Path.ReceiverDeletedProxy)
            self.set(true as AnyObject, a: Path.Convos, b: convo.receiverProxyKey, c: convo.key, d: Path.ReceiverDeletedProxy)
        }
    }
    
    // MARK: - Message
    
    func sendMessage(_ sender: Proxy, receiver: Proxy, text: String, completion: @escaping (_ convo: Convo) -> Void) {
        let convoKey = createConvoKey(sender.key, senderOwner: sender.ownerId, receiverKey: receiver.key, receiverOwner: receiver.ownerId)
        
        // Check if convo exists
        ref.child(Path.Convos).child(sender.ownerId).queryEqual(toValue: convoKey).observeSingleEvent(of: .value, with: { (snapshot) in
            
            // Convo exists, use it to send the message
            if snapshot.childrenCount == 1, let convo = Convo(anyObject: snapshot.value! as AnyObject) {
                self.sendMessage(withText: text, withMediaType: "", usingSenderConvo: convo, completion: { (convo, message) in
                    completion(convo)
                })
            
            // Convo does not exist, create the convo before sending message
            } else {
                self.createConvo(sender, receiver: receiver, convoKey: convoKey, text: text, completion: { (convo) in
                    self.sendMessage(withText: text, withMediaType: "", usingSenderConvo: convo, completion: { (convo, message) in
                        completion(convo)
                    })
                })
            }
        })
    }
    
    func sendMessage(withText text: String, withMediaType mediaType: String, usingSenderConvo convo: Convo, completion: @escaping (_ convo: Convo, _ message: Message) -> Void) {
        
        // Check if receiver is present to mark message as read
        userIsPresent(user: convo.receiverId, convo: convo.key) { (receiverIsPresent) in
            let timestamp = Date().timeIntervalSince1970
            
            // Sender updates
            self.set(timestamp as AnyObject, a: Path.Proxies, b: convo.senderId, c: convo.senderProxyKey, d: Path.Timestamp)
            self.setConvoValuesOnMessageSend(convo.senderId, proxy: convo.senderProxyKey, convo: convo.key, message: "You: \(text)", timestamp: timestamp)
            if convo.senderLeftConvo {
                self.set(false as AnyObject, a: Path.Convos, b: convo.senderId, c: convo.key, d: Path.SenderLeftConvo)
                self.set(false as AnyObject, a: Path.Convos, b: convo.senderProxyKey, c: convo.key, d: Path.SenderLeftConvo)
                self.set(false as AnyObject, a: Path.Convos, b: convo.receiverId, c: convo.key, d: Path.ReceiverLeftConvo)
                self.set(false as AnyObject, a: Path.Convos, b: convo.receiverProxyKey, c: convo.key, d: Path.ReceiverLeftConvo)
                self.increment(1, a: Path.Proxies, b: convo.senderId, c: convo.senderProxyKey, d: Path.Convos)
            }
            self.increment(1, a: Path.MessagesSent, b: convo.senderId, c: Path.MessagesSent, d: nil)
            
            // Receiver updates
            if !convo.receiverDeletedProxy && !convo.receiverIsBlocking {
                self.set(text as AnyObject, a: Path.Proxies, b: convo.receiverId, c: convo.receiverProxyKey, d: Path.Message)
                self.set(timestamp as AnyObject, a: Path.Proxies, b: convo.receiverId, c: convo.receiverProxyKey, d: Path.Timestamp)
                if receiverIsPresent {
                    self.increment(1, a: Path.Proxies, b: convo.receiverId, c: convo.receiverProxyKey, d: Path.Unread)
                    self.increment(1, a: Path.Unread, b: convo.receiverId, c: Path.Unread, d: nil)
                }
            }
            if !convo.receiverDeletedProxy {
                self.setConvoValuesOnMessageSend(convo.receiverId, proxy: convo.receiverProxyKey, convo: convo.key, message: text, timestamp: timestamp)
                if receiverIsPresent {
                    self.increment(1, a: Path.Convos, b: convo.receiverId, c: convo.key, d: Path.Unread)
                    self.increment(1, a: Path.Convos, b: convo.receiverProxyKey, c: convo.key, d: Path.Unread)
                }
            }
            if convo.receiverLeftConvo {
                self.set(false as AnyObject, a: Path.Convos, b: convo.senderId, c: convo.key, d: Path.ReceiverLeftConvo)
                self.set(false as AnyObject, a: Path.Convos, b: convo.senderProxyKey, c: convo.key, d: Path.ReceiverLeftConvo)
                self.set(false as AnyObject, a: Path.Convos, b: convo.receiverId, c: convo.key, d: Path.SenderLeftConvo)
                self.set(false as AnyObject, a: Path.Convos, b: convo.receiverProxyKey, c: convo.key, d: Path.SenderLeftConvo)
                self.increment(1, a: Path.Proxies, b: convo.receiverId, c: convo.receiverProxyKey, d: Path.Convos)
            }
            self.increment(1, a: Path.MessagesReceived, b: convo.receiverId, c: Path.MessagesReceived, d: nil)
            
            // Write message
            let messageKey = self.ref.child(Path.Messages).child(convo.key).childByAutoId().key
            let timeRead = receiverIsPresent ? timestamp : 0.0
            let message = Message(key: messageKey, convo: convo.key, mediaType: mediaType, read: receiverIsPresent, timeRead: timeRead, senderId: convo.senderId, date: timestamp, text: text)
            self.set(message.toAnyObject() as AnyObject, a: Path.Messages, b: convo.key, c: messageKey, d: nil)
            
            completion(convo, message)
        }
    }
    
    /// Sets `message` & `timestamp` for `user`'s `convo`.
    func setConvoValuesOnMessageSend(_ user: String, proxy: String, convo: String, message: String, timestamp: Double) {
        set(message as AnyObject, a: Path.Convos, b: user, c: convo, d: Path.Message)
        set(message as AnyObject, a: Path.Convos, b: proxy, c: convo, d: Path.Message)
        set(timestamp as AnyObject, a: Path.Convos, b: user, c: convo, d: Path.Timestamp)
        set(timestamp as AnyObject, a: Path.Convos, b: proxy, c: convo, d: Path.Timestamp)
    }
    
    /// Sets `message`'s `read` & `timeRead`.
    /// Decrements unread's for `user`.
    func setRead(forMessage message: Message, forUser user: String, forProxy proxy: String) {
        let ref = getRef(Path.Messages, b: message.convo, c: message.key, d: nil)
        let update = [Path.TimeRead: Date().timeIntervalSince1970, Path.Read: true] as [String : Any]
        ref!.updateChildValues(update as [AnyHashable: Any])
        increment(-1, a: Path.Unread, b: user, c: Path.Unread, d: nil)
        increment(-1, a: Path.Proxies, b: user, c: proxy, d: Path.Unread)
        increment(-1, a: Path.Convos, b: user, c: message.convo, d: Path.Unread)
        increment(-1, a: Path.Convos, b: proxy, c: message.convo, d: Path.Unread)
    }
    
    /// Sets `message`'s `mediaType` and `mediaURL`.
    func setMedia(forMessage message: Message, mediaType: String, mediaURL: String) {
        set(mediaType as AnyObject, a: Path.Messages, b: message.convo, c: message.key, d: Path.MediaType)
        set(mediaURL as AnyObject, a: Path.Messages, b: message.convo, c: message.key, d: Path.MediaURL)
    }
    
    // MARK: - Conversation (Convo)
    
    func createConvoKey(_ senderKey: String, senderOwner: String, receiverKey: String, receiverOwner: String) -> String {
        return [senderKey, senderOwner, receiverKey, receiverOwner].sorted().joined(separator: "")
    }
    
    func createConvo(_ sender: Proxy, receiver: Proxy, convoKey: String, text: String, completion: @escaping (_ convo: Convo) -> Void) {
        
        // Check if sender is in receiver's blocked list
        ref.child(Path.Blocked).child(receiver.ownerId).child(sender.ownerId).observeSingleEvent(of: .value, with: { (snapshot) in
            var senderConvo = Convo()
            var receiverConvo = Convo()
            let senderBlocked = snapshot.childrenCount == 1
            
            // Set up sender side
            senderConvo.key = convoKey
            senderConvo.senderId = sender.ownerId
            senderConvo.senderProxyKey = sender.key
            senderConvo.senderProxyName = sender.name
            senderConvo.receiverId = receiver.ownerId
            senderConvo.receiverProxyKey = receiver.key
            senderConvo.receiverProxyName = receiver.name
            senderConvo.icon = receiver.icon
            senderConvo.receiverIsBlocking = senderBlocked
            let senderConvoAnyObject = senderConvo.toAnyObject()
            self.set(senderConvoAnyObject as AnyObject, a: Path.Convos, b: senderConvo.senderId, c: senderConvo.key, d: nil)
            self.set(senderConvoAnyObject as AnyObject, a: Path.Convos, b: senderConvo.senderProxyKey, c: senderConvo.key, d: nil)
            self.increment(1, a: Path.ProxiesInteractedWith, b: sender.ownerId, c: Path.ProxiesInteractedWith, d: nil)
            
            // Set up receiver side
            receiverConvo.key = convoKey
            receiverConvo.senderId = receiver.ownerId
            receiverConvo.senderProxyKey = receiver.key
            receiverConvo.senderProxyName = receiver.name
            receiverConvo.receiverId = sender.ownerId
            receiverConvo.receiverProxyKey = sender.key
            receiverConvo.receiverProxyName = sender.name
            receiverConvo.icon = sender.icon
            receiverConvo.senderIsBlocking = senderBlocked
            let receiverConvoAnyObject = receiverConvo.toAnyObject()
            self.set(receiverConvoAnyObject as AnyObject, a: Path.Convos, b: receiverConvo.senderId, c: receiverConvo.key, d: nil)
            self.set(receiverConvoAnyObject as AnyObject, a: Path.Convos, b: receiverConvo.senderProxyKey, c: receiverConvo.key, d: nil)
            self.increment(1, a: Path.ProxiesInteractedWith, b: receiver.ownerId, c: Path.ProxiesInteractedWith, d: nil)
            
            completion(senderConvo)
        })
    }
    
    func getConvo(withKey key: String, belongingToUser user: String, completion: @escaping (_ convo: Convo) -> Void) {
        ref.child(Path.Convos).child(user).child(key).observeSingleEvent(of: .value, with: { (snapshot) in
            guard let convo = Convo(anyObject: snapshot.value! as AnyObject) else { return }
            completion(convo)
        })
    }
    
    func getConvos(forProxy proxy: Proxy, completion: @escaping (_ convos: [Convo]) -> Void) {
        ref.child(Path.Convos).child(proxy.key).observeSingleEvent(of: .value, with: { (snapshot) in
            var convos = [Convo]()
            for child in snapshot.children {
                if let convo = Convo(anyObject: (child as! FIRDataSnapshot).value as AnyObject) {
                    convos.append(convo)
                }
            }
            completion(convos)
        })
    }
    
    func getConvos(_ user: String, completion: @escaping (_ convos: [Convo]) -> Void) {
        ref.child(Path.Convos).child(user).observeSingleEvent(of: .value, with: { (snapshot) in
            var convos = [Convo]()
            for child in snapshot.children {
                if let convo = Convo(anyObject: (child as! FIRDataSnapshot).value as AnyObject) {
                    convos.append(convo)
                }
            }
            completion(convos)
        })
    }
    
    /// Returns an array of Convo's from `snapshot`.
    /// Filters out Convo's that should not be shown.
    func getConvos(fromSnapshot snapshot: FIRDataSnapshot) -> [Convo] {
        var convos = [Convo]()
        for child in snapshot.children {
            if let convo = Convo(anyObject: (child as! FIRDataSnapshot).value as AnyObject),
                !convo.senderLeftConvo && !convo.senderIsBlocking {
                convos.append(convo)
            }
        }
        return convos.reversed()
    }
    
    /// Returns a Convo title.
    func getConvoTitle(receiverNickname: String, receiverName: String, senderNickname: String, senderName: String) -> NSAttributedString {
        let grayAttribute = [NSForegroundColorAttributeName: UIColor.gray]
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
        first.append(second)
        return first
    }
    
    /// Sets `nickname` for `convo`.
    /// (Only the sender sees this nickname).
    func set(nickname: String, forReceiverInConvo convo: Convo) {
        set(nickname as AnyObject, a: Path.Convos, b: convo.senderId, c: convo.key, d: Path.ReceiverNickname)
        set(nickname as AnyObject, a: Path.Convos, b: convo.senderProxyKey, c: convo.key, d: Path.ReceiverNickname)
    }
    
    /// Returns a Bool indicating whether or not `user` is currently in `convo`.
    func userIsPresent(user: String, convo: String, completion: @escaping (_ userIsPresent: Bool) -> Void) {
        ref.child(Path.Present).child(convo).child(user).child(Path.Present).observeSingleEvent(of: .value, with: { (snapshot) in
            completion(snapshot.value as? Bool ?? false)
        })
    }
    
    /// Leaves a convo.
    func leave(convo: Convo) {
        set(true as AnyObject, a: Path.Convos, b: convo.senderId, c: convo.key, d: Path.SenderLeftConvo)
        set(true as AnyObject, a: Path.Convos, b: convo.senderProxyKey, c: convo.key, d: Path.SenderLeftConvo)
        set(true as AnyObject, a: Path.Convos, b: convo.receiverId, c: convo.key, d: Path.ReceiverLeftConvo)
        set(true as AnyObject, a: Path.Convos, b: convo.receiverProxyKey, c: convo.key, d: Path.ReceiverLeftConvo)
        set(0 as AnyObject, a: Path.Convos, b: convo.senderId, c: convo.key, d: Path.Unread)
        set(0 as AnyObject, a: Path.Convos, b: convo.senderProxyKey, c: convo.key, d: Path.Unread)
        increment(-1, a: Path.Proxies, b: convo.senderId, c: convo.senderProxyKey, d: Path.Convos)
        increment(-convo.unread, a: Path.Unread, b: convo.senderId, c: Path.Unread, d: nil)
        increment(-convo.unread, a: Path.Proxies, b: convo.senderId, c: convo.senderProxyKey, d: Path.Unread)
    }
}
