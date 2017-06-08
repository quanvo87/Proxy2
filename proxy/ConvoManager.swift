//
//  ConvosManager.swift
//  proxy
//
//  Created by Quan Vo on 6/8/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import FirebaseDatabase

class ConvoManager {
    weak var dataSource: MessagesTableViewDataSource?
    var convosRef = DatabaseReference()
    var convosHandle = DatabaseHandle()
    var convos = [Convo]()

    init() {
        observeConvos()
    }

    deinit {
        convosRef.removeObserver(withHandle: convosHandle)
    }

    func observeConvos() {
        convosRef = API.sharedInstance.ref.child(Path.Convos).child(UserManager.shared.uid)
        convosHandle = convosRef.queryOrdered(byChild: Path.Timestamp).observe(.value, with: { (snapshot) in
            let convos = API.sharedInstance.getConvos(from: snapshot)
            self.convos = convos
            self.dataSource?.tableViewController?.convos = convos
            self.dataSource?.tableViewController?.tableView.reloadData()
        })
    }

}
