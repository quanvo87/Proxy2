import FirebaseDatabase
import MessageKit

protocol MessagesObserving: ReferenceObserving {
    func observe(convoKey: String, completion: @escaping ([Message]) -> Void)
    func loadMessages(endingAtMessageId id: String, completion: @escaping ([Message]) -> Void)
}

class MessagesObserver: MessagesObserving {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?
    private var loading = true

    func observe(convoKey: String, completion: @escaping ([Message]) -> Void) {
        stopObserving()
        ref = try? Shared.firebaseHelper.makeReference(Child.messages, convoKey)
        handle = ref?
            .queryLimited(toLast: DatabaseOption.querySize)
            .queryOrdered(byChild: Child.timestamp)
            .observe(.value) { [weak self] data in
                self?.loading = true
                completion(data.asMessagesArray)
                self?.loading = false
        }
    }

    func loadMessages(endingAtMessageId id: String, completion: @escaping ([Message]) -> Void) {
        guard !loading else {
            completion([])
            return
        }
        loading = true
        var tempHandle: DatabaseHandle?
        tempHandle = ref?.queryEnding(atValue: id)
            .queryLimited(toLast: DatabaseOption.querySize)
            .queryOrderedByKey()
            .observe(.value) { [weak self] data in
                guard let handle = tempHandle, let `self` = self else {
                    return
                }
                defer {
                    self.ref?.removeObserver(withHandle: handle)
                }
                var messages = data.asMessagesArray
                guard messages.count > 1 else {
                    completion([])
                    return
                }
                messages.removeLast(1)
                completion(messages)
                self.loading = false
        }
    }

    deinit {
        stopObserving()
    }
}
