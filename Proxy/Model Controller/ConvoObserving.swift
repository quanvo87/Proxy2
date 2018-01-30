import FirebaseDatabase
import FirebaseHelper

protocol ConvoObserving: ReferenceObserving {
    func observe(convoKey: String, convoSenderId: String, convoManager: ConvoManaging)
}

class ConvoObserver: ConvoObserving {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?
    private let database = Firebase()

    func observe(convoKey: String, convoSenderId: String, convoManager: ConvoManaging) {
        stopObserving()
        ref = try? FirebaseHelper.main.makeReference(Child.convos, convoSenderId, convoKey)
        handle = ref?.observe(.value) { [weak self, weak convoManager] (data) in
            do {
                convoManager?.convo = try Convo(data)
            } catch {
                self?.database.getConvo(key: convoKey, ownerId: convoSenderId) { (result) in
                    switch result {
                    case .success(let convo):
                        convoManager?.convo = convo
                    case .failure:
                        convoManager?.convo = nil
                    }
                }
            }
        }
    }

    deinit {
        stopObserving()
    }
}
