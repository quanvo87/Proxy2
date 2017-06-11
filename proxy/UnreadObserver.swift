//
//  UnreadManager.swift
//  proxy
//
//  Created by Quan Vo on 6/8/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import FirebaseDatabase

class UnreadObserver {
    private var ref = DatabaseReference()
    private var handle = DatabaseHandle()

    init() {}

    func observe(_ delegate: UnreadObserverDelegate) {
        ref = Database.database().reference().child(Path.Unread).child(DataManager.shared.uid).child(Path.Unread)
        handle = ref.observe(.value, with: { [weak delegate = delegate] (snapshot) in
            delegate?.setUnread(snapshot.value as? Int)
        })
    }

    deinit {
        ref.removeObserver(withHandle: handle)
    }
}

protocol UnreadObserverDelegate: class {
    func setUnread(_ unread: Int?)
}
