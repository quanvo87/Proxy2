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
    
    var proxyAndConvo = (proxy: Proxy(), convos: [Convo]()) {
        didSet {
            observeNickname()
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        label = UITextField(frame: CGRect.null)
        
        super.init(coder: aDecoder)!
        
        let blueAttr = [NSForegroundColorAttributeName: UIColor().blue()]
        let placeholderText = NSAttributedString(string: "Tap to edit", attributes: blueAttr)
        label.attributedPlaceholder = placeholderText
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
        nicknameRef = ref.child("users").child(api.uid).child("proxies").child(proxyAndConvo.proxy.name).child("nickname")
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
        let trim = label.text?.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: " "))
        if label.text != "" && trim == "" {
            label.text = ""
        } else {
            api.updateProxyNickname(proxyAndConvo.proxy, convos: proxyAndConvo.convos, nickname: label.text!)
        }
        return true
    }
}