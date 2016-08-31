//
//  ConvoViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/30/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase
import JSQMessagesViewController

class ConvoViewController: UIViewController {

    private let api = API.sharedInstance
    private var messages = [JSQMessage]()
    private var incomingBubble: JSQMessagesBubbleImage!
    private var outgoingBubble: JSQMessagesBubbleImage!
    private var displayName: String!
    var convo = Convo()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        navigationItem.title = convo.members
    }
    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        navigationItem.title = convo.members
//        
//        collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSizeZero
//        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero
//        
//        let factory = JSQMessagesBubbleImageFactory()
//        incomingBubble = factory.incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
//        outgoingBubble = factory.outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleBlueColor())
//    }
//    
//    // MARK: JSQMessagesCollectionView Datasource
//    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return messages.count
//    }
//    
//    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
//        return messages[indexPath.item]
//    }
//    
//    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
//        
//        let message = messages[indexPath.item] // retrieve the message based on the NSIndexPath item.
//        if message.senderId == senderId { // Check if the message was sent by the local user. If so, return the outgoing image view.
//            return outgoingBubble
//        } else {  // If the message was not sent by the local user, return the incoming image view.
//            return incomingBubble
//        }
//    }
//    
//    // set text color based on who is sending the messages
//    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
//        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
//        
//        let message = messages[indexPath.item]
//        
//        if message.senderId == senderId {
//            cell.textView!.textColor = UIColor.whiteColor()
//        } else {
//            cell.textView?.textColor = UIColor.blackColor()
//        }
//        
//        
//        return cell
//    }
//    
//    // remove avatar support and close the gap where the avatars would normally get displayed.
//    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
//        return nil
//    }
//    
//    // MARK: - Create Message
//    // This helper method creates a new JSQMessage with a blank displayName and adds it to the data source.
//    func addMessage(id: String, text: String) {
//        let message = JSQMessage(senderId: id, displayName: "", text: text)
//        messages.append(message)
//    }
}