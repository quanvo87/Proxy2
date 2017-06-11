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
        ref = DB.ref(Path.Convos, DataManager.shared.uid)
        handle = ref.queryOrdered(byChild: Path.Timestamp).observe(.value, with: { [weak self, weak delegate = delegate] (snapshot) in
            self?.convos = snapshot.toConvos().reversed()
            delegate?.tableViewController?.tableView.visibleCells.incrementTags()
            delegate?.tableViewController?.tableView.reloadData()
        })
    }
}
