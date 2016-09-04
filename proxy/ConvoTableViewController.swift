//
//  ConvoTableViewController.swift
//  proxy
//
//  Created by Quan Vo on 9/3/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase

class ConvoTableViewController: UITableViewController {
    
    let api = API.sharedInstance
    let ref = FIRDatabase.database().reference()
    var nicknameRef = FIRDatabaseReference()
    var nicknameRefHandle = FIRDatabaseHandle()
    var proxyRef = FIRDatabaseReference()
    var proxyRefHandle = FIRDatabaseHandle()
    var convo = Convo()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setTitle()
        observeNickname()
        observeProxy()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        
        // The convo VC needs to hide the tab bar in order for its text input
        // bar to work, so we unhide it again here.
        self.tabBarController?.tabBar.hidden = false
    }
    
    deinit {
        // Stop observing this node on deinit
        nicknameRef.removeObserverWithHandle(nicknameRefHandle)
        proxyRef.removeObserverWithHandle(proxyRefHandle)
    }
    
    // A custom two-line title showing the participants of the convo.
    // Prioritizes nicknames, and gets updated when the user changes the convo's
    // nickname on this same screen.
    func setTitle() {
        let title = convoTitle(convo.convoNickname, proxyNickname: convo.proxyNickname, you: convo.senderProxy, them: convo.receiverProxy, size: 13, navBar: true)
        let navLabel = UILabel()
        navLabel.numberOfLines = 2
        navLabel.textAlignment = .Center
        navLabel.attributedText = title
        navLabel.sizeToFit()
        navigationItem.titleView = navLabel
    }
    
    // Watch the database for nickname changes to this convo. When they happen,
    // update the title of the view to reflect them.
    func observeNickname() {
        nicknameRef = ref.child("users").child(api.uid).child("convos").child(convo.key).child("convoNickname")
        nicknameRefHandle = nicknameRef.observeEventType(.Value, withBlock: { snapshot in
            if let nickname = snapshot.value as? String {
                self.convo.convoNickname = nickname
                self.setTitle()
            }
        })
    }
    
    // Observe the user's proxy to keep note of changes and update the title
    // and 'you' cell
    func observeProxy() {
        proxyRef = ref.child("users").child(api.uid).child("proxies").child(convo.senderProxy).child("nickname")
        proxyRefHandle = proxyRef.observeEventType(.Value, withBlock: { snapshot in
            if let nickname = snapshot.value as? String {
                self.convo.proxyNickname = nickname
                self.setTitle()
                let indexPath = NSIndexPath(forRow: 0, inSection: 2)
                if self.tableView.dequeueReusableCellWithIdentifier(Constants.Identifiers.BasicCell, forIndexPath: indexPath) is BasicCell {
                    self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                }
            }
        })
    }
    
    // To dismiss keyboard when user drags down on the view
    override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        view.endEditing(true)
    }
    
    // MARK: - Table view
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return 1
        case 2: return 1
        default: return 0
        }
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "NICKNAME - only you see this"
        case 1: return "MEMBERS"
        default: return nil
        }
    }
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 1: return "them"
        case 2: return "you"
        default: return nil
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        switch indexPath.section {
            
        // The nickname editor cell
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier(Constants.Identifiers.ConvoNicknameCell, forIndexPath: indexPath) as! ConvoNicknameCell
            
            cell.convo = convo
            
            // Needed in order for text field inside a cell to work
            cell.selectionStyle = .None
            
            return cell
            
            // The 'Members' section
        // 'them'
        case 1:
            let cell = tableView.dequeueReusableCellWithIdentifier(Constants.Identifiers.BasicCell, forIndexPath: indexPath) as! BasicCell
            cell.textLabel?.text = convo.receiverProxy
            return cell
            
        // 'you'
        case 2:
            let cell = tableView.dequeueReusableCellWithIdentifier(Constants.Identifiers.BasicCell, forIndexPath: indexPath) as! BasicCell
            cell.textLabel?.attributedText = youTitle(convo.senderProxy, nickname: convo.proxyNickname)
            return cell
            
        default: break
        }
        
        return UITableViewCell()
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        //        switch indexPath.section {
        //        case 1:
        //            switch indexPath.row {
        //            case 0:
        //                confirmDelete()
        //            default: return
        //            }
        //        default: return
        //        }
    }
}

// set observer to convo nickname and change title accordingly
// set observer for members to monitor when user changes their nickname