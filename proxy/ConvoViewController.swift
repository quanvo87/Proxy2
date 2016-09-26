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
import Fusuma
import MobilePlayer

class ConvoViewController: JSQMessagesViewController, ConvoInfoTableViewControllerDelegate, FusumaDelegate {
    
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
    var userIsTypingRef = FIRDatabaseReference()
    var userIsTyping = false {
        didSet {
            if userIsTyping {
                userIsTypingRef.setValue(userIsTyping)
            } else {
                userIsTypingRef.removeValue()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
        setUpBubbles()
        setUpSenderIsPresent()
        observeReceiverNickname()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.tabBarController?.tabBar.hidden = true
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        if senderIsPresentIsSetUp {
            senderIsPresent = true
        }
        leaveConvo()
        observeReceiverIsPresent()
        observeSenderIcon()
        observeReceiverIcon()
        observeSenderNickname()
        observeTyping()
        observeMessages()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        self.tabBarController?.tabBar.hidden = false
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(true)
        senderIsPresent = false
        userIsTyping = false
        receiverIsPresentRef.removeObserverWithHandle(receiverIsPresentRefHandle)
        senderIconRef.removeObserverWithHandle(senderIconRefHandle)
        receiverIconRef.removeObserverWithHandle(receiverIconRefHandle)
        senderNicknameRef.removeObserverWithHandle(senderNicknameRefHandle)
        membersAreTypingRef.removeObserverWithHandle(membersAreTypingRefHandle)
        messagesRef.removeObserverWithHandle(messagesRefHandle)
    }
    
    deinit {
        receiverNicknameRef.removeObserverWithHandle(receiverNicknameRefHandle)
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
        
        receiverNicknameRef.removeObserverWithHandle(receiverNicknameRefHandle)
        messagesRef.removeObserverWithHandle(messagesRefHandle)
        
        receiverIsPresentRef = ref.child(Path.Present).child(convo.key).child(convo.receiverId).child(Path.Present)
        senderNicknameRef = ref.child(Path.Nickname).child(convo.senderProxy).child(Path.Nickname)
        receiverNicknameRef = ref.child(Path.Nickname).child(convo.senderId).child(convo.key).child(Path.Nickname)
        senderIconRef = ref.child(Path.Icon).child(convo.senderProxy).child(Path.Icon)
        receiverIconRef = ref.child(Path.Icon).child(convo.receiverProxy).child(Path.Icon)
        messagesRef = ref.child(Path.Messages).child(convo.key)
        membersAreTypingRef = ref.child(Path.Typing).child(convo.key)
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
        senderIsPresentRef = ref.child(Path.Present).child(convo.key).child(convo.senderId).child(Path.Present)
        senderIsPresentRef.onDisconnectRemoveValue()
        senderIsPresentIsSetUp = true
        senderIsPresent = true
    }
    
    // Observe when receiver enters the convo while we are in it.
    // If this happens, refresh the cell with our last message to them to display the read receipt.
    func observeReceiverIsPresent() {
        receiverIsPresentRefHandle = receiverIsPresentRef.observeEventType(.Value, withBlock: { (snapshot) in
            guard let present = snapshot.value as? Bool
                where present && self.readReceiptIndex > -1 && !self.messages[self.readReceiptIndex].read
                else { return }
            
            // Get the most recent version of this message to get the `readTime`.
            let message = self.messages[self.readReceiptIndex]
            self.api.getMessage(withKey: message.key, inConvo: message.convo, completion: { (message) in
                self.messages[self.readReceiptIndex] = message
                self.collectionView.reloadItemsAtIndexPaths([NSIndexPath(forItem: self.readReceiptIndex, inSection: 0)])
                self.scrollToBottomAnimated(true)
            })
        })
    }
    
    // Observe when sender changes their nickname and update all cells that are displaying it.
    func observeSenderNickname() {
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
        messages = []
        messagesRefHandle = messagesRef.queryOrderedByChild(Path.Timestamp).observeEventType(.ChildAdded, withBlock: { (snapshot) in
            let message = Message(anyObject: snapshot.value!)
            switch message.mediaType {
                
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
                // Create message with placeholder.
                let media = JSQPhotoMediaItem()
                let _message = Message(key: message.key, convo: message.convo, mediaType: message.mediaType, mediaURL: message.mediaURL, read: message.read, timeRead: message.timeRead, senderId: message.senderId, date: message.date.timeIntervalSince1970, text: message.text, media: media)
                self.messages.append(_message)
                self.finishReceivingMessage()
                
                // Get the image from `mediaURL`.
                guard let url = NSURL(string: message.mediaURL) else { break }
                self.api.getUIImage(fromURL: url, completion: { (image) in
                    
                    // Load the image to the cell.
                    (_message.media as! JSQPhotoMediaItem).image = image
                    
                    // Reload the cell.
                    let indexPath = NSIndexPath(forItem: self.messages.count - 1, inSection: 0)
                    self.collectionView.reloadItemsAtIndexPaths([indexPath])
                })
                
            case "videoPlaceholder":
                // Create message with placeholder.
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
                guard let mediaURL = NSURL(string: message.mediaURL) else { break }
                let media = JSQVideoMediaItem(fileURL: mediaURL, isReadyToPlay: true)
                media.appliesMediaViewMaskAsOutgoing = message.senderId == self.senderId
                
                // Attach JSQVideoMediaItem.
                let _message = Message(key: message.key, convo: message.convo, mediaType: message.mediaType, mediaURL: message.mediaURL, read: message.read, timeRead: message.timeRead, senderId: message.senderId, date: message.date.timeIntervalSince1970, text: message.text, media: media)
                
                // Send message.
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
                    self.api.setRead(forMessage: message, forUser: self.convo.senderId, forProxy: self.convo.senderProxy)
                }
            } else {
                // Keep track of the last message you sent.
                self.readReceiptIndex = self.messages.count - 1
                
                // Workaround for a bug when displaying outgoing messages
                // with various `read` states. It'll do for now 🐷😕.
                self.collectionView.reloadData()
            }
        })
    }
    
    func observeTyping() {
        // Stop monitoring user's typing when they disconnect.
        userIsTypingRef = ref.child(Path.Typing).child(convo.key).child(convo.senderId).child(Path.Typing)
        userIsTypingRef.onDisconnectRemoveValue()
        
        // Show typing indicator when other user is typing.
        membersAreTypingRefHandle = membersAreTypingRef.observeEventType(.Value, withBlock: { (snapshot) in
            if snapshot.childrenCount == 1 && self.userIsTyping {
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
        let curr = self.messages[indexPath.item]
        
        // Show names/nicknames for last message by either user.
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
    
    // Play video if user taps a video bubble.
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
    
    // Show multi media message options when user taps attachments button.
    override func didPressAccessoryButton(sender: UIButton!) {
        self.inputToolbar.contentView!.textView!.resignFirstResponder()
        let alert = UIAlertController(title: "Send:", message: nil, preferredStyle: .ActionSheet)
        
        // Send photo/video
        alert.addAction(UIAlertAction(title: "Photo 📸 / Video 🎥", style: .Default, handler: { action in
            
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
        userIsTyping = false
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
        let alert = UIAlertController(title: "Access Camera", message: "Access the camera to send and take photos.", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Go To Settings", style: .Default) { (action) in
            if let appSettings = NSURL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.sharedApplication().openURL(appSettings, options: [:], completionHandler: nil)
            }})
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func send(image image: UIImage) {
        // First send a placeholder message that displays a loading indicator.
        api.sendMessage(withText: "[Photo 📸]", withMediaType: "imagePlaceholder", usingSenderConvo: self.convo) { (convo, message) in
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
        api.sendMessage(withText: "[Video 🎥]", withMediaType: "videoPlaceholder", usingSenderConvo: self.convo) { (convo, message) in
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
        userIsTyping = textView.text != ""
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
