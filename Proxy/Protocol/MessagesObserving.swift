import FirebaseDatabase
import MessageKit
import WQNetworkActivityIndicator

protocol MessagesObserving: ReferenceObserving {
    init(querySize: UInt)
    func observe(convoKey: String, completion: @escaping ([Message]) -> Void)
    func loadMessages(endingAtMessageId id: String, completion: @escaping ([Message]) -> Void)
}

class MessagesObserver: MessagesObserving {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?
    private let querySize: UInt
    private var firstCallback = true
    private var loading = true

    required init(querySize: UInt = DatabaseOption.querySize) {
        self.querySize = querySize
    }

    func observe(convoKey: String, completion: @escaping ([Message]) -> Void) {
        stopObserving()
        firstCallback = true
        ref = try? Constant.firebaseHelper.makeReference(Child.messages, convoKey)
        WQNetworkActivityIndicator.shared.show()
        handle = ref?
            .queryLimited(toLast: querySize)
            .queryOrdered(byChild: Child.timestamp)
            .observe(.value) { [weak self] data in
                if let firstCallback = self?.firstCallback, firstCallback {
                    self?.firstCallback = false
                    WQNetworkActivityIndicator.shared.hide()
                }
                self?.loading = true
                completion(data.asMessagesArray)
                self?.loading = false
        }
    }

    func loadMessages(endingAtMessageId id: String, completion: @escaping ([Message]) -> Void) {
        guard !loading else {
            return
        }
        loading = true
        WQNetworkActivityIndicator.shared.show()
        ref?.queryEnding(atValue: id)
            .queryLimited(toLast: querySize)
            .queryOrderedByKey()
            .observeSingleEvent(of: .value) { [weak self] data in
                WQNetworkActivityIndicator.shared.hide()
                var messages = data.asMessagesArray
                guard messages.count > 1 else {
                    completion([])
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
