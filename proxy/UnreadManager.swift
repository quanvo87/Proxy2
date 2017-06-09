//
//  UnreadManager.swift
//  proxy
//
//  Created by Quan Vo on 6/8/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import FirebaseDatabase

class UnreadManager {
    private weak var delegate: UnreadManagerDelegate?
    private var ref = DatabaseReference()
    private var handle = DatabaseHandle()

    init(_ delegate: UnreadManagerDelegate) {
        self.delegate = delegate

        ref = Database.database().reference().child(Path.Unread).child(UserManager.shared.uid).child(Path.Unread)
        handle = ref.observe(.value, with: { (snapshot) in
            self.delegate?.setUnread(snapshot.value as? Int)
        })
    }

    deinit {
        ref.removeObserver(withHandle: handle)
    }
}

protocol UnreadManagerDelegate: class {
    func setUnread(_ unread: Int?)
}
