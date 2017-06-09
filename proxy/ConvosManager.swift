//
//  ConvosManager.swift
//  proxy
//
//  Created by Quan Vo on 6/8/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import FirebaseDatabase

class ConvosManager {
    weak var dataSource: MessagesTableViewDataSource?
    private var ref = DatabaseReference()
    private var handle = DatabaseHandle()
    var convos = [Convo]()

    init() {
        ref = Database.database().reference().child(Path.Convos).child(UserManager.shared.uid)
        handle = ref.queryOrdered(byChild: Path.Timestamp).observe(.value, with: { (snapshot) in
            self.convos = ConvosManager.getConvos(from: snapshot)
            self.dataSource?.tableViewController?.tableView.reloadData()
        })
    }

    deinit {
        ref.removeObserver(withHandle: handle)
    }
}

private extension ConvosManager {
    static func getConvos(from snapshot: DataSnapshot) -> [Convo] {
        var convos = [Convo]()
        for child in snapshot.children {
            if  let child = child as? DataSnapshot,
                let convo = Convo(anyObject: child.value as AnyObject),
                !convo.senderLeftConvo && !convo.senderIsBlocking {
                convos.append(convo)
            }
        }
        return convos.reversed()
    }
}
