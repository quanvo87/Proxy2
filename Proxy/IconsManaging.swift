import FirebaseDatabase

typealias IconsManaging = ReceiverIconManaging & SenderIconManaging

class ReceiverIconObserver: ReferenceObserving {
    let ref: DatabaseReference?
    private weak var manager: ReceiverIconManaging?
    private(set) var handle: DatabaseHandle?

    init(convo: Convo, manager: ReceiverIconManaging) {
        self.manager = manager
        ref = DB.makeReference(Child.proxies, convo.receiverId, convo.receiverProxyKey, Child.icon)
        observe()
    }

    func observe() {
        stopObserving()
        handle = ref?.observe(.value, with: { [weak self] (data) in
            guard let icon = data.value as? String else { return }
            self?.manager?.setReceiverIcon(icon)
        })
    }

    deinit {
        stopObserving()
    }
}

class SenderIconObserver: ReferenceObserving {
    let ref: DatabaseReference?
    private weak var manager: SenderIconManaging?
    private(set) var handle: DatabaseHandle?

    init(convo: Convo, manager: SenderIconManaging) {
        self.manager = manager
        ref = DB.makeReference(Child.proxies, convo.senderId, convo.senderProxyKey, Child.icon)
        observe()
    }

    func observe() {
        stopObserving()
        handle = ref?.observe(.value, with: { [weak self] (data) in
            guard let icon = data.value as? String else { return }
            self?.manager?.setSenderIcon(icon)
        })
    }

    deinit {
        stopObserving()
    }
}

protocol ReceiverIconManaging: class {
    func setReceiverIcon(_ icon: String)
}

protocol SenderIconManaging: class {
    func setSenderIcon(_ icon: String)
}
