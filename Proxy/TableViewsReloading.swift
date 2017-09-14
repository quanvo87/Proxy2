import UIKit

protocol TableViewsReloading {
    var tableViews: NSMapTable<AnyObject, AnyObject> { get }
}

extension TableViewsReloading {
    func reloadTableViews() {
        let enumerator = tableViews.objectEnumerator()
        while let tableView = enumerator?.nextObject() as? UITableView {
            tableView.reloadData()
        }
    }
}
