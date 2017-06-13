//
//  UnreadManager.swift
//  proxy
//
//  Created by Quan Vo on 6/8/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import FirebaseDatabase

class UnreadObserver {
    private var ref: DatabaseReference?

    init() {}

    func observe(_ delegate: UnreadObserverDelegate) {
        ref = DB.ref(Path.Unread, Shared.shared.uid, Path.Unread)
        ref?.observe(.value, with: { [weak delegate = delegate] (snapshot) in
            delegate?.setUnread(snapshot.value as? Int)
        })
    }

    deinit {
        ref?.removeAllObservers()
    }
}

protocol UnreadObserverDelegate: class {
    func setUnread(_ unread: Int?)
}
