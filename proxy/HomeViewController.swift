//
//  HomeViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/14/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import UIKit
import CoreData

class HomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
        
        ProxyAPI.sharedInstance.createProxy("testing", nickname: "123")
    }
    
    func setUp() {
        self.navigationItem.title = "My Proxies"
    }
    
}