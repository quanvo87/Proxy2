//
//  ConvoTableViewController.swift
//  proxy
//
//  Created by Quan Vo on 9/3/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase

class ConvoTableViewController: UITableViewController {

    var convo = Convo()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setTitle()
    }
    
    func setTitle() {
        let title = convoTitle(convo.convoNickname, proxyNickname: convo.proxyNickname, you: convo.senderProxy, them: convo.receiverProxy, size: 13, navBar: true)
        let navLabel = UILabel()
        navLabel.numberOfLines = 2
        navLabel.textAlignment = .Center
        navLabel.attributedText = title
        navLabel.sizeToFit()
        navigationItem.titleView = navLabel
    }
}

// set observer to convo nickname and change title accordingly
// set observer for members to monitor when user changes their nickname
// cant delete members when delete proxy or leave conversation then
// instead, set present bool to false
// each time someone leaves a convo, check both bools, if both false, delete convo/both members