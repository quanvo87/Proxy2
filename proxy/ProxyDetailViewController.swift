//
//  ProxyDetailViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/27/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase

class ProxyDetailViewController: UIViewController, UITextFieldDelegate {
    
    private let api = API.sharedInstance
    private let ref = FIRDatabase.database().reference()
    private var nicknameRef = FIRDatabaseReference()
    private var nicknameRefHandle = FIRDatabaseHandle()
    private var key = ""
    var proxy = [String: AnyObject]()
    
    @IBOutlet weak var proxyNicknameLabel: UILabel!
    @IBOutlet weak var newProxyNicknameTextField: UITextField!
    @IBOutlet weak var editProxyNicknameButton: UIButton!
    @IBOutlet weak var saveNicknameButton: UIButton!
    @IBOutlet weak var proxyDetailTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpUI()
        setProxyData()
        setUpTableView()
        setUpDatabase()
    }
    
    deinit {
        nicknameRef.removeObserverWithHandle(nicknameRefHandle)
    }
    
    func setUpUI() {
        if let name = proxy["name"] {
            navigationItem.title = name as? String
        }
        newProxyNicknameTextField.delegate = self
        newProxyNicknameTextField.clearButtonMode = .WhileEditing
        newProxyNicknameTextField.returnKeyType = .Done
    }
    
    func setProxyData() {
        if let _key = proxy["key"] {
            key = _key as! String
        }
    }
    
    func setUpTableView() {
        automaticallyAdjustsScrollViewInsets = false
        //        proxyDetailTableView.delegate = self
        //        proxyDetailTableView.dataSource = self
        proxyDetailTableView.rowHeight = UITableViewAutomaticDimension
        proxyDetailTableView.estimatedRowHeight = 80
    }
    
    func setUpDatabase() {
        nicknameRef = ref.child("users").child(api.uid).child("proxies").child(key).child("nickname")
        nicknameRefHandle = nicknameRef.observeEventType(.Value, withBlock: { snapshot in
            if let nickname = snapshot.value {
                self.proxyNicknameLabel.text = nickname as? String
            } else {
                self.proxyNicknameLabel.text = ""
            }
        })
    }
    
    @IBAction func tapEditProxyNicknameButton(sender: AnyObject) {
        proxyNicknameLabel.hidden = true
        newProxyNicknameTextField.hidden = false
        newProxyNicknameTextField.text = proxyNicknameLabel.text
        newProxyNicknameTextField.becomeFirstResponder()
        editProxyNicknameButton.hidden = true
        saveNicknameButton.hidden = false
    }
    
    func saveNickname() {
        endEditingNickname()
        api.updateNicknameForProxyWithKey(key, nickname: newProxyNicknameTextField.text!)
    }
    
    func endEditingNickname() {
        proxyNicknameLabel.hidden = false
        newProxyNicknameTextField.hidden = true
        editProxyNicknameButton.hidden = false
        saveNicknameButton.hidden = true
    }
    
    @IBAction func tapSaveNicknameButton(sender: AnyObject) {
        self.view.endEditing(true)
        saveNickname()
    }
    
    // MARK: - Keyboard
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        saveNickname()
        return true
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
        endEditingNickname()
    }
}