//
//  proxyTests.swift
//  proxyTests
//
//  Created by Quan Vo on 6/6/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import XCTest
@testable import proxy

class proxyTests: XCTestCase {
    func test() {
        let expectation = self.expectation(description: #function)

        let iconManager = IconManager.singleton

        iconManager.getIconNames { (iconNames) in
            print(iconNames)
            iconManager.getUIImage(forIconName: iconNames[0], completion: { (image) in
                print(image as Any)
                expectation.fulfill()
            })
        }
        
        waitForExpectations(timeout: 10)
    }    
}
