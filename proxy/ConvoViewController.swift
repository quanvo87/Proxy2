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
    
    var convo = Convo()
    
    private var incomingBubble: JSQMessagesBubbleImage!
    private var outgoingBubble: JSQMessagesBubbleImage!
    private var messages = [JSQMessage]()
    
    private let api = API.sharedInstance
    
    private let ref = FIRDatabase.database().reference()
    
    private var messagesRef = FIRDatabaseReference()
    private var messagesRefHandle = FIRDatabaseHandle()
    
    private var unreadRef = FIRDatabaseReference()
    private var unreadRefHandle = FIRDatabaseHandle()
    
    private var userTypingRef = FIRDatabaseReference()
    private var membersTypingRef = FIRDatabaseReference()
    private var membersTypingRefHandle = FIRDatabaseHandle()
    private var _userTyping = false
    
    var userTyping: Bool {
        get {
            return _userTyping
        }
        set {
            _userTyping = newValue
            userTypingRef.setValue(newValue)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = convo.senderProxy + ", " + convo.receiverProxy
        
        self.senderId = convo.senderId
        self.senderDisplayName = convo.senderProxy
        
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSizeZero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero
        
        observeUnread()
        setUpBubbles()
        observeMessages()
        observeTyping()
    }
    
    deinit {
        unreadRef.removeObserverWithHandle(unreadRefHandle)
        messagesRef.removeObserverWithHandle(messagesRefHandle)
        membersTypingRef.removeObserverWithHandle(membersTypingRefHandle)
    }
    
    func observeUnread() {
        unreadRef = ref.child("users").child(convo.senderId).child("convos").child(convo.key).child("unread")
        unreadRefHandle = unreadRef.observeEventType(.Value, withBlock: { (snapshot) in
            if let unread = snapshot.value as? Int {
                if unread != 0 {
                    self.api.decreaseUnreadForUserBy(unread, user: self.convo.senderId, convo: self.convo.key, proxy: self.convo.senderProxy)
                }
            }
        })
    }
    
    func setUpBubbles() {
        let factory = JSQMessagesBubbleImageFactory()
        incomingBubble = factory.incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
        outgoingBubble = factory.outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleBlueColor())
    }
    
    func observeMessages() {
        messagesRef = ref.child("messages").child(convo.key)
        messagesRefHandle = messagesRef.queryOrderedByChild("timestamp").observeEventType(.ChildAdded, withBlock: { (snapshot) in
            let message = Message(anyObject: snapshot.value!)
            let jsqmessage = JSQMessage(senderId: message.sender, displayName: self.convo.senderProxy, text: message.message)
            self.messages.append(jsqmessage)
            self.finishReceivingMessage()
        })
    }
    
    private func observeTyping() {
        userTypingRef = ref.child("typing").child(convo.key).child(convo.senderId)
        userTypingRef.onDisconnectRemoveValue()
        
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
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        return messages[indexPath.item].senderId == self.senderId ? outgoingBubble : incomingBubble
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        if messages[indexPath.item].senderId == senderId {
            cell.textView!.textColor = UIColor.whiteColor()
        } else {
            cell.textView?.textColor = UIColor.blackColor()
        }
        return cell
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView, attributedTextForCellTopLabelAtIndexPath indexPath: NSIndexPath) -> NSAttributedString? {
        let message = self.messages[indexPath.item]
        if indexPath.item == 0 {
            return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(message.date)
        }
        if indexPath.item - 1 > 0 {
            let prev = self.messages[indexPath.item - 1]
            
            if message.date.timeIntervalSinceDate(prev.date) / 60 > Constants.ChatOptions.MinsTillTimestamp {
                return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(message.date)
            }
        }
        return nil
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout, heightForCellTopLabelAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.item == 0 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        if indexPath.item - 1 > 0 {
            let prev = self.messages[indexPath.item - 1]
            let message = self.messages[indexPath.item]
            
            if message.date.timeIntervalSinceDate(prev.date) / 60 > Constants.ChatOptions.MinsTillTimestamp {
                return kJSQMessagesCollectionViewCellLabelHeightDefault
            }
        }
        return 0
    }
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        self.api.sendMessage(convo, messageText: text) { (success) in
            JSQSystemSoundPlayer.jsq_playMessageSentSound()
            self.finishSendingMessage()
        }
    }
    
    override func didPressAccessoryButton(sender: UIButton!) {
        
    }
    
    // MARK: - Text view
    override func textViewDidChange(textView: UITextView) {
        super.textViewDidChange(textView)
        userTyping = textView.text != ""
    }
}