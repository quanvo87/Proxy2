//
//  NewMessageViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/25/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase

class NewMessageViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    
    @IBOutlet weak var selectProxyButton: UIButton!
    @IBOutlet weak var newButton: NSLayoutConstraint!
    @IBOutlet weak var firstTextField: UITextField!
    @IBOutlet weak var secondTextField: UITextField!
    @IBOutlet weak var numTextField: UITextField!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NewMessageViewController.keyboardWillShow), name:UIKeyboardWillShowNotification, object: self.view.window)
        
        setUpTextField()
        setUpTextView()
    }
    
    override func viewWillAppear(animated: Bool) {
        navigationItem.title = "New Message"
    }
    
    override func viewWillDisappear(animated: Bool) {
        navigationItem.title = ""
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    @IBAction func tapSelectProxy(sender: AnyObject) {
    }
    
    @IBAction func tapNewButton(sender: AnyObject) {
    }
    
    @IBAction func tapSendButton(sender: AnyObject) {
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardFrame = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            self.bottomConstraint.constant = keyboardFrame.size.height
        })
    }
    
    // MARK: - Text field
    
    func setUpTextField() {
        firstTextField.becomeFirstResponder()
        firstTextField.delegate = self
        firstTextField.clearButtonMode = .WhileEditing
        firstTextField.returnKeyType = .Next
        firstTextField.tag = 0
        secondTextField.delegate = self
        secondTextField.clearButtonMode = .WhileEditing
        secondTextField.returnKeyType = .Next
        secondTextField.tag = 1
        numTextField.delegate = self
        numTextField.clearButtonMode = .WhileEditing
        numTextField.returnKeyType = .Next
        numTextField.tag = 2
        numTextField.keyboardType = .NumbersAndPunctuation
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        let nextTag = textField.tag + 1
        if let nextResponder = textField.superview!.viewWithTag(nextTag){
            nextResponder.becomeFirstResponder()
        } else {
            messageTextView.becomeFirstResponder()
        }
        return false
    }
    
    // MARK: - Text view
    
    func setUpTextView() {
        messageTextView.delegate = self
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        if messageTextView.text == "Message..." {
            messageTextView.text = ""
        }
    }
}