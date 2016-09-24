//
//  ConvoViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/30/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase
import JSQMessagesViewController
import Photos
import YangMingShan
import Fusuma
import MobilePlayer

class ConvoViewController: JSQMessagesViewController, ConvoInfoTableViewControllerDelegate, YMSPhotoPickerViewControllerDelegate, FusumaDelegate {
    
    let api = API.sharedInstance
    let ref = FIRDatabase.database().reference()
    var convo = Convo()
    var readReceiptIndex = -1
    var _didLeaveConvo = false
    
    var incomingBubble: JSQMessagesBubbleImage!
    var outgoingBubble: JSQMessagesBubbleImage!
    
    var senderIsPresentIsSetUp = false
    var senderIsPresentRef = FIRDatabaseReference()
    var senderIsPresent = false {
        didSet {
            if senderIsPresent {
                senderIsPresentRef.setValue(senderIsPresent)
            } else {
                senderIsPresentRef.removeValue()
            }
        }
    }
    
    var receiverIsPresentRef = FIRDatabaseReference()
    var receiverIsPresentRefHandle = FIRDatabaseHandle()
    
    var senderIconRef = FIRDatabaseReference()
    var senderIconRefHandle = FIRDatabaseHandle()
    var receiverIconRef = FIRDatabaseReference()
    var receiverIconRefHandle = FIRDatabaseHandle()
    var icons = [String: JSQMessagesAvatarImage]()
    
    var senderNicknameRef = FIRDatabaseReference()
    var senderNicknameRefHandle = FIRDatabaseHandle()
    var receiverNicknameRef = FIRDatabaseReference()
    var receiverNicknameRefHandle = FIRDatabaseHandle()
    var names = [String: String]()
    
    var messagesRef = FIRDatabaseReference()
    var messagesRefHandle = FIRDatabaseHandle()
    var messages = [Message]()
    
    var membersAreTypingRef = FIRDatabaseReference()
    var membersAreTypingRefHandle = FIRDatabaseHandle()
    var userTypingRef = FIRDatabaseReference()
    var userTyping = false {
        didSet {
            if userTyping {
                userTypingRef.setValue(userTyping)
            } else {
                userTypingRef.removeValue()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
        setUpBubbles()
        setUpSenderIsPresent()
        observeReceiverIsPresent()
        observeSenderIcon()
        observeReceiverIcon()
        observeSenderNickname()
        observeReceiverNickname()
        observeMessages()
        observeTyping()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.tabBarController?.tabBar.hidden = true
        if senderIsPresentIsSetUp {
            senderIsPresent = true
        }
        leaveConvo()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        self.tabBarController?.tabBar.hidden = false
        senderIsPresent = false
        userTyping = false
    }
    
    deinit {
        receiverIsPresentRef.removeObserverWithHandle(receiverIsPresentRefHandle)
        senderIconRef.removeObserverWithHandle(senderIconRefHandle)
        receiverIconRef.removeObserverWithHandle(receiverIconRefHandle)
        senderNicknameRef.removeObserverWithHandle(senderNicknameRefHandle)
        receiverNicknameRef.removeObserverWithHandle(receiverNicknameRefHandle)
        messagesRef.removeObserverWithHandle(messagesRefHandle)
        membersAreTypingRef.removeObserverWithHandle(membersAreTypingRefHandle)
    }
    
    // MARK: - Set up
    func setUp() {
        names[convo.senderId] = convo.senderProxy
        names[convo.receiverId] = convo.receiverProxy
        setTitle()
        navigationController!.view.backgroundColor = UIColor.whiteColor()
        navigationItem.rightBarButtonItem = createInfoButton()
        collectionView.contentInset.bottom = 0
        collectionView?.collectionViewLayout.incomingAvatarViewSize = CGSize(width: kJSQMessagesCollectionViewAvatarSizeDefault, height:kJSQMessagesCollectionViewAvatarSizeDefault)
        collectionView?.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: kJSQMessagesCollectionViewAvatarSizeDefault, height:kJSQMessagesCollectionViewAvatarSizeDefault)
        senderId = convo.senderId
        senderDisplayName = ""
    }
    
    func setTitle() {
        navigationItem.title = names[convo.receiverId]
    }
    
    func createInfoButton() -> UIBarButtonItem {
        let infoButton = UIButton(type: .Custom)
        infoButton.setImage(UIImage(named: "info.png"), forState: UIControlState.Normal)
        infoButton.addTarget(self, action: #selector(ConvoViewController.showConvoInfoTableViewController), forControlEvents: UIControlEvents.TouchUpInside)
        infoButton.frame = CGRectMake(0, 0, 25, 25)
        return UIBarButtonItem(customView: infoButton)
    }
    
    func setUpBubbles() {
        let factory = JSQMessagesBubbleImageFactory()
        incomingBubble = factory.incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
        outgoingBubble = factory.outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleBlueColor())
    }
    
    // MARK: - Database
    // Set user as present in the convo.
    func setUpSenderIsPresent() {
        senderIsPresentRef = ref.child(Path.Present).child(convo.key).child(convo.senderId)
        senderIsPresentRef.onDisconnectRemoveValue()
        senderIsPresentIsSetUp = true
        senderIsPresent = true
    }
    
    // Observe when receiver enters the convo while we are in it.
    // If this happens, refresh the cell with our last message to them to display the read receipt.
    func observeReceiverIsPresent() {
        receiverIsPresentRef = ref.child(Path.Present).child(convo.key).child(convo.receiverId)
        receiverIsPresentRefHandle = receiverIsPresentRef.observeEventType(.Value, withBlock: { (snapshot) in
            guard let present = snapshot.value as? Bool
                where present && self.readReceiptIndex > -1 && !self.messages[self.readReceiptIndex].read
                else { return }
            let message = self.messages[self.readReceiptIndex]
            self.api.getMessage(withKey: message.key, inConvo: message.key, completion: { (message) in
                self.messages[self.readReceiptIndex] = message
                self.collectionView.reloadItemsAtIndexPaths([NSIndexPath(forItem: self.readReceiptIndex, inSection: 0)])
                self.scrollToBottomAnimated(true)
            })
        })
    }
    
    // Observe when sender changes their nickname and update all cells that are displaying it.
    func observeSenderNickname() {
        senderNicknameRef = ref.child(Path.Nickname).child(convo.senderProxy)
        senderNicknameRefHandle = senderNicknameRef.observeEventType(.Value, withBlock: { (snapshot) in
            if let nickname = snapshot.value as? String {
                self.names[self.convo.senderId] = nickname == "" ? self.convo.senderProxy : nickname
                self.collectionView.reloadData()
            }
        })
    }
    
    // Observe when sender changes receiver's nickname for this convo and update all cells that are displaying it.
    // Also update navigation bar title.
    func observeReceiverNickname() {
        receiverNicknameRef = ref.child(Path.Nickname).child(convo.senderId).child(convo.key).child(Path.Nickname)
        receiverNicknameRefHandle = receiverNicknameRef.observeEventType(.Value, withBlock: { (snapshot) in
            if let nickname = snapshot.value as? String {
                self.names[self.convo.receiverId] = nickname == "" ? self.convo.receiverProxy : nickname
                self.setTitle()
                self.collectionView.reloadData()
            }
        })
    }
    
    // Observe when sender changes his/her icon to update all cells that are displaying it.
    func observeSenderIcon() {
        senderIconRef = ref.child(Path.Icon).child(convo.senderProxy).child(Path.Icon)
        senderIconRefHandle = senderIconRef.observeEventType(.Value, withBlock: { (snapshot) in
            if let icon = snapshot.value as? String {
                self.api.getUIImage(forIcon: icon, completion: { (image) in
                    self.icons[self.convo.senderId] = JSQMessagesAvatarImage(placeholder: image)
                    self.collectionView.reloadData()
                })
            }
        })
    }
    
    // Observe when receiver changes his/her icon to update all cells that are displaying it.
    func observeReceiverIcon() {
        receiverIconRef = ref.child(Path.Icon).child(convo.receiverProxy).child(Path.Icon)
        receiverIconRefHandle = receiverIconRef.observeEventType(.Value, withBlock: { (snapshot) in
            if let icon = snapshot.value as? String {
                self.api.getUIImage(forIcon: icon, completion: { (image) in
                    self.icons[self.convo.receiverId] = JSQMessagesAvatarImage(placeholder: image)
                    self.collectionView.reloadData()
                })
            }
        })
    }
    
    // Observe and build the messages for this convo.
    // Mark unread messages to this user as read.
    // Keep track of the index of the last message you sent (for read receipt purposes).
    func observeMessages() {
        messagesRef = ref.child(Path.Messages).child(convo.key)
        messagesRefHandle = messagesRef.queryOrderedByChild(Path.Timestamp).observeEventType(.ChildAdded, withBlock: { (snapshot) in
            let message = Message(anyObject: snapshot.value!)
            switch message.mediaType {
                
            // A new media message that is waiting for its content to be uploaded to storage.
            // Once that is complete, this media message will be updated with the URL to that content.
            // Pull that content and reload the cell once it has a URL.
            case "imagePlaceholder":
                
                // Send message with placeholder.
                let media = JSQPhotoMediaItem()
                let _message = Message(key: message.key, convo: message.convo, mediaType: message.mediaType, mediaURL: message.mediaURL, read: message.read, timeRead: message.timeRead, senderId: message.senderId, date: message.date.timeIntervalSince1970, text: message.text, media: media)
                self.messages.append(_message)
                self.finishReceivingMessage()
                
                // Wait for the message's content to be loaded to storage.
                // Once this happens, the message's `mediaURL` will be updated.
                var messageRefHandle = FIRDatabaseHandle()
                let messageRef = self.ref.child(Path.Messages).child(message.convo).child(message.key).child(Path.MediaURL)
                messageRefHandle = messageRef.observeEventType(.Value, withBlock: { (snapshot) in
                    
                    // Get `mediaURL`.
                    guard let url = NSURL(string: snapshot.value as! String)
                        where url.absoluteString != "" else { return }
                    
                    // Get the image from `mediaURL`.
                    self.api.getUIImage(fromURL: url, completion: { (image) in
                        
                        // Load the image to the cell.
                        (_message.media as! JSQPhotoMediaItem).image = image
                        
                        // Reload the cell.
                        let indexPath = NSIndexPath(forItem: self.messages.count - 1, inSection: 0)
                        self.collectionView.reloadItemsAtIndexPaths([indexPath])
                        
                        // Remove database observer for this message.
                        messageRef.removeObserverWithHandle(messageRefHandle)
                    })
                })
                
            case "image":
                
                // Send message with placeholder.
                let media = JSQPhotoMediaItem()
                let _message = Message(key: message.key, convo: message.convo, mediaType: message.mediaType, mediaURL: message.mediaURL, read: message.read, timeRead: message.timeRead, senderId: message.senderId, date: message.date.timeIntervalSince1970, text: message.text, media: media)
                self.messages.append(_message)
                self.finishReceivingMessage()
                
                // Get the image from `mediaURL`.
                guard let url = NSURL(string: message.mediaURL) else { return }
                self.api.getUIImage(fromURL: url, completion: { (image) in
                    
                    // Load the image to the cell.
                    (_message.media as! JSQPhotoMediaItem).image = image
                    
                    // Reload the cell.
                    let indexPath = NSIndexPath(forItem: self.messages.count - 1, inSection: 0)
                    self.collectionView.reloadItemsAtIndexPaths([indexPath])
                })
                
            case "videoPlaceholder":
                
                // Send message with placeholder.
                let media = JSQVideoMediaItem()
                let _message = Message(key: message.key, convo: message.convo, mediaType: "video", mediaURL: message.mediaURL, read: message.read, timeRead: message.timeRead, senderId: message.senderId, date: message.date.timeIntervalSince1970, text: message.text, media: media)
                self.messages.append(_message)
                self.finishReceivingMessage()
                
                // Wait for the message's content to be loaded to storage.
                // Once this happens, the message's `mediaURL` will be updated.
                var messageRefHandle = FIRDatabaseHandle()
                let messageRef = self.ref.child(Path.Messages).child(message.convo).child(message.key).child(Path.MediaURL)
                messageRefHandle = messageRef.observeEventType(.Value, withBlock: { (snapshot) in
                    
                    // Get `mediaURL`.
                    guard let mediaURLString = snapshot.value as? String
                        where mediaURLString != "" else { return }
                    
                    // Load cell with url to local file.
                    (_message.media as! JSQVideoMediaItem).fileURL = NSURL(string: mediaURLString)
                    (_message.media as! JSQVideoMediaItem).isReadyToPlay = true
                    (_message.media as! JSQVideoMediaItem).appliesMediaViewMaskAsOutgoing = message.senderId == self.senderId
                    
                    // Reload the cell.
                    let indexPath = NSIndexPath(forItem: self.messages.count - 1, inSection: 0)
                    self.collectionView.reloadItemsAtIndexPaths([indexPath])
                    
                    // Remove database observer for this message.
                    messageRef.removeObserverWithHandle(messageRefHandle)
                })
                
            case "video":
                
                // Build JSQVideoMediaItem.
                guard let mediaURL = NSURL(string: message.mediaURL) else { return }
                let media = JSQVideoMediaItem(fileURL: mediaURL, isReadyToPlay: true)
                media.appliesMediaViewMaskAsOutgoing = message.senderId == self.senderId
                
                // Attach JSQVideoMediaItem.
                let _message = Message(key: message.key, convo: message.convo, mediaType: message.mediaType, mediaURL: message.mediaURL, read: message.read, timeRead: message.timeRead, senderId: message.senderId, date: message.date.timeIntervalSince1970, text: message.text, media: media)
                
                // Append modified message to messages and finish receiving.
                self.messages.append(_message)
                self.finishReceivingMessage()
                
            // Regular text message.
            default:
                self.messages.append(message)
                self.finishReceivingMessage()
            }
            
            // Mark messages from other user as read.
            if message.senderId != self.senderId {
                if !message.read {
                    self.api.setRead(forMessage: message, forUser: self.senderId)
                }
            } else {
                // Keep track of the last message you sent.
                self.readReceiptIndex = self.messages.count - 1
            }
        })
    }
    
    func observeTyping() {
        
        // Stop monitoring user's typing when they disconnect.
        userTypingRef = ref.child(Path.Typing).child(convo.key).child(convo.senderId)
        userTypingRef.onDisconnectRemoveValue()
        
        // Show typing indicator when other user is typing.
        membersAreTypingRef = ref.child(Path.Typing).child(convo.key)
        membersAreTypingRefHandle = membersAreTypingRef.observeEventType(.Value, withBlock: { (snapshot) in
            if snapshot.childrenCount == 1 && self.userTyping {
                return
            }
            self.showTypingIndicator = snapshot.childrenCount > 0
            self.scrollToBottomAnimated(true)
        })
    }
    
    // MARK: - JSQMessagesCollectionView
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    // Distinguish between sender and receiver chat bubble.
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        return messages[indexPath.item].senderId == self.senderId ? outgoingBubble : incomingBubble
    }
    
    // Set up cell.
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        
        // Messages with media don't have textfields.
        guard message.mediaType == "" else {
            return cell
        }
        
        // Outgoing message.
        if message.senderId == senderId {
            cell.textView!.textColor = UIColor.whiteColor()
            cell.messageBubbleTopLabel.textInsets = UIEdgeInsetsMake(0, 0, 0, 40)
        
        // Incoming message.
        } else {
            cell.textView?.textColor = UIColor.blackColor()
            cell.messageBubbleTopLabel.textInsets = UIEdgeInsetsMake(0, 40, 0, 0)
            cell.textView.linkTextAttributes = [
                NSForegroundColorAttributeName: UIColor().blue(),
                NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue]
        }
        
        return cell
    }
    
    // Make space for timestamp.
    override func collectionView(collectionView: JSQMessagesCollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout, heightForCellTopLabelAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        // First message of convo.
        if indexPath.item == 0 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        
        // When too much time has passed between two messages.
        let prev = self.messages[indexPath.item - 1]
        let curr = self.messages[indexPath.item]
        if curr.date.timeIntervalSinceDate(prev.date) / 60 > Settings.TimeBetweenTimestamps {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        
        return 0
    }
    
    // Get timestamp.
    override func collectionView(collectionView: JSQMessagesCollectionView, attributedTextForCellTopLabelAtIndexPath indexPath: NSIndexPath) -> NSAttributedString? {
        let curr = self.messages[indexPath.item]
        
        // First message of convo.
        if indexPath.item == 0 {
            return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(curr.date)
        }
        
        // When too much time has passed between two messages.
        let prev = self.messages[indexPath.item - 1]
        if curr.date.timeIntervalSinceDate(prev.date) / 60 > Settings.TimeBetweenTimestamps {
            return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(curr.date)
        }
        
        return nil
    }
    
    // Get avatars.
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        let curr = self.messages[indexPath.item]
        
        // Display an avatar for the first message of the convo.
        if indexPath.item == 0 {
            return icons[curr.senderId]
        }
        
        // Display an avatar for the last message of the convo.
        if indexPath.item == messages.count - 1 {
            return icons[curr.senderId]
        }
        
        // Display an avatar for each user on message chain breaks.
        let next = self.messages[indexPath.item + 1]
        if curr.senderId != next.senderId {
            return icons[curr.senderId]
        }
        
        let prev = self.messages[indexPath.item - 1]
        if prev.senderId != curr.senderId {
            return icons[curr.senderId]
        }
        
        return nil
    }
    
    // Make space for proxy names.
    override func collectionView(collectionView: JSQMessagesCollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout, heightForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        // Show names/nicknames for last message by either user.
        if indexPath.item == messages.count - 1 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }

        let curr = self.messages[indexPath.item]
        let next = self.messages[indexPath.item + 1]
        if curr.senderId != next.senderId {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        
        return 0
    }
    
    // Get proxy names.
    override func collectionView(collectionView: JSQMessagesCollectionView, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath) -> NSAttributedString? {
        
        // Show names/nicknames for last message by either user.
        let curr = self.messages[indexPath.item]
        if indexPath.item == messages.count - 1 {
            return NSAttributedString(string: names[curr.senderId]!)
        }
        
        let next = self.messages[indexPath.item + 1]
        if curr.senderId != next.senderId {
            return NSAttributedString(string: names[curr.senderId]!)
        }
        
        return nil
    }
    
    // Make space for read receipt.
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        let message = messages[indexPath.item]
        if indexPath.item == readReceiptIndex && message.senderId == senderId && message.read {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        return 0
    }
    
    // Get read receipt.
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.item]
        if indexPath.item == readReceiptIndex && message.senderId == senderId && message.read {
            let read = "Read ".makeBold(withSize: 12)
            let timestamp = NSAttributedString(string: message.timeRead.toTimeAgo())
            read.appendAttributedString(timestamp)
            return read
        }
        return nil
    }
    
    // Get message data for row.
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAtIndexPath indexPath: NSIndexPath!) {
        let message = messages[indexPath.item]
        if message.mediaType == "video" {
            guard let url = (message.media as! JSQVideoMediaItem).fileURL
                where url.absoluteString != "" else { return }
            let playerVC = MobilePlayerViewController(contentURL: url)
            playerVC.activityItems = [url]
            presentMoviePlayerViewControllerAnimated(playerVC)
        }
    }
    
    // Write the message to the database when user taps send.
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        api.sendMessage(withText: text, withMediaType: "", usingSenderConvo: convo) { (convo, message) in
            self.finishedWritingMessage()
        }
    }
    
    override func didPressAccessoryButton(sender: UIButton!) {
        self.inputToolbar.contentView!.textView!.resignFirstResponder()
        let alert = UIAlertController(title: "Attach:", message: nil, preferredStyle: .ActionSheet)
        
        // Send photo
        alert.addAction(UIAlertAction(title: "Photo 📸", style: .Default, handler: { action in
            
            // Show YMSPhotoPicker, our VC that can handle camera and photos.
            let ysmPhotoPicker = YMSPhotoPickerViewController()
            ysmPhotoPicker.theme.cameraVeilColor = UIColor.clearColor()
            ysmPhotoPicker.numberOfPhotoToSelect = 5
            self.yms_presentCustomAlbumPhotoView(ysmPhotoPicker, delegate: self)
        }))
        
        // Send video
        alert.addAction(UIAlertAction(title: "Video 🎥", style: .Default, handler: { action in
            
            // Show Fusuma, our VC that can handle camera, photos, and video.
            let fusuma = FusumaViewController()
            fusuma.delegate = self
            fusuma.hasVideo = true
            self.presentViewController(fusuma, animated: true, completion: nil)
        }))
        
//        let locationAction = UIAlertAction(title: "Send location", style: .Default) { (action) in
//            /**
//             *  Add fake location
//             */
//            let locationItem = self.buildLocationItem()
//
//            self.addMedia(locationItem)
//        }
//
//        let videoAction = UIAlertAction(title: "Send video", style: .Default) { (action) in
//            /**
//             *  Add fake video
//             */
//            let videoItem = self.buildVideoItem()
//            
//            self.addMedia(videoItem)
//        }
//        
//        let audioAction = UIAlertAction(title: "Send audio", style: .Default) { (action) in
//            /**
//             *  Add fake audio
//             */
//            let audioItem = self.buildAudioItem()
//            
//            self.addMedia(audioItem)
//        }
//        
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func finishedWritingMessage() {
        finishSendingMessage()
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        userTyping = false
    }
    
    // MARK: - YMSPhotoPicker delegate
    func photoPickerViewControllerDidReceivePhotoAlbumAccessDenied(picker: YMSPhotoPickerViewController!) {
        let alert = UIAlertController(title: "Allow photo album access?", message: "Need your permission to access photo albums.", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Settings", style: .Default) { (action) in
            if let appSettings = NSURL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.sharedApplication().openURL(appSettings, options: [:], completionHandler: nil)
            }})
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func photoPickerViewControllerDidReceiveCameraAccessDenied(picker: YMSPhotoPickerViewController!) {
        let alert = UIAlertController(title: "Allow camera album access?", message: "Need your permission to take a photo.", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Settings", style: .Default) { (action) in
            if let appSettings = NSURL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.sharedApplication().openURL(appSettings, options: [:], completionHandler: nil)
            }})
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        // The access denied of camera always happens on picker, present alert on it to follow the view hierarchy.
        picker.presentViewController(alert, animated: true, completion: nil)
    }
    
    // User has selected the photos they want to send.
    func photoPickerViewController(picker: YMSPhotoPickerViewController!, didFinishPickingImages photoAssets: [PHAsset]!) {
        picker.dismissViewControllerAnimated(true) {
            
            let manager = PHImageManager.defaultManager()
            let options = PHImageRequestOptions()
            
            // Get images from photoAssets and send them.
            for asset in photoAssets {
                manager.requestImageForAsset(asset, targetSize: PHImageManagerMaximumSize, contentMode: .Default, options: options, resultHandler: { (image, info) -> Void in
                    if let image = image {
                        self.send(image: image)
                    }
                })
            }
        }
    }
    
    // MARK: - Fusuma delegate
    // Return the image which is selected from camera roll or is taken via the camera.
    func fusumaImageSelected(image: UIImage) {
    }
    
    // Return the image but called after is dismissed.
    func fusumaDismissedWithImage(image: UIImage) {
        send(image: image)
    }
    
    func fusumaVideoCompleted(withFileURL fileURL: NSURL) {
        send(videoWithURL: fileURL)
    }
    
    // Call when camera roll not authorized.
    func fusumaCameraRollUnauthorized() {
        let alert = UIAlertController(title: "Allow camera album access?", message: "Need your permission to take a photo.", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Settings", style: .Default) { (action) in
            if let appSettings = NSURL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.sharedApplication().openURL(appSettings, options: [:], completionHandler: nil)
            }})
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func send(image image: UIImage) {
        
        // First send a placeholder message that displays a loading indicator.
        api.sendMessage(withText: "Photo message.", withMediaType: "imagePlaceholder", usingSenderConvo: self.convo) { (convo, message) in
            self.finishSendingMessage()
            
            // Then upload the image to storage.
            self.api.upload(image: image, completion: { (url) in
                
                // The upload returns the URL to the image we just uploaded.
                // Update the placeholder message with this info.
                guard let url = url.absoluteString else { return }
                self.api.setMedia(forMessage: message, mediaType: "image", mediaURL: url)
                self.finishedWritingMessage()
            })
        }
    }
    
    func send(videoWithURL url: NSURL) {
        
        // First send a placeholder message that displays a loading indicator.
        api.sendMessage(withText: "Video message.", withMediaType: "videoPlaceholder", usingSenderConvo: self.convo) { (convo, message) in
            self.finishSendingMessage()
            
            // Then upload the image to storage.
            self.api.uploadVideo(fromURL: url, completion: { (url) in
              
                // The upload returns the URL to the image we just uploaded.
                // Update the placeholder message with this info.
                guard let url = url.absoluteString else { return }
                self.api.setMedia(forMessage: message, mediaType: "video", mediaURL: url)
                self.finishedWritingMessage()
            })
        }
    }
    
    // MARK: - Text view
    // Keep track of when user is typing.
    override func textViewDidChange(textView: UITextView) {
        super.textViewDidChange(textView)
        userTyping = textView.text != ""
    }
    
    // MARK: - ConvoInfoTableViewControllerDelegate
    func didLeaveConvo() {
        _didLeaveConvo = true
    }
    
    func leaveConvo() {
        if _didLeaveConvo {
            navigationController?.popViewControllerAnimated(true)
        }
    }
    
    // MARK: - Navigation
    func showConvoInfoTableViewController() {
        let dest = storyboard?.instantiateViewControllerWithIdentifier(Identifiers.ConvoInfoTableViewController) as! ConvoInfoTableViewController
        dest.convo = convo
        dest.delegate = self
        navigationController?.pushViewController(dest, animated: true)
    }
}
