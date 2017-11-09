import UIKit

protocol StoryboardMakable {
    static var identifier: String { get }
}

extension StoryboardMakable {
    static func make() -> Self? {
        guard let controller = UIStoryboard.main.instantiateViewController(withIdentifier: identifier) as? Self else {
            return nil
        }
        return controller
    }
}
