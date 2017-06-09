//
//  ConvosManager.swift
//  proxy
//
//  Created by Quan Vo on 6/8/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import FirebaseDatabase

class ConvosObserver {
    private var ref = DatabaseReference()
    private var handle = DatabaseHandle()
    var convos = [Convo]()

    init() {}

    deinit {
        ref.removeObserver(withHandle: handle)
    }

    func observe(_ delegate: MessagesTableViewDataSource) {
        ref = Database.database().reference().child(Path.Convos).child(UserManager.shared.uid)
        handle = ref.queryOrdered(byChild: Path.Timestamp).observe(.value, with: { [weak self, weak delegate = delegate] (snapshot) in
            self?.convos = ConvosObserver.getConvos(from: snapshot)
            delegate?.tableViewController?.tableView.reloadData()
        })
    }
}

private extension ConvosObserver {
    static func getConvos(from snapshot: DataSnapshot) -> [Convo] {
        var convos = [Convo]()
        for child in snapshot.children {
            if  let data = child as? DataSnapshot,
                let convo = Convo(anyObject: data.value as AnyObject),
                !convo.senderLeftConvo && !convo.senderIsBlocking {
                convos.append(convo)
            }
        }
        return convos.reversed()
    }
}
