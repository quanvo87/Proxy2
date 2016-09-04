//
//  ConvoNicknameCell.swift
//  proxy
//
//  Created by Quan Vo on 9/3/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase

class ConvoNicknameCell: UITableViewCell, UITextFieldDelegate {

    let api = API.sharedInstance
    let ref = FIRDatabase.database().reference()
    var nicknameRef = FIRDatabaseReference()
    var nicknameRefHandle = FIRDatabaseHandle()
    var label: UITextField
    let leftMarginForLabel: CGFloat = 15
    
    var convo = Convo() {
        didSet {
            observeNickname()
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        label = UITextField(frame: CGRect.null)
        
        super.init(coder: aDecoder)!
        
        // Set up the text field and add to view
        let blueAttr = [NSForegroundColorAttributeName: UIColor().blue()]
        let placeholderText = NSAttributedString(string: "Tap to nickname this conversation", attributes: blueAttr)
        label.attributedPlaceholder = placeholderText
        label.textColor = UIColor().blue()
        label.returnKeyType = .Done
        label.clearButtonMode = .WhileEditing
        label.delegate = self
        addSubview(label)
    }
    
    deinit {
        // Stop observing this node on deinit
        nicknameRef.removeObserverWithHandle(nicknameRefHandle)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Makes the text field the size of the cell
        label.frame = CGRect(x: leftMarginForLabel, y: 0, width: bounds.size.width - leftMarginForLabel, height: bounds.size.height)
    }
    
    // When a user enters a new nickname and confirms, it's saved to the
    // database, which is then immediately retrieved by this observer, and then
    // set to the text field's display text
    func observeNickname() {
        nicknameRef = ref.child("users").child(api.uid).child("convos").child(convo.key).child("convoNickname")
        nicknameRefHandle = nicknameRef.observeEventType(.Value, withBlock: { snapshot in
            if let nickname = snapshot.value as? String {
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
        // If the user set this to "", they don't want the convo to have a
        // nickname. But if the user sets it to some blank spaces, we won't
        // allow that and will just give them no nickname.
        let trim = label.text?.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: " "))
        if label.text != "" && trim == "" {
            label.text = ""
        } else {
            api.updateConvoNickname(convo, nickname: label.text!)
        }
        return true
    }
}