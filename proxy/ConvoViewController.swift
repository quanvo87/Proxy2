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
    let api = API.sharedInstance
    
    let ref = FIRDatabase.database().reference()
    
    var nicknameRef = FIRDatabaseReference()
    var nicknameRefHandle = FIRDatabaseHandle()
    
    var proxyRef = FIRDatabaseReference()
    var proxyRefHandle = FIRDatabaseHandle()
    
    var unreadRef = FIRDatabaseReference()
    var unreadRefHandle = FIRDatabaseHandle()
    
    var messagesRef = FIRDatabaseReference()
    var messagesRefHandle = FIRDatabaseHandle()
    
    var membersTypingRef = FIRDatabaseReference()
    var membersTypingRefHandle = FIRDatabaseHandle()
    
    var userTypingRef = FIRDatabaseReference()
    var _userTyping = false
    
    var incomingBubble: JSQMessagesBubbleImage!
    var outgoingBubble: JSQMessagesBubbleImage!
    var messages = [JSQMessage]()
    
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
        
        navigationController!.view.backgroundColor = UIColor.whiteColor()
        
        senderId = convo.senderId
        senderDisplayName = convo.senderProxy
        
        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSizeZero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero
        
//        observeNickname()
//        observeProxy()
        
        setUpBubbles()
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
        nicknameRef.removeObserverWithHandle(nicknameRefHandle)
        proxyRef.removeObserverWithHandle(proxyRefHandle)
        unreadRef.removeObserverWithHandle(unreadRefHandle)
        messagesRef.removeObserverWithHandle(messagesRefHandle)
        membersTypingRef.removeObserverWithHandle(membersTypingRefHandle)
    }
    
    // MARK: - Database
    func observeNickname() {
        nicknameRef = ref.child("convos").child(api.uid).child(convo.key).child("receiverNickname")
        nicknameRefHandle = nicknameRef.observeEventType(.Value, withBlock: { snapshot in
            if let nickname = snapshot.value as? String {
                self.convo.receiverNickname = nickname
            }
        })
    }
    
    // Observe the user's proxy to keep note of changes and update the title
    func observeProxy() {
        proxyRef = ref.child("proxies").child(api.uid).child(convo.senderProxy).child("nickname")
        proxyRefHandle = proxyRef.observeEventType(.Value, withBlock: { snapshot in
            if let nickname = snapshot.value as? String {
                self.convo.senderNickname = nickname
            }
        })
    }
    
    // Decrements user, convo, proxy convo, and proxy unread by the convo's
    // starting unread count upon load. Further unread increments to this convo
    // are immediately set to 0 and the corresponding unreads decremented.
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
    
    func observeTyping() {
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
        if indexPath.item - 1 > 0 {
            let prev = self.messages[indexPath.item - 1]
            
            if message.date.timeIntervalSinceDate(prev.date) / 60 > Settings.TimestampInterval {
                return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(message.date)
            }
        }
        return nil
    }
    
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
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        api.send(message: text, usingSenderConvo: convo) { (convo) in
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