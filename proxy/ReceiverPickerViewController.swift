//
//  ReceiverPickerViewController.swift
//  proxy
//
//  Created by Quan Vo on 11/1/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase
import RAMReel

class ReceiverPickerViewController: UIViewController, UICollectionViewDelegate {
    
    @IBOutlet weak var selectThisReceiverButton: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    let api = API.sharedInstance
    var receiverPickerDelegate: ReceiverPickerDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Select Receiver"
        
        let cancelButton = UIButton(type: .Custom)
        cancelButton.addTarget(self, action: #selector(ReceiverPickerViewController.close), forControlEvents: UIControlEvents.TouchUpInside)
        cancelButton.frame = CGRectMake(0, 0, 25, 25)
        cancelButton.setImage(UIImage(named: "cancel"), forState: UIControlState.Normal)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cancelButton)
        
        api.ref.child(Path.Proxies).queryOrderedByChild(Path.Key).observeSingleEventOfType(.Value, withBlock: { snapshot in
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
                guard $0 != "" else { return }
                self.api.getProxy($0, completion: { (proxy) in
                    guard let proxy = proxy else {
                        self.showAlert("Receiver Not Found", message: "Make sure to type the receiver's full name or tap 'Select This Receiver'.")
                        return
                    }
                    guard proxy.ownerId != self.api.uid else {
                        self.showAlert("Cannot Send To Self", message: "Did you select your own proxy by mistake? 😂")
                        return
                    }
                    self.receiverPickerDelegate.setReceiver(proxy)
                    self.close()
                })
            }
            
            self.view.addSubview(ramReel.view)
            ramReel.view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        })
        
        selectThisReceiverButton.layer.borderColor = UIColor().blue().CGColor
        selectThisReceiverButton.layer.borderWidth = 1
        selectThisReceiverButton.layer.cornerRadius = 5
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ReceiverPickerViewController.keyboardWillShow), name: UIKeyboardWillShowNotification, object: self.view.window)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ReceiverPickerViewController.keyboardWillHide), name: UIKeyboardWillHideNotification, object: self.view.window)
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
    
    func close() {
        navigationController?.popViewControllerAnimated(true)
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
}
