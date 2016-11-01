//
//  SelectReceiverViewController.swift
//  proxy
//
//  Created by Quan Vo on 11/1/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import RAMReel
import FirebaseDatabase

class SelectReceiverViewController: UIViewController, UICollectionViewDelegate {

    let api = API.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Select Receiver"
        
        FIRDatabase.database().reference().child(Path.Proxies).queryOrderedByChild(Path.Key).observeSingleEventOfType(.Value, withBlock: { snapshot in
            
            var proxies = [String]()
            
            for child in snapshot.children {
                let proxy = Proxy(anyObject: child.value)
                if proxy.key != "" {
                    proxies.append(proxy.key.lowercaseString)
                }
            }
            
            let dataSource = SimplePrefixQueryDataSource(proxies)
            var ramReel: RAMReel<RAMCell, RAMTextField, SimplePrefixQueryDataSource>!
            ramReel = RAMReel(frame: self.view.bounds, dataSource: dataSource, placeholder: "Start by typing…") {
                print("Plain:", $0)
            }
            
            self.view.addSubview(ramReel.view)
            ramReel.view.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        })
    }
}
