import FirebaseDatabase
import UIKit

class ProxiesObserver: ReferenceObserving, TableViewMapTableHandling {
    private(set) var handle: DatabaseHandle?
    private(set) var proxies = [Proxy]()
    private(set) var ref: DatabaseReference?
    private(set) var tableViews = NSMapTable<AnyObject, AnyObject>(keyOptions: [.weakMemory], valueOptions: [.weakMemory])

    func observe() {
        if let handle = handle {
            ref?.removeObserver(withHandle: handle)
        }
        
        ref = DB.makeReference(Child.proxies, Shared.shared.uid)

        handle = ref?.queryOrdered(byChild: Child.timestamp).observe(.value, with: { [weak self] (data) in
            self?.proxies = data.toProxiesArray().reversed()
            self?.reloadTableViews()
        })
    }

    deinit {
        if let handle = handle {
            ref?.removeObserver(withHandle: handle)
        }
    }
}
