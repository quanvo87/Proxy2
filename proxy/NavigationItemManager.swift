//
//  NavigationItemManager.swift
//  proxy
//
//  Created by Quan Vo on 6/8/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

class NavigationItemManager {
    let newProxyButton: UIBarButtonItem
    let newMessageButton: UIBarButtonItem
    let removeItemsButton: UIBarButtonItem
    let confirmButton: UIBarButtonItem
    let cancelButton: UIBarButtonItem

    init(_ delegate: NavigationItemManagerDelegate) {
        newProxyButton = ButtonFactory.makeNewProxyButton(target: delegate, selector: #selector(delegate.createNewProxy))
        newMessageButton = ButtonFactory.makeNewMessageButton(target: delegate, selector: #selector(delegate.createNewMessage))
        removeItemsButton = ButtonFactory.makeDeleteButton(target: delegate, selector: #selector(delegate.toggleEditMode))
        confirmButton = ButtonFactory.makeConfirmButton(target: delegate, selector: #selector(delegate.removeItems))
        cancelButton = ButtonFactory.makeCancelButton(target: delegate, selector: #selector(delegate.toggleEditMode))
    }
}

@objc protocol NavigationItemManagerDelegate {
    func setDefaultButtons()
    func setEditModeButtons()
    func toggleEditMode()
    func removeItems()
    func createNewProxy()
    func createNewMessage()
}
