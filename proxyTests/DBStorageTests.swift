import XCTest
@testable import proxy

class DBStorageTests: DBTest {
    func testGetImageForIcon() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 30) }
        
        DBStorage.loadProxyInfo { (success) in
            XCTAssert(success)
            
            let iconImagesRetrieved = DispatchGroup()
            
            for iconName in Shared.shared.iconNames {
                iconImagesRetrieved.enter()
                
                DBStorage.getImageForIcon(iconName, tag: 0) { (result) in
                    XCTAssertEqual(result?.image, Shared.shared.cache.object(forKey: iconName as AnyObject) as? UIImage)
                    iconImagesRetrieved.leave()
                }
            }
            
            iconImagesRetrieved.notify(queue: DispatchQueue.main) {
                expectation.fulfill()
            }
        }
    }

    func testLoadProxyInfo() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        DBStorage.loadProxyInfo { (success) in
            XCTAssert(success)
            XCTAssertFalse(Shared.shared.adjectives.isEmpty)
            XCTAssertFalse(Shared.shared.nouns.isEmpty)
            XCTAssertFalse(Shared.shared.iconNames.isEmpty)
            expectation.fulfill()
        }
    }
    
    func testUploadImage() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 10) }

        guard let url = URL(string: "https://pre03.deviantart.net/ad3e/th/pre/f/2017/135/e/9/sylvanas_windrunner_by_enshanlee-db9ag0u.jpg") else {
            XCTFail()
            return
        }

        URLSession.shared.dataTask(with: url) { (data, _, _) in
            guard
                let data = data,
                let image = UIImage(data: data) else {
                    XCTFail()
                    return
            }

            let key = UUID().uuidString

            DBStorage.uploadImage(image, withKey: key) { (url) in
                guard let url = url else {
                    XCTFail()
                    return
                }

                XCTAssertNotNil(Shared.shared.cache.object(forKey: url as AnyObject))

                URLSession.shared.dataTask(with: url) { (_, _, error) in
                    XCTAssertNil(error)

                    DBStorage.deleteFile(withKey: key) { (success) in
                        XCTAssert(success)

                        expectation.fulfill()
                    }
                }.resume()
            }
        }.resume()
    }
}

extension DBStorageTests {
    func testIncrementTags() {
        let cells = [UITableViewCell()]
        cells.incrementTags()
        XCTAssertEqual(cells[0].tag, 1)
    }
}
