import UIKit

protocol StoryboardMakable {
    static var identifier: String { get }
}

extension StoryboardMakable {
    static func make() -> Self? {
        guard let controller = UIStoryboard.storyboard.instantiateViewController(withIdentifier: identifier) as? Self else {
            return nil
        }
        return controller
    }
}
