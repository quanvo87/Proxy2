//
//  ConvoViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/30/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

class ConvoViewController: UIViewController {

    var convo = Convo()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = convo.members
    }
}