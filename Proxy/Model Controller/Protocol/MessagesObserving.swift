import FirebaseDatabase
import MessageKit

protocol MessagesObserving: ReferenceObserving {
    func load(convoKey: String,
              querySize: UInt,
              collectionView: MessagesCollectionView?,
              manager: MessagesManaging?)
    func loadMessages(endingAtMessageId id: String,
                      querySize: UInt,
                      collectionView: MessagesCollectionView?,
                      manager: MessagesManaging?)
}

class MessagesObserver: MessagesObserving {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?
    private var loading = true

    func load(convoKey: String,
              querySize: UInt,
              collectionView: MessagesCollectionView?,
              manager: MessagesManaging?) {
        stopObserving()
        ref = FirebaseHelper.makeReference(Child.messages, convoKey)
        handle = ref?
            .queryOrdered(byChild: Child.timestamp)
            .queryLimited(toLast: querySize)
            .observe(.value) { [weak self, weak collectionView, weak manager] (data) in
                self?.loading = true
                manager?.messages = data.asMessagesArray
                collectionView?.reloadData()
                collectionView?.scrollToBottom()
                self?.loading = false
        }
    }

    func loadMessages(endingAtMessageId id: String,
                      querySize: UInt,
                      collectionView: MessagesCollectionView?,
                      manager: MessagesManaging?) {
        guard !loading else {
            return
        }
        loading = true
        ref?.queryOrderedByKey()
            .queryEnding(atValue: id)
            .queryLimited(toLast: querySize)
            .observeSingleEvent(of: .value) { [weak self, weak collectionView, weak manager] (data) in
                var olderMessages = data.asMessagesArray
                guard olderMessages.count > 1 else {
                    return
                }
                olderMessages.removeLast(1)
                let currentMessages = manager?.messages ?? []
                manager?.messages = olderMessages + currentMessages
                collectionView?.reloadDataAndKeepOffset()
                self?.loading = false
        }
    }

    deinit {
        stopObserving()
    }
}
