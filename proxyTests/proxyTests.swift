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

        let iconManager = IconManager.shared

        iconManager.getIconNames { (iconNames) in
            iconManager.getUIImage(forIconName: iconNames[0], completion: { (image) in
                XCTAssertNotNil(image)
                expectation.fulfill()
            })
        }
        
        waitForExpectations(timeout: 10)
    }    
}
