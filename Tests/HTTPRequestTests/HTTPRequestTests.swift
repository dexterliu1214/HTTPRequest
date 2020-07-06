import XCTest
@testable import HTTPRequest

final class HTTPRequestTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(HTTPRequest().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
