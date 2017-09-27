protocol ItemsToDeleteManaging: class {
    var itemsToDelete: [String: Any] { get set }
}

class ItemsToDeleteManager: ItemsToDeleteManaging {
    var itemsToDelete = [String: Any]()
}
