import FirebaseDatabase

protocol ConvoObserving: ReferenceObserving {
    func observe(convoSenderId: String, convoKey: String, completion: @escaping (Convo?) -> Void)
}

class ConvoObserver: ConvoObserving {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?

    func observe(convoSenderId: String, convoKey: String, completion: @escaping (Convo?) -> Void) {
        stopObserving()
        ref = try? Shared.firebaseHelper.makeReference(Child.convos, convoSenderId, convoKey)
        handle = ref?.observe(.value) { data in
            do {
                completion(try Convo(data))
            } catch {
                Shared.database.getConvo(ownerId: convoSenderId, convoKey: convoKey) { result in
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
