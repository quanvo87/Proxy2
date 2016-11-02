//
//  SelectReceiverViewController.swift
//  proxy
//
//  Created by Quan Vo on 11/1/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase
import RAMReel

class SelectReceiverViewController: UIViewController, UICollectionViewDelegate {
    
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    let api = API.sharedInstance
    var selectReceiverDelegate: SelectReceiverDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SelectReceiverViewController.keyboardWillShow), name: UIKeyboardWillShowNotification, object: self.view.window)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(SelectReceiverViewController.keyboardWillHide), name: UIKeyboardWillHideNotification, object: self.view.window)
        
        navigationItem.title = "Select Receiver"
        
        let cancelButton = UIButton(type: .Custom)
        cancelButton.setImage(UIImage(named: "cancel"), forState: UIControlState.Normal)
        cancelButton.addTarget(self, action: #selector(SelectReceiverViewController.close), forControlEvents: UIControlEvents.TouchUpInside)
        cancelButton.frame = CGRectMake(0, 0, 25, 25)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cancelButton)
        
        FIRDatabase.database().reference().child(Path.Proxies).queryOrderedByChild(Path.Key).observeSingleEventOfType(.Value, withBlock: { snapshot in
            
            var proxies = [String]()
            
            for child in snapshot.children {
                let proxy = Proxy(anyObject: child.value)
                if proxy.key != "" {
                    proxies.append(proxy.key.lowercaseString)
                }
            }
            
            let dataSource = SimplePrefixQueryDataSource(proxies)
            var ramReel: RAMReel<RAMCell, RAMTextField, SimplePrefixQueryDataSource>!
            ramReel = RAMReel(frame: self.view.bounds, dataSource: dataSource, placeholder: "Tap to begin typing…") {
                if $0 != "" {
                    self.api.getProxy($0, completion: { (proxy) in
                        if let proxy = proxy {
                            self.selectReceiverDelegate.setReceiver(proxy)
                            self.close()
                        } else {
                            self.showAlert("Receiver Not Found", message: "Please try again.")
                        }
                    })
                }
            }
            
            self.view.addSubview(ramReel.view)
            ramReel.view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        })
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        navigationItem.hidesBackButton = true
        tabBarController?.tabBar.hidden = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        tabBarController?.tabBar.hidden = false
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardFrame = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            self.bottomConstraint.constant = keyboardFrame.size.height + 5
        })
    }
    
    func keyboardWillHide(notification: NSNotification) {
        bottomConstraint.constant = 5
    }
    
    func close() {
        navigationController?.popViewControllerAnimated(true)
    }
}
