//
//  NicknameCell.swift
//  proxy
//
//  Created by Quan Vo on 9/1/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase

class NicknameCell: UITableViewCell, UITextFieldDelegate {
    
    let api = API.sharedInstance
    let ref = FIRDatabase.database().reference()
    var nicknameRef = FIRDatabaseReference()
    var nicknameRefHandle = FIRDatabaseHandle()
    var label: UITextField
    let leftMarginForLabel: CGFloat = 15
    
    var proxy = Proxy() {
        didSet {
            observeNickname()
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        label = UITextField(frame: CGRect.null)
        
        super.init(coder: aDecoder)!
        
        label.placeholder = "Tap to edit"
        label.textColor = UIColor().blue()
        label.returnKeyType = .Done
        label.clearButtonMode = .WhileEditing
        label.delegate = self
        addSubview(label)
    }
    
    deinit {
        nicknameRef.removeObserverWithHandle(nicknameRefHandle)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = CGRect(x: leftMarginForLabel, y: 0, width: bounds.size.width - leftMarginForLabel, height: bounds.size.height)
    }
    
    func observeNickname() {
        nicknameRef = ref.child("users").child(api.uid).child("proxies").child(proxy.name).child("nickname")
        nicknameRefHandle = nicknameRef.observeEventType(.Value, withBlock: { snapshot in
            if let nickname = snapshot.value as? String where nickname != "" {
                self.label.text = nickname
            }
        })
    }
    
    // MARK: - Text field
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        api.updateProxyNickname(proxy, nickname: label.text!)
        return true
    }
    
}