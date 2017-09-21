import FirebaseDatabase
import UIKit

class ReceiverNicknameObserver: ReferenceObserving {
    let ref: DatabaseReference?
    private weak var controller: ConvoMemberNicknamesObserving?
    private(set) var handle: DatabaseHandle?

    init(controller: ConvoMemberNicknamesObserving, convo: Convo) {
        self.controller = controller
        ref = DB.makeReference(Child.convos, convo.senderId, convo.key, Child.receiverNickname)
        observe()
    }

    func observe() {
        stopObserving()
        handle = ref?.observe(.value, with: { [weak self] (data) in
            guard let nickname = data.value as? String else { return }
            self?.controller?.setReceiverNickname(nickname)
        })
    }

    deinit {
        stopObserving()
    }
}

class SenderNicknameObserver: ReferenceObserving {
    let ref: DatabaseReference?
    private weak var controller: ConvoMemberNicknamesObserving?
    private(set) var handle: DatabaseHandle?

    init(controller: ConvoMemberNicknamesObserving, convo: Convo) {
        self.controller = controller
        ref = DB.makeReference(Child.convos, convo.senderId, convo.key, Child.senderNickname)
        observe()
    }

    func observe() {
        stopObserving()
        handle = ref?.observe(.value, with: { [weak self] (data) in
            guard let nickname = data.value as? String else { return }
            self?.controller?.setSenderNickname(nickname)
        })
    }

    deinit {
        stopObserving()
    }
}

protocol ConvoMemberNicknamesObserving: class {
    func setReceiverNickname(_ nickname: String)
    func setSenderNickname(_ nickname: String)
}
