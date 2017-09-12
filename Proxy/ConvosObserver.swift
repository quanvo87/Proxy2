import FirebaseDatabase
import UIKit

class ConvosObserver: ReferenceObserving, TableViewMapTableHandling {
    private(set) var convos = [Convo]()
    private(set) var handle: DatabaseHandle?
    private(set) var ref: DatabaseReference?
    private(set) var tableViews = NSMapTable<AnyObject, AnyObject>(keyOptions: [.weakMemory], valueOptions: [.weakMemory])

    func observeConvos(forOwner owner: String) {
        if let handle = handle {
            ref?.removeObserver(withHandle: handle)
        }

        ref = DB.makeReference(Child.convos, owner)

        handle = ref?.queryOrdered(byChild: Child.timestamp).observe(.value, with: { [weak self] (data) in
            self?.convos = data.toConvosArray(filtered: true).reversed()
            self?.reloadTableViews()
        })
    }

    deinit {
        if let handle = handle {
            ref?.removeObserver(withHandle: handle)
        }
    }
}
