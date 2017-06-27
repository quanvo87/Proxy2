//
//  ConvosManager.swift
//  proxy
//
//  Created by Quan Vo on 6/8/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import FirebaseDatabase

class ConvosObserver {
    private var ref: DatabaseReference?
    var convos = [Convo]()

    init() {}

    deinit {
        ref?.removeAllObservers()
    }

    func observe(_ delegate: MessagesTableViewDataSource) {
        ref = DB.ref(DB.Path(Path.Convos, Shared.shared.uid))
        ref?.queryOrdered(byChild: Path.Timestamp).observe(.value, with: { [weak self, weak delegate = delegate] (snapshot) in
            self?.convos = snapshot.toConvos(filtered: true).reversed()
            delegate?.tableViewController?.tableView.visibleCells.incrementedTags
            delegate?.tableViewController?.tableView.reloadData()
        })
    }
}
