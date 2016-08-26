//
//  ProxyViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/25/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase

class ProxyViewController: UIViewController {
    
    private let api = API.sharedInstance
    private let ref = FIRDatabase.database().reference()
    private var conversationsReferenceHandle = FIRDatabaseHandle()
    private var invitesReferenceHandle = FIRDatabaseHandle()
    private var conversations = [Conversation]()
    private var invites = [Invite]()
    var proxy = [:]
    private var proxyKey = ""
    private var proxyName = ""
    private var proxyNickname = ""
    
    @IBOutlet weak var proxyNicknameLabel: UILabel!
    @IBOutlet weak var editProxyNicknameButton: UIButton!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setProxyData()
        setUpUI()
        configureDataBase()
        setUpTableView()
    }
    
    deinit {
        ref.child("users").child(api.uid).child("proxies").child(proxyKey).child("coversations").removeObserverWithHandle(conversationsReferenceHandle)
        ref.child("users").child(api.uid).child("proxies").child(proxyKey).child("invites").removeObserverWithHandle(invitesReferenceHandle)
    }
    
    func setProxyData() {
        proxyKey = proxy["key"] as! String
        proxyName = proxy["name"] as! String
        proxyNickname = proxy["nickname"] as! String
    }
    
    func setUpUI() {
        navigationItem.title = proxyName
        proxyNicknameLabel.text = proxyNickname == "" ? "\"\"" : "\"" + proxyNickname + "\""
    }
    
    func configureDataBase() {
        //        conversationsReferenceHandle = ref.child("users").child(api.uid).child("proxies").child(proxyKey).child("conversations").queryOrderedByChild("lastEventTime").observeEventType(.Value, withBlock: { snapshot in
        //            var newData = [Conversation]()
        //            for item in snapshot.children {
        //                let conversation = Conversation()
        //                newData.append(conversation)
        //            }
        //            self.conversations = newData
        //            self.tableView.reloadData()
        //        })
        
//        invitesReferenceHandle = ref.child("users").child(api.uid).child("proxies").child(proxyKey).child("invites").queryOrderedByChild("lastEventTime").observeEventType(.Value, withBlock: { snapshot in
//            var newData = [Invite]()
//            for item in snapshot.children {
//                let invite = Invite()
//                newData.append(invite)
//            }
//            self.invites = newData
//            self.tableView.reloadData()
//        })
    }
    
    func setUpTableView() {
        
    }
    
    @IBAction func tapEditProxyNicknameButton(sender: AnyObject) {
    }
    
    @IBAction func changeSegmentedControl(sender: AnyObject) {
        tableView.reloadData()
    }
    
    @IBAction func tapStartAConversationButton(sender: AnyObject) {
        if let startAConversationViewController = storyboard?.instantiateViewControllerWithIdentifier("Start A Conversation View Controller") as? StartAConversationViewController {
            startAConversationViewController.sender = proxy
            self.presentViewController(startAConversationViewController, animated: true, completion: nil)
        }
    }
    
    // MARK: - Table view data source
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            return conversations.count
        case 1:
            return invites.count
        default:
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        //        switch segmentedControl.selectedSegmentIndex {
        //        case 0:
        //
        //        case 1:
        //
        //        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Home Table View Cell", forIndexPath: indexPath) as! HomeTableViewCell
        //        let proxy = proxies[indexPath.row]
        //        cell.proxyNameLabel.text = proxy.name
        //        cell.proxyNicknameLabel.text = proxy.nickname == "" ? "" : "- \"" + proxy.nickname + "\""
        //        cell.lastEventMessageLabel.text = proxy.lastEvent
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //        let proxy = proxies[indexPath.row]
        //        if let proxyViewController = storyboard?.instantiateViewControllerWithIdentifier("Proxy View Controller") as? ProxyViewController {
        //            proxyViewController.proxyKey = proxy.key
        //            navigationItem.title = ""
        //            navigationController?.pushViewController(proxyViewController, animated: true)
        //        }
    }
}