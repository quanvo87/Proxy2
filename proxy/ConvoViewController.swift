//
//  ConvoViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/30/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase
import JSQMessagesViewController

class ConvoViewController: JSQMessagesViewController, ConvoInfoTableViewControllerDelegate {
    
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
        observeRecieverNickname()
        observeMessages()
        observeTyping()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        self.tabBarController?.tabBar.hidden = true
        if senderIsPresentIsSetUp {
            senderIsPresent = true
        }
        decrementUnread()
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
        setTitle()
        navigationController!.view.backgroundColor = UIColor.whiteColor()
        navigationItem.rightBarButtonItem = createInfoButton()
        collectionView?.collectionViewLayout.incomingAvatarViewSize = CGSize(width: kJSQMessagesCollectionViewAvatarSizeDefault, height:kJSQMessagesCollectionViewAvatarSizeDefault)
        collectionView?.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: kJSQMessagesCollectionViewAvatarSizeDefault, height:kJSQMessagesCollectionViewAvatarSizeDefault)
        senderId = convo.senderId
        senderDisplayName = ""
        names[convo.senderId] = convo.senderProxy
        names[convo.receiverId] = convo.receiverProxy
    }
    
    func setTitle() {
        navigationItem.title = names[convo.receiverId] == "" ? convo.receiverProxy : names[convo.receiverId]
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
        senderIsPresentRef = ref.child("present").child(convo.key).child(convo.senderId)
        senderIsPresentRef.onDisconnectRemoveValue()
        senderIsPresentIsSetUp = true
        senderIsPresent = true
    }
    
    // Observe when receiver enters the convo while we are in it.
    // If this happens, refresh the cell with our last message to them to display the read receipt.
    func observeReceiverIsPresent() {
        receiverIsPresentRef = ref.child("present").child(convo.key).child(convo.receiverId)
        receiverIsPresentRefHandle = receiverIsPresentRef.observeEventType(.Value, withBlock: { (snapshot) in
            if let present = snapshot.value as? Bool where present {
                if self.readReceiptIndex > -1 && !self.messages[self.readReceiptIndex].read {
                    self.api.getMessage(withKey: self.messages[self.readReceiptIndex].key, inConvo: self.convo.key, completion: { (message) in
                        self.messages[self.readReceiptIndex] = message
                        self.collectionView.reloadItemsAtIndexPaths([NSIndexPath(forItem: self.readReceiptIndex, inSection: 0)])
                    })
                }
            }
        })
    }
    
    // Observe when sender changes their nickname and update all cells that are displaying it.
    func observeSenderNickname() {
        senderNicknameRef = ref.child("proxies").child(convo.senderId).child(convo.senderProxy).child("nickname")
        senderNicknameRefHandle = senderNicknameRef.observeEventType(.Value, withBlock: { (snapshot) in
            if let nickname = snapshot.value as? String {
                self.names[self.convo.senderId] = nickname == "" ? self.convo.senderProxy : nickname
                self.collectionView.reloadData()
            }
        })
    }
    
    // Observe when sender changes receiver's nickname and update all cells that are displaying it.
    func observeRecieverNickname() {
        receiverNicknameRef = ref.child("convos").child(convo.senderId).child(convo.key).child("receiverNickname")
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
    
    // Observe when receiver changes his/her icon to update all cells that are displaying it.
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
    
    // Observe and build the messages for this convo.
    // Mark unread messages to this user as read.
    // Keep track of the index of the last message you sent (for read receipt purposes).
    func observeMessages() {
        messagesRef = ref.child("messages").child(convo.key)
        messagesRefHandle = messagesRef.queryOrderedByChild("timestamp").observeEventType(.ChildAdded, withBlock: { (snapshot) in
            let message = Message(anyObject: snapshot.value!)
            self.messages.append(message)
            if message.senderId != self.senderId {
                if !message.read {
                    self.api.setRead(forMessage: message)
                }
            } else {
                self.readReceiptIndex = self.messages.count - 1
            }
            self.finishReceivingMessage()
        })
    }
    
    // Decrement user's, convo's, proxy convo's, and proxy's unread by this convo's unread count.
    func decrementUnread() {
        ref.child("convos").child(convo.senderId).child(convo.key).child("unread").observeSingleEventOfType(.Value, withBlock: { (snapshot) in
            if let unread = snapshot.value as? Int where unread > 0 {
                self.api.decrementAllUnreadFor(convo: self.convo, byAmount: unread)
            }
        })
    }
    
    func observeTyping() {
        // Stop monitoring user's typing when they disconnect.
        userTypingRef = ref.child("typing").child(convo.key).child(convo.senderId)
        userTypingRef.onDisconnectRemoveValue()
        
        // Show typing indicator when other user is typing.
        membersAreTypingRef = ref.child("typing").child(convo.key)
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
    
    // Display a centered timestamp before the very first message in the convo;
    // and when too much time has passed between two messages.
    // Make space for timestamp.
    override func collectionView(collectionView: JSQMessagesCollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout, heightForCellTopLabelAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.item == 0 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        
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
        
        if indexPath.item == 0 {
            return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(curr.date)
        }
        
        let prev = self.messages[indexPath.item - 1]
        if curr.date.timeIntervalSinceDate(prev.date) / 60 > Settings.TimeBetweenTimestamps {
            return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(curr.date)
        }
        
        return nil
    }
    
    // Display an avatar for the first message of the convo.
    // Display an avatar for the last message of the convo.
    // Display an avatar for each user on message chain breaks.
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        let curr = self.messages[indexPath.item]
        
        if indexPath.item == 0 {
            return icons[curr.senderId]
        }
        
        if indexPath.item == messages.count - 1 {
            return icons[curr.senderId]
        }
        
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
    
    // Show names/nicknames for last message by either user. (only one activated currently)
    // Make space for proxy names.
    override func collectionView(collectionView: JSQMessagesCollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout, heightForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath) -> CGFloat {
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
    
    // Write the message to the database when user taps send.
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: NSDate!) {
        api.send(messageWithText: text, usingSenderConvo: convo) { (convo) in
            self.finishSendingMessage()
            JSQSystemSoundPlayer.jsq_playMessageSentSound()
            self.userTyping = false
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
    func showConvoInfoTableViewController() {
        let dest = storyboard?.instantiateViewControllerWithIdentifier(Identifiers.ConvoInfoTableViewController) as! ConvoInfoTableViewController
        dest.convo = convo
        dest.delegate = self
        navigationController?.pushViewController(dest, animated: true)
    }
    
    func didLeaveConvo() {
        _didLeaveConvo = true
    }
    
    func leaveConvo() {
        if _didLeaveConvo {
            navigationController?.popViewControllerAnimated(true)
        }
    }
}
