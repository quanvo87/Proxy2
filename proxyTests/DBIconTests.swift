//
//  DBIconTests.swift
//  proxy
//
//  Created by Quan Vo on 6/15/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import XCTest
@testable import proxy
import FirebaseDatabase

class DBIconTests: DBTest {
    func testGetImageForIcon() {
        x = expectation(description: #function)

        DBProxy.loadProxyInfo { (success) in
            XCTAssert(success)

            let group = DispatchGroup()

            for iconName in Shared.shared.iconNames {
                group.enter()

                DBIcon.getImageForIcon(iconName as AnyObject, tag: 0) { (_, _) in
                    group.leave()
                }
            }

            group.notify(queue: DispatchQueue.main) {
                self.x.fulfill()
            }
        }

        waitForExpectations(timeout: 20)
    }

    func testCellsIncrementTags() {
        let cells = [UITableViewCell(), UITableViewCell()]
        cells.incrementedTags
        for cell in cells {
            XCTAssertEqual(cell.tag, 1)
        }
    }
}
