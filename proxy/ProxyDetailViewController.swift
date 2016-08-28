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
    var proxy = Proxy()
    
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var nicknameTextField: UITextField!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = proxy.name
        
        setUpTextField()
        setUpTableView()
        setUpDatabase()
    }
    
    deinit {
        nicknameRef.removeObserverWithHandle(nicknameRefHandle)
    }
    
    func setUpDatabase() {
        nicknameRef = ref.child("users").child(api.uid).child("proxies").child(proxy.name).child("nickname")
        nicknameRefHandle = nicknameRef.observeEventType(.Value, withBlock: { snapshot in
            if let nickname = snapshot.value {
                self.nicknameLabel.text = nickname as? String
            } else {
                self.nicknameLabel.text = ""
            }
        })
    }
    
    @IBAction func tapEditButton(sender: AnyObject) {
        nicknameLabel.hidden = true
        nicknameTextField.hidden = false
        nicknameTextField.text = nicknameLabel.text
        nicknameTextField.becomeFirstResponder()
        editButton.hidden = true
        saveButton.hidden = false
    }
    
    @IBAction func tapSaveButton(sender: AnyObject) {
        self.view.endEditing(true)
        saveNickname()
    }
    
    func saveNickname() {
        endEditingNickname()
        api.updateProxyNickname(proxy, nickname: nicknameTextField.text!)
    }
    
    func endEditingNickname() {
        nicknameLabel.hidden = false
        nicknameTextField.hidden = true
        editButton.hidden = false
        saveButton.hidden = true
    }
    
    // MARK: - Table view data source
    
    func setUpTableView() {
        automaticallyAdjustsScrollViewInsets = false
        //        proxyDetailTableView.delegate = self
        //        proxyDetailTableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 80
    }
    
    // MARK: - Text field
    
    func setUpTextField() {
        nicknameTextField.delegate = self
        nicknameTextField.clearButtonMode = .WhileEditing
        nicknameTextField.returnKeyType = .Done
    }
    
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