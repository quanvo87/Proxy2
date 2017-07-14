//
//  ReceiverPickerViewController.swift
//  proxy
//
//  Created by Quan Vo on 11/1/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase
//import RAMReel

class ReceiverPickerViewController: UIViewController, UICollectionViewDelegate {
    
    @IBOutlet weak var selectThisReceiverButton: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    let api = API.sharedInstance
    var receiverPickerDelegate: ReceiverPickerDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Select Receiver"
        
        let cancelButton = UIButton(type: .custom)
        cancelButton.addTarget(self, action: #selector(ReceiverPickerViewController.close), for: UIControlEvents.touchUpInside)
        cancelButton.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        cancelButton.setImage(UIImage(named: "cancel"), for: UIControlState.normal)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cancelButton)
        
        api.ref.child(Path.Proxies).queryOrdered(byChild: Path.Key).observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.hasChildren() else { return }
            let dict = snapshot.children.nextObject() as AnyObject
            var proxies = [String]()
            for child in dict.children {
                if let proxy = Proxy((child as! DataSnapshot).value as AnyObject) {
                    // TODO: - add this when start testing with two phones
                    // , proxy.ownerId != self.api.uid {
                    proxies.append(proxy.key.lowercased())
                }
            }
//            let dataSource = SimplePrefixQueryDataSource(proxies)
//            var ramReel: RAMReel<RAMCell, RAMTextField, SimplePrefixQueryDataSource>!
//            ramReel = RAMReel(frame: self.view.bounds, dataSource: dataSource, placeholder: "Tap to begin typing…") {
//                guard $0 != "" else { return }
//                self.api.getProxy(withKey: $0, completion: { (proxy) in
//                    guard let proxy = proxy else {
//                        self.showAlert("Receiver Not Found", message: "Highlight the receiver then tap 'Select This Receiver'.")
//                        return
//                    }
//                    self.receiverPickerDelegate.setReceiver(to: proxy)
//                    self.close()
//                })
//            }
//            self.view.addSubview(ramReel.view)
//            ramReel.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        })
        
        selectThisReceiverButton.layer.borderColor = UIColor.blue.cgColor
        selectThisReceiverButton.layer.borderWidth = 1
        selectThisReceiverButton.layer.cornerRadius = 5
        
        NotificationCenter.default.addObserver(self, selector: #selector(ReceiverPickerViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: self.view.window)
        NotificationCenter.default.addObserver(self, selector: #selector(ReceiverPickerViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: self.view.window)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        navigationItem.hidesBackButton = true
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        tabBarController?.tabBar.isHidden = false
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func close() {
        _ = navigationController?.popViewController(animated: true)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        let info = notification.userInfo!
        let keyboardFrame = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            self.bottomConstraint.constant = keyboardFrame.size.height + 5
        })
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        bottomConstraint.constant = 5
    }
}
