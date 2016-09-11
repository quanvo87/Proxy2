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
    
    var nicknameRef = FIRDatabaseReference()
    var nicknameRefHandle = FIRDatabaseHandle()
    
    var senderIconRef = FIRDatabaseReference()
    var senderIconRefHandle = FIRDatabaseHandle()
    var receiverIconRef = FIRDatabaseReference()
    var receiverIconRefHandle = FIRDatabaseHandle()
    var icons = [String: JSQMessagesAvatarImage]()
    
    var unreadRef = FIRDatabaseReference()
    var unreadRefHandle = FIRDatabaseHandle()
    
    var messagesRef = FIRDatabaseReference()
    var messagesRefHandle = FIRDatabaseHandle()
    var messages = [JSQMessage]()
    
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
//        observeNickname()
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
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(true)
        self.tabBarController?.tabBar.hidden = false
        userTypingRef.removeValue()
    }
    
    deinit {
//        nicknameRef.removeObserverWithHandle(nicknameRefHandle)
//        proxyRef.removeObserverWithHandle(proxyRefHandle)
        senderIconRef.removeObserverWithHandle(senderIconRefHandle)
        receiverIconRef.removeObserverWithHandle(receiverIconRefHandle)
        unreadRef.removeObserverWithHandle(unreadRefHandle)
        messagesRef.removeObserverWithHandle(messagesRefHandle)
        membersTypingRef.removeObserverWithHandle(membersTypingRefHandle)
    }
    
    func setUp() {
        navigationController!.view.backgroundColor = UIColor.whiteColor()
        senderId = convo.senderId
        
        // TODO: Add logic to show either senderNickname or senderProxy
        senderDisplayName = convo.senderProxy
        
        collectionView?.collectionViewLayout.incomingAvatarViewSize = CGSize(width: kJSQMessagesCollectionViewAvatarSizeDefault, height:kJSQMessagesCollectionViewAvatarSizeDefault)
        collectionView?.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: kJSQMessagesCollectionViewAvatarSizeDefault, height:kJSQMessagesCollectionViewAvatarSizeDefault)
        automaticallyScrollsToMostRecentMessage = true
    }
    
    func setUpBubbles() {
        let factory = JSQMessagesBubbleImageFactory()
        incomingBubble = factory.incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
        outgoingBubble = factory.outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleBlueColor())
    }
    
    // MARK: - Database
    // TODO: Change this to `observeReceiverNickname`
    func observeNickname() {
        nicknameRef = ref.child("convos").child(api.uid).child(convo.key).child("receiverNickname")
        nicknameRefHandle = nicknameRef.observeEventType(.Value, withBlock: { snapshot in
            if let nickname = snapshot.value as? String {
                self.convo.receiverNickname = nickname
            }
        })
    }
    
    // TODO: Add observer for `senderNickname`
    
    // Observe sender's icon
    func observeSenderIcon() {
        senderIconRef = ref.child("proxies").child(convo.senderId).child(convo.senderProxy).child("icon")
        senderIconRefHandle = senderIconRef.observeEventType(.Value, withBlock: { (snapshot) in
            if let icon = snapshot.value as? String {
                self.api.getImage(forIcon: icon, completion: { (image) in
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
                self.api.getImage(forIcon: icon, completion: { (image) in
                    self.icons[self.convo.receiverId] = JSQMessagesAvatarImage(placeholder: image)
                    self.collectionView.reloadData()
                })
            }
        })
    }
    
    
    // Observe the messages for this convo
    func observeMessages() {
        messagesRef = ref.child("messages").child(convo.key)
        messagesRefHandle = messagesRef.queryOrderedByChild("timestamp").observeEventType(.ChildAdded, withBlock: { (snapshot) in
            let message = Message(anyObject: snapshot.value!)
            let jsqMessage = JSQMessage(senderId: message.sender, senderDisplayName: self.convo.senderProxy, date: NSDate(timeIntervalSince1970: message.timestamp), text: message.message)
            self.messages.append(jsqMessage)
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
            if let unread = snapshot.value as? Int {
                if unread != 0 {
                    self.api.decrementAllUnreadFor(convo: self.convo, byAmount: unread)
                }
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
        return messages.count
    }
    
    // Distinguish between sender and receiver chat bubble
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        return messages[indexPath.item].senderId == self.senderId ? outgoingBubble : incomingBubble
    }
    
    // Chat bubble color
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        if messages[indexPath.item].senderId == senderId {
            cell.textView!.textColor = UIColor.whiteColor()
        } else {
            cell.textView?.textColor = UIColor.blackColor()
        }
        return cell
    }
    
    // Returns avatars for the proxies
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        let message = self.messages[indexPath.item]
        if indexPath.item + 1 < messages.count {
            let next = self.messages[indexPath.item + 1]
            if message.senderId != next.senderId {
                return icons[message.senderId]
            }
        } else {
            return icons[message.senderId]
        }
        return nil
    }
    
    // Create space for timestamp
    override func collectionView(collectionView: JSQMessagesCollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout, heightForCellTopLabelAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.item - 1 > 0 {
            let prev = self.messages[indexPath.item - 1]
            let message = self.messages[indexPath.item]
            
            if message.date.timeIntervalSinceDate(prev.date) / 60 > Settings.TimestampInterval {
                return kJSQMessagesCollectionViewCellLabelHeightDefault
            }
        }
        return 0
    }
    
    // Show text for timestamp
    override func collectionView(collectionView: JSQMessagesCollectionView, attributedTextForCellTopLabelAtIndexPath indexPath: NSIndexPath) -> NSAttributedString? {
        let message = self.messages[indexPath.item]
        if indexPath.item - 1 > 0 {
            let prev = self.messages[indexPath.item - 1]
            
            if message.date.timeIntervalSinceDate(prev.date) / 60 > Settings.TimestampInterval {
                return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(message.date)
            }
        }
        return nil
    }
    
    // The message
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    // Writes the message to the database
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        api.send(message: text, usingSenderConvo: convo) { (convo) in
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