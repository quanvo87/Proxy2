import GroupWork
import XCTest
@testable import Proxy

class DBStorageTests: DBTest {
    func testUploadImage() {
        let expectation = self.expectation(description: #function)
        defer { waitForExpectations(timeout: 30) }

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
