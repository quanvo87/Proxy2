import FirebaseDatabase

class SenderIconObserver: ReferenceObserving {
    var handle: DatabaseHandle?
    var ref: DatabaseReference?

    func observe(convo: Convo, manager: SenderIconManaging) {
        stopObserving()
        ref = DB.makeReference(Child.proxies, convo.senderId, convo.senderProxyKey, Child.icon)
        handle = ref?.observe(.value, with: { [weak manager = manager] (data) in
            guard let icon = data.value as? String else { return }
            manager?.senderIcon = icon
        })
    }

    deinit {
        stopObserving()
    }
}
