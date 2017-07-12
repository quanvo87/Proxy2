//
//  Shared.swift
//  proxy
//
//  Created by Quan Vo on 6/11/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import Firebase

class Shared {
    static let shared = Shared()

    lazy var firebase = FirebaseApp.app()

    lazy var cache = NSCache<AnyObject, AnyObject>()

    lazy var adjectives = [String]()
    lazy var nouns = [String]()
    lazy var iconNames = [String]()

    lazy var workGroups = [String: (group: DispatchGroup, result: Bool)]()

    lazy var uid = ""
    lazy var isCreatingProxy = false

    lazy var workGroup = [String: DispatchGroup]()
    lazy var workResult = [String: Bool]()

    private init() {}
}

extension Shared {
    static func startWorkGroup() -> String {
        let workKey = UUID().uuidString
        Shared.shared.workGroup[workKey] = DispatchGroup()
        Shared.shared.workResult[workKey] = true
        return workKey
    }

    static func finishWorkGroup(workKey: String) {
        Shared.shared.workGroup.removeValue(forKey: workKey)
        Shared.shared.workResult.removeValue(forKey: workKey)
    }

    static func startWork(_ workKey: String) {
        Shared.shared.workGroup[workKey]?.enter()
    }

    static func finishWorkWithResult(_ result: Success, workKey: String) {
        setWorkResult(result, workKey: workKey)
        Shared.shared.workGroup[workKey]?.leave()
    }

    @discardableResult
    static func setWorkResult(_ result: Success, workKey: String) -> Success {
        let result = Shared.shared.workResult[workKey] ?? false && result
        Shared.shared.workResult[workKey] = result
        return result
    }
}
