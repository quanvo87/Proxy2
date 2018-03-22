import FirebaseDatabase

protocol ConvoObserving: ReferenceObserving {
    func observe(convoKey: String, convoSenderId: String, completion: @escaping (Convo?) -> Void)
}

class ConvoObserver: ConvoObserving {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?
    private let database = Shared.database

    func observe(convoKey: String, convoSenderId: String, completion: @escaping (Convo?) -> Void) {
        stopObserving()
        ref = try? Shared.firebaseHelper.makeReference(Child.convos, convoSenderId, convoKey)
        handle = ref?.observe(.value) { [weak self] data in
            do {
                completion(try Convo(data))
            } catch {
                self?.database.getConvo(convoKey: convoKey, ownerId: convoSenderId) { result in
                    switch result {
                    case .success(let convo):
                        completion(convo)
                    case .failure:
                        completion(nil)
                    }
                }
            }
        }
    }

    deinit {
        stopObserving()
    }
}
