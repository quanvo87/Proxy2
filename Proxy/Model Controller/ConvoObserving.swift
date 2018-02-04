import FirebaseDatabase
import FirebaseHelper
import WQNetworkActivityIndicator

protocol ConvoObserving: ReferenceObserving {
    func observe(convoKey: String, convoSenderId: String, completion: @escaping (Convo?) -> Void)
}

class ConvoObserver: ConvoObserving {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?
    private let database = Firebase()
    private var firstCallback = true

    func observe(convoKey: String, convoSenderId: String, completion: @escaping (Convo?) -> Void) {
        stopObserving()
        firstCallback = true
        ref = try? FirebaseHelper.main.makeReference(Child.convos, convoSenderId, convoKey)
        WQNetworkActivityIndicator.shared.show()
        handle = ref?.observe(.value) { [weak self] data in
            if let firstCallback = self?.firstCallback, firstCallback {
                self?.firstCallback = false
                WQNetworkActivityIndicator.shared.hide()
            }
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
