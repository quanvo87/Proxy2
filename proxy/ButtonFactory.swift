//
//  ButtonFactory.swift
//  proxy
//
//  Created by Quan Vo on 6/8/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

struct ButtonFactory {
    static func makeNewProxyButton(target: Any?, selector: Selector) -> UIBarButtonItem {
        let newProxyButton = UIButton(type: .custom)
        newProxyButton.addTarget(target, action: selector, for: UIControlEvents.touchUpInside)
        newProxyButton.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        newProxyButton.setImage(UIImage(named: "new-proxy.png"), for: UIControlState.normal)
        return UIBarButtonItem(customView: newProxyButton)
    }

    static func makeNewMessageButton(target: Any?, selector: Selector) -> UIBarButtonItem {
        let newMessageButton = UIButton(type: .custom)
        newMessageButton.addTarget(target, action: selector, for: UIControlEvents.touchUpInside)
        newMessageButton.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        newMessageButton.setImage(UIImage(named: "new-message.png"), for: UIControlState.normal)
        return UIBarButtonItem(customView: newMessageButton)
    }

    static func makeDeleteButton(target: Any?, selector: Selector) -> UIBarButtonItem {
        let deleteButton = UIButton(type: .custom)
        deleteButton.addTarget(target, action: selector, for: UIControlEvents.touchUpInside)
        deleteButton.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        deleteButton.setImage(UIImage(named: "delete.png"), for: UIControlState.normal)
        return UIBarButtonItem(customView: deleteButton)
    }

    static func makeConfirmButton(target: Any?, selector: Selector) -> UIBarButtonItem {
        let confirmButton = UIButton(type: .custom)
        confirmButton.addTarget(target, action: selector, for: UIControlEvents.touchUpInside)
        confirmButton.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        confirmButton.setImage(UIImage(named: "confirm"), for: UIControlState.normal)
        return UIBarButtonItem(customView: confirmButton)
    }

    static func makeCancelButton(target: Any?, selector: Selector) -> UIBarButtonItem {
        let cancelButton = UIButton(type: .custom)
        cancelButton.addTarget(target, action: selector, for: UIControlEvents.touchUpInside)
        cancelButton.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        cancelButton.setImage(UIImage(named: "cancel"), for: UIControlState.normal)
        return UIBarButtonItem(customView: cancelButton)
    }
}
