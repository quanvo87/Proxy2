//
//  StartAConversationViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/25/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase

class StartAConversationViewController: UIViewController {
    
    private let api = API.sharedInstance
    private let ref = FIRDatabase.database().reference()
    var sender = [:]
    private var senderKey = ""
    private var senderOwner = ""
    private var senderName = ""
    private var senderInvites = ["" : true]
    private var senderInvitesFrom = ["" : true]
    private var receiverKey = ""
    private var receiverOwner = ""
    private var recieverName = ""
    private var receiverInvites = ["" : true]
    private var receiverInvitesFrom = ["" : true]
    
    @IBOutlet weak var startAConversationBetweenLabel: UILabel!
    @IBOutlet weak var firstWordTextField: UITextField!
    @IBOutlet weak var secondWordTextField: UITextField!
    @IBOutlet weak var numberTextField: UITextField!
    @IBOutlet weak var firstMessageTextField: UITextField!
    @IBOutlet weak var sendInviteButton: UIButton!
    @IBOutlet weak var cancelStartAConversationButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpUI()
        setProxyData()
    }
    
    func setUpUI() {
        startAConversationBetweenLabel.text = "Starting A Conversation Between \(senderName) And..."
        firstWordTextField.clearButtonMode = .WhileEditing
        secondWordTextField.clearButtonMode = .WhileEditing
        numberTextField.clearButtonMode = .WhileEditing
        firstMessageTextField.clearButtonMode = .WhileEditing
    }
    
    func setProxyData() {
        senderKey = sender["key"] as! String
        senderOwner = sender["owner"] as! String
        senderName = sender["name"] as! String
        if let invites = sender["invites"] {
            senderInvites = invites as! [String : Bool]
        }
        if let invitesFrom = sender["invitesFrom"] {
            senderInvitesFrom = invitesFrom as! [String : Bool]
        }
    }
    
    @IBAction func tapSendInviteButton(sender: AnyObject) {
//        self.sendInviteButton.enabled = false
//        guard
//            let firstWord = firstWordTextField.text,
//            let secondWord = secondWordTextField.text,
//            let number = numberTextField.text
//            
//            // check for blank fields
//            where firstWord != "" && secondWord != "" && number != "" else {
//                self.sendInviteButton.enabled = true
//                showAlert("Empty Fields", message: "Please enter a valid value in all the fields.")
//                return
//        }
//        
//        let proxyName = firstWord.lowercaseString + secondWord.lowercaseString.capitalizedString + number
//        self.ref.child("proxies").queryOrderedByChild("name").queryEqualToValue(proxyName).observeSingleEventOfType(.Value, withBlock: { snapshot in
//            
//            // check if proxy exists
//            guard snapshot.childrenCount > 0 else {
//                self.sendInviteButton.enabled = true
//                self.showAlert("Proxy Doesn't Exist", message: "Please try again.")
//                return
//            }
//            
////            let receiverProxy = Proxy(snapshot: snapshot.children.nextObject() as! FIRDataSnapshot)
//            
//            // check for proxy not belong to sender
//            guard receiverProxy.owner != self.api.uid else {
//                self.sendInviteButton.enabled = true
//                self.showAlert("Can't Message Yourself", message: "That proxy belongs to you.")
//                return
//            }
//            
//            // check for existing invite for both users
//            self.ref.child("proxies").child(receiverProxy.key).child("invitesFrom").queryOrderedByKey().queryEqualToValue(self.proxy.name).observeSingleEventOfType(.Value, withBlock: { snapshot in
//                
//                guard snapshot.childrenCount == 0 else {
//                    self.sendInviteButton.enabled = true
//                    self.showAlert("Invite Already Exists", message: "An invite already exists between these proxies.")
//                    return
//                }
//                
//                // create the invite
//                let key = self.ref.child("invites").childByAutoId().key
//                let invite = Invite(key: key, senderProxyName: self.proxy.name, receiverId: receiverProxy.owner, receiverProxyName: receiverProxy.name, message: self.firstMessageTextField.text!).toAnyObject()
//                
//                self.ref.updateChildValues([
//                    "/invites/\(key)": invite,
//                    "/users/\(self.api.uid)/proxies/\(self.proxy.key)/invites/\(key)": invite,
//                    "/users/\(self.api.uid)/proxies/\(self.proxy.key)/invitesFrom/\(receiverProxy.name)": true,
//                    "/users/\(receiverProxy.owner)/proxies/\(receiverProxy.key)/invites/\(key)": invite,
//                    "/users/\(receiverProxy.owner)/proxies/\(receiverProxy.key)/invitesFrom/\(self.proxy.name)": true])
//                self.dismissViewControllerAnimated(true, completion: nil)
//            })
//        })
    }
    
    @IBAction func tapCancelStartAConversationButton(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}