//
//  ConvoCell.swift
//  proxy
//
//  Created by Quan Vo on 9/9/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase
import FirebaseStorage

class ConvoCell: UITableViewCell {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var unreadLabel: UILabel!
    
    let api = API.sharedInstance
    let ref = FIRDatabase.database().reference()
    
    var iconRef = FIRDatabaseReference()
    var iconRefHandle = FIRDatabaseHandle()
    
    var senderNicknameRef = FIRDatabaseReference()
    var senderNicknameRefHandle = FIRDatabaseHandle()
    var senderNickname = ""
    
    var receiverNicknameRef = FIRDatabaseReference()
    var receiverNicknameRefHandle = FIRDatabaseHandle()
    var receiverNickname = ""
    
    var unreadRef = FIRDatabaseReference()
    var unreadRefHandle = FIRDatabaseHandle()
    
    var lastMessageRef = FIRDatabaseReference()
    var lastMessageRefHandle = FIRDatabaseHandle()
    
    var convo = Convo() {
        didSet {
            setTitle()
            iconImageView.kf_indicatorType = .Activity
            timestampLabel.text = convo.timestamp.toTimeAgo()
            lastMessageLabel.text = ""
            unreadLabel.text = ""
            observeIcon()
            observeSenderNickname()
            observeReceiverNickname()
            observeUnread()
            observeLastMessage()
        }
    }

    deinit {
        iconRef.removeObserverWithHandle(iconRefHandle)
        senderNicknameRef.removeObserverWithHandle(senderNicknameRefHandle)
        unreadRef.removeObserverWithHandle(unreadRefHandle)
        lastMessageRef.removeObserverWithHandle(lastMessageRefHandle)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        iconRef.removeObserverWithHandle(iconRefHandle)
        senderNicknameRef.removeObserverWithHandle(senderNicknameRefHandle)
        unreadRef.removeObserverWithHandle(unreadRefHandle)
        lastMessageRef.removeObserverWithHandle(lastMessageRefHandle)
    }
    
    func setTitle() {
        titleLabel.attributedText = getConvoTitle(receiverNickname, receiverName: convo.receiverProxy, senderNickname: senderNickname, senderName: convo.senderProxy)
    }
    
    func observeIcon() {
        iconRef = ref.child(Path.Icon).child(convo.receiverProxy).child(Path.Icon)
        iconRefHandle = iconRef.observeEventType(.Value, withBlock: { (snapshot) in
            guard let icon = snapshot.value as? String where icon != "" else { return }
            self.api.getURL(forIcon: icon) { (url) in
                guard let url = url.absoluteString where url != "" else { return }
                self.iconImageView.image = nil
                self.iconImageView.kf_setImageWithURL(NSURL(string: url), placeholderImage: nil)
            }
        })
    }
    
    func observeSenderNickname() {
        senderNicknameRef = ref.child(Path.Nickname).child(convo.senderProxy).child(Path.Nickname)
        senderNicknameRefHandle = senderNicknameRef.observeEventType(.Value, withBlock: { (snapshot) in
            guard let nickname = snapshot.value as? String else { return }
            self.senderNickname = nickname
            self.setTitle()
        })
    }
    
    func observeReceiverNickname() {
        receiverNicknameRef = ref.child(Path.Nickname).child(convo.senderId).child(convo.key).child(Path.Nickname)
        receiverNicknameRefHandle = receiverNicknameRef.observeEventType(.Value, withBlock: { (snapshot) in
            guard let nickname = snapshot.value as? String else { return }
            self.receiverNickname = nickname
            self.setTitle()
        })
    }
    
    func observeUnread() {
        unreadRef = ref.child(Path.Unread).child(convo.senderId).child(convo.key)
        unreadRefHandle = unreadRef.observeEventType(.Value, withBlock: { (snapshot) in
            guard let unread = snapshot.value as? Int else { return }
            self.unreadLabel.text = unread.toUnreadLabel()
        })
    }
    
    func observeLastMessage() {
        lastMessageRef = ref.child(Path.Messages).child(convo.key)
        lastMessageRefHandle = lastMessageRef.queryOrderedByChild(Path.Timestamp).queryLimitedToLast(1).observeEventType(.ChildAdded, withBlock: { (snapshot) in
            let message = Message(anyObject: snapshot.value!)
            if message.senderId == self.convo.senderId {
                self.lastMessageLabel.text = "You: " + message.text
            } else {
                self.lastMessageLabel.text = message.text
            }
        })
    }
}
