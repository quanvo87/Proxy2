import UIKit

protocol TableViewMapTableHandling {
    var tableViews: NSMapTable<AnyObject, AnyObject> { get }
    func addTableView(_ tableView: UITableView, forKey key: Int)
    func reloadTableViews()
    func removeTableView(forKey key: Int)
}

extension TableViewMapTableHandling {
    func addTableView(_ tableView: UITableView, forKey key: Int) {
        tableViews.setObject(tableView, forKey: key as AnyObject)
    }

    func reloadTableViews() {
        let enumerator = tableViews.objectEnumerator()

        while let tableView = enumerator?.nextObject() as? UITableView {
            tableView.reloadData()
        }
    }

    func removeTableView(forKey key: Int) {
        tableViews.removeObject(forKey: key as AnyObject)
    }
}
