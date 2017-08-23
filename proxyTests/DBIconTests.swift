import XCTest
@testable import proxy

class DBIconTests: DBTest {
    func testGetImageForIcon() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 30) }
        
        DBProxy.loadProxyInfo { (success) in
            XCTAssert(success)
            
            let iconImagesRetrieved = DispatchGroup()
            
            for iconName in Shared.shared.iconNames {
                iconImagesRetrieved.enter()
                
                DBIcon.getImageForIcon(iconName as AnyObject, tag: 0) { (image, _) in
                    XCTAssertEqual(image, Shared.shared.cache.object(forKey: iconName as AnyObject) as? UIImage)
                    iconImagesRetrieved.leave()
                }
            }
            
            iconImagesRetrieved.notify(queue: DispatchQueue.main) {
                expectation.fulfill()
            }
        }
    }
}
