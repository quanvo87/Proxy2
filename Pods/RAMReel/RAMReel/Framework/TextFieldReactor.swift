//
//  RAMReel.swift
//  RAMReel
//
//  Created by Mikhail Stepkin on 4/2/15.
//  Copyright (c) 2015 Ramotion. All rights reserved.
//

import Foundation
import UIKit

// MARK: -  Text field reactor operators

infix operator <&> { precedence 175 }

/**
 Links text field to data flow
 
 - parameters:
    - left: Text field.
    - right: `DataFlow` object.
 
 - returns: `TextFieldReactor` object
 */
public func <&>
    <
    DS: FlowDataSource,
    DD: FlowDataDestination
    where
    DS.ResultType == DD.DataType,
    DS.QueryType  == String
    >
    (left: UITextField, right: DataFlow<DS, DD>) -> TextFieldReactor<DS, DD>
{
    return TextFieldReactor(textField: left, dataFlow: right)
}

// MARK: - Text field reactor

/**
 TextFieldReactor
 --
 
 Implements reactive handling text field editing and passes editing changes to data flow
 */
public struct TextFieldReactor
    <
    DS: FlowDataSource,
    DD: FlowDataDestination
    where
    DS.ResultType == DD.DataType,
    DS.QueryType  == String
    >
{
    let textField : UITextField
    let dataFlow  : DataFlow<DS, DD>
    
    private let editingTarget: TextFieldTarget
    
    private init(textField: UITextField, dataFlow: DataFlow<DS, DD>) {
        self.textField = textField
        self.dataFlow  = dataFlow
        
        self.editingTarget = TextFieldTarget(controlEvents: UIControlEvents.EditingChanged, textField: textField) {
            if let text = $0.text {
                dataFlow.transport(text)
            }
        }
    }
    
}

final class TextFieldTarget: NSObject {
    
    static let actionSelector = #selector(TextFieldTarget.action(_:))
    
    typealias HookType = (UITextField) -> ()
    
    override init() {
        super.init()
    }
    
    init(controlEvents:UIControlEvents, textField: UITextField, hook: HookType) {
        super.init()
        
        self.beTargetFor(textField, controlEvents: controlEvents, hook: hook)
    }
    
    var hooks: [UITextField: HookType] = [:]
    func beTargetFor(textField: UITextField, controlEvents:UIControlEvents, hook: HookType) {
        textField.addTarget(self, action: TextFieldTarget.actionSelector, forControlEvents: controlEvents)
        hooks[textField] = hook
    }
    
    deinit {
        for (textField, _) in hooks {
            textField.removeTarget(self, action: TextFieldTarget.actionSelector, forControlEvents: UIControlEvents.AllEvents)
        }
    }
    
    func action(textField: UITextField) {
        let hook = hooks[textField]
        hook?(textField)
    }
    
}
