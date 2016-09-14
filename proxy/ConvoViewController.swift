//
//  ConvoViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/30/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase
import JSQMessagesViewController

class ConvoViewController: JSQMessagesViewController {
    
    let api = API.sharedInstance
    let ref = FIRDatabase.database().reference()
    var convo = Convo()
    var unreadReceiptIndex = 0
    
    var unreadRef = FIRDatabaseReference()
    var unreadRefHandle = FIRDatabaseHandle()
    
    var senderNicknameRef = FIRDatabaseReference()
    var senderNicknameRefHandle = FIRDatabaseHandle()
    var receiverNicknameRef = FIRDatabaseReference()
    var receiverNicknameRefHandle = FIRDatabaseHandle()
    var nicknames = [String: String]()
    
    var senderIconRef = FIRDatabaseReference()
    var senderIconRefHandle = FIRDatabaseHandle()
    var receiverIconRef = FIRDatabaseReference()
    var receiverIconRefHandle = FIRDatabaseHandle()
    var icons = [String: JSQMessagesAvatarImage]()
    
    var messagesRef = FIRDatabaseReference()
    var messagesRefHandle = FIRDatabaseHandle()
    var messages = [Message]()
    
    var membersTypingRef = FIRDatabaseReference()
    var membersTypingRefHandle = FIRDatabaseHandle()
    var userTypingRef = FIRDatabaseReference()
    var userTyping = false {
        didSet {
            userTypingRef.setValue(userTyping)
        }
    }
    
    var incomingBubble: JSQMessagesBubbleImage!
    var outgoingBubble: JSQMessagesBubbleImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
        observeSenderNickname()
        observerRecieverNickname()
        setUpBubbles()
        observeSenderIcon()
        observeReceiverIcon()
        observeMessages()
        observeTyping()
        observeUnread()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewDidDisappear(true)
        navigationItem.title = convo.receiverProxy
        self.tabBarController?.tabBar.hidden = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        self.tabBarController?.tabBar.hidden = false
        userTypingRef.removeValue()
    }
    
    deinit {
        unreadRef.removeObserverWithHandle(unreadRefHandle)
        senderNicknameRef.removeObserverWithHandle(senderNicknameRefHandle)
        receiverNicknameRef.removeObserverWithHandle(receiverNicknameRefHandle)
        senderIconRef.removeObserverWithHandle(senderIconRefHandle)
        receiverIconRef.removeObserverWithHandle(receiverIconRefHandle)
        messagesRef.removeObserverWithHandle(messagesRefHandle)
        membersTypingRef.removeObserverWithHandle(membersTypingRefHandle)
    }
    
    // MARK: - Set up
    func setUp() {
        navigationController!.view.backgroundColor = UIColor.whiteColor()
        nicknames[convo.senderId] = convo.senderProxy
        nicknames[convo.receiverId] = convo.receiverProxy
        senderId = convo.senderId
        senderDisplayName = ""
        collectionView?.collectionViewLayout.incomingAvatarViewSize = CGSize(width: kJSQMessagesCollectionViewAvatarSizeDefault, height:kJSQMessagesCollectionViewAvatarSizeDefault)
        collectionView?.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: kJSQMessagesCollectionViewAvatarSizeDefault, height:kJSQMessagesCollectionViewAvatarSizeDefault)
    }
    
    func setUpBubbles() {
        let factory = JSQMessagesBubbleImageFactory()
        incomingBubble = factory.incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
        outgoingBubble = factory.outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleBlueColor())
    }
    
    // MARK: - Database
    // Observe sender's nickname
    func observeSenderNickname() {
        senderNicknameRef = ref.child("proxies").child(convo.senderId).child(convo.senderProxy).child("nickname")
        senderNicknameRefHandle = senderNicknameRef.observeEventType(.Value, withBlock: { (snapshot) in
            if let nickname = snapshot.value as? String {
                self.nicknames[self.convo.senderId] = nickname == "" ? self.convo.senderProxy : nickname
                self.collectionView.reloadData()
            }
        })
    }
    
    // Observe receiver's nickname
    func observerRecieverNickname() {
        receiverNicknameRef = ref.child("convos").child(convo.senderId).child(convo.key).child("receiverNickname")
        receiverNicknameRefHandle = receiverNicknameRef.observeEventType(.Value, withBlock: { snapshot in
            if let nickname = snapshot.value as? String {
                self.nicknames[self.convo.receiverId] = nickname == "" ? self.convo.receiverProxy : nickname
                self.collectionView.reloadData()
            }
        })
    }
    
    // Observe sender's icon
    func observeSenderIcon() {
        senderIconRef = ref.child("proxies").child(convo.senderId).child(convo.senderProxy).child("icon")
        senderIconRefHandle = senderIconRef.observeEventType(.Value, withBlock: { (snapshot) in
            if let icon = snapshot.value as? String {
                self.api.getUIImage(forIcon: icon, completion: { (image) in
                    self.icons[self.convo.senderId] = JSQMessagesAvatarImage(placeholder: image)
                    self.collectionView.reloadData()
                })
            }
        })
    }
    
    // Observe receiver's icon
    func observeReceiverIcon() {
        receiverIconRef = ref.child("proxies").child(convo.receiverId).child(convo.receiverProxy).child("icon")
        receiverIconRefHandle = receiverIconRef.observeEventType(.Value, withBlock: { (snapshot) in
            if let icon = snapshot.value as? String {
                self.api.getUIImage(forIcon: icon, completion: { (image) in
                    self.icons[self.convo.receiverId] = JSQMessagesAvatarImage(placeholder: image)
                    self.collectionView.reloadData()
                })
            }
        })
    }
    
    // Observe and build the messages for this convo
    // Mark messages to this user as read
    func observeMessages() {
        messagesRef = ref.child("messages").child(convo.key)
        messagesRefHandle = messagesRef.queryOrderedByChild("timestamp").observeEventType(.ChildAdded, withBlock: { (snapshot) in
            let message = Message(anyObject: snapshot.value!)
            if message.senderId != self.senderId && !message.read {
                self.api.setRead(forMessage: message)
            }
            self.messages.append(message)
            self.finishReceivingMessage()
        })
    }
    
    // Upon entering the convo, decrement user's, convo's, proxy convo's, and proxy's
    // unread by this convo's unread count.
    // Upon further increments to this convo's unread count,
    // decrement those unread counts again by that increment.
    func observeUnread() {
        unreadRef = ref.child("convos").child(convo.senderId).child(convo.key).child("unread")
        unreadRefHandle = unreadRef.observeEventType(.Value, withBlock: { (snapshot) in
            if let unread = snapshot.value as? Int where unread != 0 {
                self.api.decrementAllUnreadFor(convo: self.convo, byAmount: unread)
            }
        })
    }
    
    func observeTyping() {
        // Stop monitoring user's typing when they disconnect
        userTypingRef = ref.child("typing").child(convo.key).child(convo.senderId)
        userTypingRef.onDisconnectRemoveValue()
        
        // Show typing indicator when other user is typing
        membersTypingRef = ref.child("typing").child(convo.key)
        membersTypingRefHandle = membersTypingRef.queryOrderedByValue().queryEqualToValue(true).observeEventType(.Value, withBlock: { (snapshot) in
            if snapshot.childrenCount == 1 && self.userTyping {
                return
            }
            self.showTypingIndicator = snapshot.childrenCount > 0
            self.scrollToBottomAnimated(true)
        })
    }
    
    // MARK: - JSQMessagesCollectionView
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        unreadReceiptIndex = messages.count - 1
        while unreadReceiptIndex > -1 {
            let message = messages[unreadReceiptIndex]
            if message.senderId == senderId {
                break
            }
            unreadReceiptIndex -= 1
        }
        return messages.count
    }
    
    // Distinguish between sender and receiver chat bubble
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        return messages[indexPath.item].senderId == self.senderId ? outgoingBubble : incomingBubble
    }
    
    // Set up cell
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        
        // Outgoing message
        if messages[indexPath.item].senderId == senderId {
            cell.textView!.textColor = UIColor.whiteColor()
            cell.messageBubbleTopLabel.textInsets = UIEdgeInsetsMake(0, 0, 0, 40)
        
        // Incoming message
        } else {
            cell.textView?.textColor = UIColor.blackColor()
            cell.messageBubbleTopLabel.textInsets = UIEdgeInsetsMake(0, 40, 0, 0)
            cell.textView.linkTextAttributes = [
                NSForegroundColorAttributeName: UIColor().blue(),
                NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue]
        }
        return cell
    }
    
    // Make space for timestamp
    override func collectionView(collectionView: JSQMessagesCollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout, heightForCellTopLabelAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.item - 1 > 0 {
            let prev = self.messages[indexPath.item - 1]
            let cur = self.messages[indexPath.item]
            if cur.date.timeIntervalSinceDate(prev.date) / 60 > Settings.TimeBetweenTimestamps {
                return kJSQMessagesCollectionViewCellLabelHeightDefault
            }
        } else {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        return 0
    }
    
    // Get timestamp
    override func collectionView(collectionView: JSQMessagesCollectionView, attributedTextForCellTopLabelAtIndexPath indexPath: NSIndexPath) -> NSAttributedString? {
        let message = self.messages[indexPath.item]
        if indexPath.item - 1 > 0 {
            let prev = self.messages[indexPath.item - 1]
            if message.date.timeIntervalSinceDate(prev.date) / 60 > Settings.TimeBetweenTimestamps {
                return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(message.date)
            }
        } else {
            return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(message.date)
        }
        return nil
    }
    
    // Get avatars
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        if indexPath.item + 1 < messages.count {
            let cur = self.messages[indexPath.item]
            let next = self.messages[indexPath.item + 1]
            if cur.senderId != next.senderId {
                return icons[cur.senderId]
            }
        } else {
            let message = self.messages[indexPath.item]
            return icons[message.senderId]
        }
        return nil
    }
    
    // Make space for proxy names
    override func collectionView(collectionView: JSQMessagesCollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout, heightForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.item == 0 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        if indexPath.item - 1 > 0 {
            let prev = self.messages[indexPath.item - 1]
            let cur = self.messages[indexPath.item]
            if cur.senderId != prev.senderId {
                return kJSQMessagesCollectionViewCellLabelHeightDefault
            }
        }
        return 0
    }
    
    // Get proxy names
    override func collectionView(collectionView: JSQMessagesCollectionView, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath) -> NSAttributedString? {
        if indexPath.item == 0 {
            let message = messages[indexPath.item]
            return NSAttributedString(string: nicknames[message.senderId]!)
        }
        if indexPath.item - 1 > 0 {
            let prev = self.messages[indexPath.item - 1]
            let cur = self.messages[indexPath.item]
            if cur.senderId != prev.senderId {
                return NSAttributedString(string: nicknames[cur.senderId]!)
            }
        }
        return nil
    }
    
    // Make space for read receipt
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        let message = messages[indexPath.item]
        if indexPath.item == unreadReceiptIndex && message.read {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        return 0
    }
    
    // Get read receipt
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.item]
        if indexPath.item == unreadReceiptIndex && message.read {
            let read = "Read ".makeBold(withSize: 12)
            let timestamp = NSAttributedString(string: message.timeRead.toTimeAgo())
            read.appendAttributedString(timestamp)
            return read
        }
        return nil
    }
    
    // Get message data for row
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    // Write the message to the database when user taps send
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        api.send(messageWithText: text, usingSenderConvo: convo) { (convo) in
            JSQSystemSoundPlayer.jsq_playMessageSentSound()
            self.finishSendingMessage()
        }
    }
    
    override func didPressAccessoryButton(sender: UIButton!) {
        
    }
    
    // MARK: - Text view
    // Keep track of when user is typing
    override func textViewDidChange(textView: UITextView) {
        super.textViewDidChange(textView)
        userTyping = textView.text != ""
    }
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Segues.ConvoDetailSegue {
            if let dest = segue.destinationViewController as? ConvoInfoTableViewController {
                navigationItem.title = nil
                dest.convo = convo
            }
        }
    }
}