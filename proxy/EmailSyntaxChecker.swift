//
//  EmailSyntaxChecker.swift
//  proxy
//
//  Created by Quan Vo on 8/20/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import Foundation

class EmailSyntaxChecker {
    func isValidEmail(testStr: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluateWithObject(testStr)
    }
}