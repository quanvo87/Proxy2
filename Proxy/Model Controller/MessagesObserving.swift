import FirebaseDatabase
import FirebaseHelper
import MessageKit

protocol MessagesObserving: ReferenceObserving {
    init(querySize: UInt)
    func observe(convoKey: String, completion: @escaping ([Message]) -> Void)
    func loadMessages(endingAtMessageId id: String, completion: @escaping ([Message]) -> Void)
}

class MessagesObserver: MessagesObserving {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?
    private let querySize: UInt
    private var loading = true

    required init(querySize: UInt = Setting.querySize) {
        self.querySize = querySize
    }

    func observe(convoKey: String, completion: @escaping ([Message]) -> Void) {
        stopObserving()
        ref = try? FirebaseHelper.main.makeReference(Child.messages, convoKey)
        handle = ref?
            .queryLimited(toLast: querySize)
            .queryOrdered(byChild: Child.timestamp)
            .observe(.value) { [weak self] data in
                self?.loading = true
                completion(data.toMessagesArray)
                self?.loading = false
        }
    }

    func loadMessages(endingAtMessageId id: String, completion: @escaping ([Message]) -> Void) {
        guard !loading else {
            return
        }
        loading = true
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        ref?.queryEnding(atValue: id)
            .queryLimited(toLast: querySize)
            .queryOrderedByKey()
            .observeSingleEvent(of: .value) { [weak self] data in
                DispatchQueue.main.async {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                }
                var messages = data.toMessagesArray
                guard messages.count > 1 else {
                    return
                }
                messages.removeLast(1)
                completion(messages)
                self?.loading = false
        }
    }

    deinit {
        stopObserving()
    }
}
