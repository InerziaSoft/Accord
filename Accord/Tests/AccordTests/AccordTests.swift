import XCTest
@testable import Accord

final class AccordDataManagerTests: XCTestCase {
  
  func testInit() {
    // GIVEN
    let scheduler = RunnablesSchedulerMock()
    
    // WHEN
    let dataManager = AccordDataManager(scheduler: scheduler)
    
    // THEN
    XCTAssertNotNil(dataManager.scheduler)
  }
  
  func testRegisterEntities() {
    
  }

//    static var allTests = [
////        ("testExample", testExample),
//    ]
}
