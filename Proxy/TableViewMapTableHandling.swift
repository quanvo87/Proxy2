import UIKit

protocol TableViewMapTableHandling {
    var tableViews: NSMapTable<AnyObject, AnyObject> { get }
}

extension TableViewMapTableHandling {
    func reloadTableViews() {
        let enumerator = tableViews.objectEnumerator()
        while let tableView = enumerator?.nextObject() as? UITableView {
            tableView.reloadData()
        }
    }
}
