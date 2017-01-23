//
//  ConvoViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/30/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase
import JSQMessagesViewController
import Fusuma
import MobilePlayer

class ConvoViewController: JSQMessagesViewController, FusumaDelegate {
    
    let api = API.sharedInstance
    let ref = FIRDatabase.database().reference()
    var convo = Convo()
    var readReceiptIndex = -1
    
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
    
    var messagesRef = FIRDatabaseReference()
    var messagesRefHandle = FIRDatabaseHandle()
    var lastMessageRefHandle = FIRDatabaseHandle()
    var messages = [Message]()
    var unreadMessages = [Message]()
    
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
        observeMessages()
        observeLastMessage()
        observeSenderIcon()
        observeReceiverIcon()
        observeSenderNickname()
        observeReceiverNickname()
        observeTyping()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        checkStatus()
        if senderIsPresentIsSetUp {
            senderIsPresent = true
        }
        readMessages()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        tabBarController?.tabBar.isHidden = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        senderIsPresent = false
        userIsTyping = false
    }
    
    deinit {
        messagesRef.removeObserver(withHandle: messagesRefHandle)
        messagesRef.removeObserver(withHandle: lastMessageRefHandle)
        senderIconRef.removeObserver(withHandle: senderIconRefHandle)
        receiverIconRef.removeObserver(withHandle: receiverIconRefHandle)
        senderNicknameRef.removeObserver(withHandle: senderNicknameRefHandle)
        receiverNicknameRef.removeObserver(withHandle: receiverNicknameRefHandle)
        membersAreTypingRef.removeObserver(withHandle: membersAreTypingRefHandle)
    }
    
    func setUp() {
        names[convo.senderId] = convo.senderProxyName
        names[convo.receiverId] = convo.receiverProxyName
        
        setTitle()
        
        let infoButton = UIButton(type: .custom)
        infoButton.setImage(UIImage(named: "info.png"), for: UIControlState())
        infoButton.addTarget(self, action: #selector(ConvoViewController.showConvoInfoTableViewController), for: UIControlEvents.touchUpInside)
        infoButton.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        navigationItem.rightBarButtonItem =  UIBarButtonItem(customView: infoButton)
        navigationController!.view.backgroundColor = UIColor.white
        
        collectionView?.collectionViewLayout.incomingAvatarViewSize = CGSize(width: kJSQMessagesCollectionViewAvatarSizeDefault, height:kJSQMessagesCollectionViewAvatarSizeDefault)
        collectionView?.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: kJSQMessagesCollectionViewAvatarSizeDefault, height:kJSQMessagesCollectionViewAvatarSizeDefault)
        collectionView.contentInset.bottom = 0
        
        senderId = convo.senderId
        senderDisplayName = ""
        
        messagesRef = ref.child(Path.Messages).child(convo.key)
        senderIconRef = ref.child(Path.Proxies).child(convo.senderId).child(convo.senderProxyKey).child(Path.Icon)
        receiverIconRef = ref.child(Path.Convos).child(convo.senderId).child(convo.key).child(Path.Icon)
        senderNicknameRef = ref.child(Path.Convos).child(convo.senderId).child(convo.key).child(Path.SenderNickname)
        receiverNicknameRef = ref.child(Path.Convos).child(convo.senderId).child(convo.key).child(Path.ReceiverNickname)
        membersAreTypingRef = ref.child(Path.Typing).child(convo.key)
    }
    
    func setTitle() {
        navigationItem.title = names[convo.receiverId]
    }
    
    func setUpBubbles() {
        let factory = JSQMessagesBubbleImageFactory()
        incomingBubble = factory?.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
        outgoingBubble = factory?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    }
    
    // MARK: - Database
    func checkStatus() {
        checkLeftConvo()
        checkDeletedProxy()
        checkIsBlocking()
    }
    
    func checkLeftConvo() {
        ref.child(Path.Convos).child(convo.senderId).child(convo.key).child(Path.SenderLeftConvo).observeSingleEvent(of: .value, with: { (snapshot) in
            if let leftConvo = snapshot.value as? Bool, leftConvo {
                self.close()
            }
        })
    }
    
    func checkDeletedProxy() {
        ref.child(Path.Convos).child(convo.senderId).child(convo.key).child(Path.SenderDeletedProxy).observeSingleEvent(of: .value, with: { (snapshot) in
            if let deletedProxy = snapshot.value as? Bool, deletedProxy {
                self.close()
            }
        })
    }
    
    func checkIsBlocking() {
        ref.child(Path.Convos).child(convo.senderId).child(convo.key).child(Path.SenderIsBlocking).observeSingleEvent(of: .value, with: { (snapshot) in
            if let isBlocking = snapshot.value as? Bool, isBlocking {
                self.close()
            }
        })
    }
    
    func close() {
        _ = navigationController?.popViewController(animated: true)
    }
    
    // Set user as present in the convo.
    func setUpSenderIsPresent() {
        senderIsPresentRef = ref.child(Path.Present).child(convo.key).child(convo.senderId).child(Path.Present)
        senderIsPresentRef.onDisconnectRemoveValue()
        senderIsPresentIsSetUp = true
        senderIsPresent = true
    }
    
    // Observe and load messages.
    func observeMessages() {
        messagesRefHandle = messagesRef.queryOrdered(byChild: Path.Timestamp).observe(.childAdded, with: { (snapshot) in
            guard let message = Message(anyObject: snapshot.value! as AnyObject) else { return }
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
                messageRefHandle = messageRef.observe(.value, with: { (snapshot) in
                    
                    // Get `mediaURL`.
                    guard let url = URL(string: snapshot.value as! String), url.absoluteString != "" else { return }
                    
                    // Get the image from `mediaURL`.
                    self.api.getUIImage(fromURL: url, completion: { (image) in
                        
                        // Load the image to the cell.
                        (_message.media as! JSQPhotoMediaItem).image = image
                        
                        // Reload the collection view.
                        self.collectionView.reloadData()
                        
                        // Remove database observer for this message.
                        messageRef.removeObserver(withHandle: messageRefHandle)
                    })
                })
                
            case "image":
                
                // Create message with placeholder.
                let media = JSQPhotoMediaItem()
                let _message = Message(key: message.key, convo: message.convo, mediaType: message.mediaType, mediaURL: message.mediaURL, read: message.read, timeRead: message.timeRead, senderId: message.senderId, date: message.date.timeIntervalSince1970, text: message.text, media: media)
                self.messages.append(_message)
                self.finishReceivingMessage()
                
                // Get the image from `mediaURL`.
                guard let url = URL(string: message.mediaURL) else { return }
                self.api.getUIImage(fromURL: url, completion: { (image) in
                    
                    // Load the image to the cell.
                    (_message.media as! JSQPhotoMediaItem).image = image
                    
                    // Reload the collection view.
                    self.collectionView.reloadData()
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
                messageRefHandle = messageRef.observe(.value, with: { (snapshot) in
                    
                    // Get `mediaURL`.
                    guard let mediaURLString = snapshot.value as? String, mediaURLString != "" else { return }
                    
                    // Load cell with url to local file.
                    (_message.media as! JSQVideoMediaItem).appliesMediaViewMaskAsOutgoing = message.senderId == self.senderId
                    (_message.media as! JSQVideoMediaItem).fileURL = URL(string: mediaURLString)
                    (_message.media as! JSQVideoMediaItem).isReadyToPlay = true
                    
                    // Reload the collection view.
                    self.collectionView.reloadData()
                    
                    // Remove database observer for this message.
                    messageRef.removeObserver(withHandle: messageRefHandle)
                })
                
            case "video":
                
                // Build JSQVideoMediaItem.
                guard let mediaURL = URL(string: message.mediaURL) else { return }
                let media = JSQVideoMediaItem(fileURL: mediaURL, isReadyToPlay: true)
                media?.appliesMediaViewMaskAsOutgoing = message.senderId == self.senderId
                
                // Attach JSQVideoMediaItem.
                let _message = Message(key: message.key, convo: message.convo, mediaType: message.mediaType, mediaURL: message.mediaURL, read: message.read, timeRead: message.timeRead, senderId: message.senderId, date: message.date.timeIntervalSince1970, text: message.text, media: media!)
                
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
                    if self.senderIsPresent {
                        self.api.setRead(forMessage: message, forUser: self.convo.senderId, forProxy: self.convo.senderProxyKey)
                    } else {
                        self.unreadMessages.append(message)
                    }
                }
            } else {
                
                // Keep track of the last message you sent.
                self.readReceiptIndex = self.messages.count - 1
                
                // Fix message bubble with read receipt.
                self.collectionView.reloadData()
            }
        })
    }
    
    // Observe most recent message to see if it's an outgoing message that's been read.
    func observeLastMessage() {
        lastMessageRefHandle = messagesRef.queryOrdered(byChild: Path.Timestamp).queryLimited(toLast: 1).observe(.value, with: { (snapshot) in
            guard snapshot.hasChildren() else { return }
            guard let message = Message(anyObject: (snapshot.children.nextObject()! as! FIRDataSnapshot).value as AnyObject) else { return }
            if message.senderId == self.senderId && message.read {
                let message_ = self.messages[self.readReceiptIndex]
                if !message_.read {
                    message_.read = message.read
                    message_.timeRead = message.timeRead
                    self.messages[self.readReceiptIndex] = message_
                    self.collectionView.reloadData()
//                    self.collectionView.reloadItemsAtIndexPaths([NSIndexPath(forItem: self.readReceiptIndex, inSection: 0)])
                    self.scrollToBottom(animated: true)
                }
            }
        })
    }
    
    // Mark messages as read for incoming messages that came in while convo was open but not on screen.
    func readMessages() {
        for message in unreadMessages {
            api.setRead(forMessage: message, forUser: self.convo.senderId, forProxy: self.convo.senderProxyKey)
        }
        unreadMessages = []
    }
    
    // Observe when sender changes his/her icon to update all cells that are displaying it.
    func observeSenderIcon() {
        senderIconRefHandle = senderIconRef.observe(.value, with: { (snapshot) in
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
        receiverIconRefHandle = receiverIconRef.observe(.value, with: { (snapshot) in
            if let icon = snapshot.value as? String {
                self.api.getUIImage(forIcon: icon, completion: { (image) in
                    self.icons[self.convo.receiverId] = JSQMessagesAvatarImage(placeholder: image)
                    self.collectionView.reloadData()
                })
            }
        })
    }
    
    // Observe when sender changes their nickname and update all cells that are displaying it.
    func observeSenderNickname() {
        senderNicknameRefHandle = senderNicknameRef.observe(.value, with: { (snapshot) in
            if let nickname = snapshot.value as? String {
                self.names[self.convo.senderId] = nickname == "" ? self.convo.senderProxyName : nickname
                self.collectionView.reloadData()
            }
        })
    }
    
    // Observe when sender changes receiver's nickname for this convo and update all cells that are displaying it.
    // Also update navigation bar title.
    func observeReceiverNickname() {
        receiverNicknameRefHandle = receiverNicknameRef.observe(.value, with: { (snapshot) in
            if let nickname = snapshot.value as? String {
                self.names[self.convo.receiverId] = nickname == "" ? self.convo.receiverProxyName : nickname
                self.setTitle()
                self.collectionView.reloadData()
            }
        })
    }
    
    func observeTyping() {
        
        // Stop monitoring user's typing when they disconnect.
        userIsTypingRef = ref.child(Path.Typing).child(convo.key).child(convo.senderId).child(Path.Typing)
        userIsTypingRef.onDisconnectRemoveValue()
        
        // Show typing indicator when other user is typing.
        membersAreTypingRefHandle = membersAreTypingRef.observe(.value, with: { (snapshot) in
            if snapshot.childrenCount == 1 && self.userIsTyping {
                return
            }
            self.showTypingIndicator = snapshot.childrenCount > 0
            self.scrollToBottom(animated: true)
        })
    }
    
    // MARK: - JSQMessagesCollectionView
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    // Distinguish between sender and receiver chat bubble.
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        return messages[indexPath.item].senderId == self.senderId ? outgoingBubble : incomingBubble
    }
    
    // Set up cell.
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        
        // Messages with media don't have textfields.
        guard message.mediaType == "" else {
            return cell
        }
        
        // Outgoing message.
        if message.senderId == senderId {
            cell.messageBubbleTopLabel.textInsets = UIEdgeInsetsMake(0, 0, 0, 40)
            cell.textView!.textColor = UIColor.white
            
        // Incoming message.
        } else {
            cell.messageBubbleTopLabel.textInsets = UIEdgeInsetsMake(0, 40, 0, 0)
            cell.textView.linkTextAttributes = [
                NSForegroundColorAttributeName: UIColor().blue(),
                NSUnderlineStyleAttributeName: NSUnderlineStyle.styleSingle.rawValue]
            cell.textView?.textColor = UIColor.black
        }
        
        return cell
    }
    
    // Make space for timestamp.
    override func collectionView(_ collectionView: JSQMessagesCollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout, heightForCellTopLabelAt indexPath: IndexPath) -> CGFloat {
        
        // First message of convo.
        if indexPath.item == 0 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        
        // When too much time has passed between two messages.
        let prev = self.messages[indexPath.item - 1]
        let curr = self.messages[indexPath.item]
        if curr.date.timeIntervalSince(prev.date) / 60 > Settings.TimeBetweenTimestamps {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        
        return 0
    }
    
    // Get timestamp.
    override func collectionView(_ collectionView: JSQMessagesCollectionView, attributedTextForCellTopLabelAt indexPath: IndexPath) -> NSAttributedString? {
        let curr = self.messages[indexPath.item]
        
        // First message of convo.
        if indexPath.item == 0 {
            return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: curr.date)
        }
        
        // When too much time has passed between two messages.
        let prev = self.messages[indexPath.item - 1]
        if curr.date.timeIntervalSince(prev.date) / 60 > Settings.TimeBetweenTimestamps {
            return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: curr.date)
        }
        
        return nil
    }
    
    // Get avatars.
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
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
    override func collectionView(_ collectionView: JSQMessagesCollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout, heightForMessageBubbleTopLabelAt indexPath: IndexPath) -> CGFloat {
        
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
    override func collectionView(_ collectionView: JSQMessagesCollectionView, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath) -> NSAttributedString? {
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
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAt indexPath: IndexPath!) -> CGFloat {
        let message = messages[indexPath.item]
        if indexPath.item == readReceiptIndex && message.senderId == senderId && message.read {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        return 0
    }
    
    // Get read receipt.
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.item]
        if indexPath.item == readReceiptIndex && message.senderId == senderId && message.read {
            let read = "Read ".makeBold(withSize: 12)
            let timestamp = NSAttributedString(string: message.timeRead.toTimeAgo())
            read.append(timestamp)
            return read
        }
        return nil
    }
    
    // Get message data for row.
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    // Play video if user taps a video bubble.
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        let message = messages[indexPath.item]
        if message.mediaType == "video" {
            guard let url = (message.media as! JSQVideoMediaItem).fileURL, url.absoluteString != "" else { return }
            let playerVC = MobilePlayerViewController(contentURL: url)
            playerVC.activityItems = [url]
            presentMoviePlayerViewControllerAnimated(playerVC)
            return
        }
        if message.mediaType == "image" {
            let image = (message.media as! JSQPhotoMediaItem).image
            let newImageView = UIImageView(image: image)
            newImageView.backgroundColor = .black
            newImageView.contentMode = .scaleAspectFit
            newImageView.frame = self.view.frame
            newImageView.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(ConvoViewController.dismissFullscreenImage(_:)))
            newImageView.addGestureRecognizer(tap)
            self.view.addSubview(newImageView)
        }
    }
    
    func dismissFullscreenImage(_ sender: UITapGestureRecognizer) {
        sender.view?.removeFromSuperview()
    }
    
    // Write message to database.
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        api.getConvo(withKey: convo.key, belongingToUser: convo.senderId, completion: { (convo) in
            if let convo = convo {
                self.convo = convo
                self.api.sendMessage(withText: text, withMediaType: "", usingSenderConvo: convo) { (convo, message) in
                    self.finishedWritingMessage()
                }
            }
        })
    }
    
    // Show multi media message options when user taps attachments button.
    override func didPressAccessoryButton(_ sender: UIButton!) {
        self.inputToolbar.contentView!.textView!.resignFirstResponder()
        let alert = UIAlertController(title: "Send:", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Photo 📸 / Video 🎥", style: .default, handler: { action in
            let fusuma = FusumaViewController()
            fusuma.delegate = self
            fusuma.hasVideo = true
            self.present(fusuma, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func finishedWritingMessage() {
        finishSendingMessage()
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        userIsTyping = false
    }
    
    // MARK: - Fusuma delegate
    
    // Return the image which is selected from camera roll or is taken via the camera.
    func fusumaImageSelected(_ image: UIImage) {
    }
    
    // Return the image but called after is dismissed.
    func fusumaDismissedWithImage(_ image: UIImage) {
        send(image: image)
    }
    
    func fusumaVideoCompleted(withFileURL fileURL: URL) {
        send(videoWithURL: fileURL)
    }
    
    // Call when camera roll not authorized.
    func fusumaCameraRollUnauthorized() {
        let alert = UIAlertController(title: "Access Camera", message: "Access the camera to send and take photos.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Go To Settings", style: .default) { (action) in
            if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
            }})
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    func send(image: UIImage) {
        api.getConvo(withKey: convo.key, belongingToUser: convo.senderId, completion: { (convo) in
            guard let convo = convo else { return }
            self.convo = convo
            
            // First send a placeholder message that displays a loading indicator.
            self.api.sendMessage(withText: "[Photo 📸]", withMediaType: "imagePlaceholder", usingSenderConvo: self.convo) { (convo, message) in
                self.finishSendingMessage()
                
                // Then upload the image to storage.
                self.api.upload(image: image, completion: { (url) in
                    
                    // The upload returns the URL to the image we just uploaded.
                    // Update the placeholder message with this info.
                    self.api.setMedia(forMessage: message, mediaType: "image", mediaURL: url.absoluteString)
                    self.finishedWritingMessage()
                })
            }
        })
    }
    
    func send(videoWithURL url: URL) {
        api.getConvo(withKey: convo.key, belongingToUser: convo.senderId, completion: { (convo) in
            guard let convo = convo else { return }
            self.convo = convo
            
            // First send a placeholder message that displays a loading indicator.
            self.api.sendMessage(withText: "[Video 🎥]", withMediaType: "videoPlaceholder", usingSenderConvo: self.convo) { (convo, message) in
                self.finishSendingMessage()
                
                // Then upload the image to storage.
                self.api.uploadVideo(fromURL: url, completion: { (url) in
                    
                    // The upload returns the URL to the image we just uploaded.
                    // Update the placeholder message with this info.
                    self.api.setMedia(forMessage: message, mediaType: "video", mediaURL: url.absoluteString)
                    self.finishedWritingMessage()
                })
            }
        })
    }
    
    public func fusumaImageSelected(_ image: UIImage, source: FusumaMode) {}
    
    // MARK: - Text view
    // Keep track of when user is typing.
    override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
        userIsTyping = textView.text != ""
    }
    
    // MARK: - Navigation
    func showConvoInfoTableViewController() {
        let dest = storyboard?.instantiateViewController(withIdentifier: Identifiers.ConvoInfoTableViewController) as! ConvoInfoTableViewController
        dest.convo = convo
        navigationController?.pushViewController(dest, animated: true)
    }
}
