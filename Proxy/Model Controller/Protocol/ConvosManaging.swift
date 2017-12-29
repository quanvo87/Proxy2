import UIKit

protocol ConvosManaging: class {
    var convos: [Convo] { get set }
    var tableView: UITableView? { get }
}
