//
//  DBIconTests.swift
//  proxy
//
//  Created by Quan Vo on 6/15/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import XCTest
@testable import proxy

class DBIconTests: DBTest {
    func testGetImageForIcon() {
        x = expectation(description: #function)

        DBProxy.loadProxyInfo { (success) in
            XCTAssert(success)

            let iconImagesRetrieved = DispatchGroup()

            for iconName in Shared.shared.iconNames {
                iconImagesRetrieved.enter()

                DBIcon.getImageForIcon(iconName as AnyObject, tag: 0) { (_, _) in
                    XCTAssertNotNil(Shared.shared.cache.object(forKey: iconName as AnyObject) as? UIImage)
                    iconImagesRetrieved.leave()
                }
            }

            iconImagesRetrieved.notify(queue: DispatchQueue.main) {
                self.x.fulfill()
            }
        }
        waitForExpectations(timeout: 30)
    }

    func testCellsIncrementedTags() {
        let cells = [UITableViewCell(), UITableViewCell()]
        cells.incrementedTags
        for cell in cells {
            XCTAssertEqual(cell.tag, 1)
        }
    }
}
