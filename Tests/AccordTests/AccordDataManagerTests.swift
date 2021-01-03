import XCTest
@testable import Accord
import RxSwift
import RxBlocking

final class AccordDataManagerTests: XCTestCase {
  
  private var disposeBag = DisposeBag()
  
  override func tearDown() {
    disposeBag = DisposeBag()
  }
  
  func testInit() {
    // GIVEN
    let scheduler = StaticRunnablesMock()
    let calculator = ChangeCalculatorMock()
    let retryPolicyEvaluator = RetryPolicyEvaluatorMock()
    
    // WHEN
    let dataManager = AccordDataManager(scheduler: scheduler, changeCalculator: calculator, retryPolicyEvaluator: retryPolicyEvaluator)
    
    // THEN
    XCTAssertNotNil(dataManager.scheduler)
  }
  
  func testRegisterEntities() {
    // GIVEN
    let scheduler = StaticRunnablesMock()
    let calculator = ChangeCalculatorMock()
    let retryPolicyEvaluator = RetryPolicyEvaluatorMock()
    let entity = EntityMock(dataStorage: LocalStorageMock(), remoteProvider: RemoteProviderMock())
    let dataManager = AccordDataManager(scheduler: scheduler, changeCalculator: calculator, retryPolicyEvaluator: retryPolicyEvaluator)
    
    // WHEN
    _ = try! dataManager.register(entity: entity, for: ContentMock.self).toBlocking().first()
    
    // THEN
    XCTAssertEqual(1, dataManager.entities.count)
  }
  
  func testObserveObjectsAddingInLocalStorage() {
    // GIVEN
    let scheduler = StaticRunnablesMock()
    let calculator = ChangeCalculatorMock()
    let retryPolicyEvaluator = RetryPolicyEvaluatorMock()
    let localStorage = LocalStorageMock()
    let remoteProvider = RemoteProviderMock()
    let entity = EntityMock(dataStorage: localStorage, remoteProvider: remoteProvider)
    let dataManager = AccordDataManager(scheduler: scheduler, changeCalculator: calculator, retryPolicyEvaluator: retryPolicyEvaluator)
    
    let expectation = XCTestExpectation(description: "New Objects")
    
    let newObjectId = "newObjectId"
    let newObject = ContentMock(id: newObjectId, stringProperty: "", intProperty: 0, boolProperty: false)
    
    // WHEN
    _ = try! dataManager.register(entity: entity, for: ContentMock.self).toBlocking().first()
    
    dataManager.observeObjects(forContentType: ContentMock.self, inEntity: .init(id: EntityMock.identifier))
      .filter { $0.contains(where: { $0.id == newObjectId }) }
      .subscribe(onNext: { objects in
        expectation.fulfill()
      })
      .disposed(by: disposeBag)
    
    localStorage.perform(action: .insert, withContent: newObject)
      .subscribe()
      .disposed(by: disposeBag)
    
    // THEN
    wait(for: [expectation], timeout: 1)
  }
  
//  func testObserveObjectsAddingInRemoteProvider() {
//    // GIVEN
//    let scheduler = StaticRunnablesMock()
//    let calculator = ChangeCalculatorMock()
//    let localStorage = LocalStorageMock()
//    let remoteProvider = RemoteProviderMock()
//    let entity = EntityMock(dataStorage: localStorage, remoteProvider: remoteProvider)
//    let dataManager = AccordDataManager(scheduler: scheduler, changeCalculator: calculator)
//
//    let expectation = XCTestExpectation(description: "New Objects")
//
//    let newObjectId = "newObjectId"
//    let newObject = ContentMock(id: newObjectId, stringProperty: "", intProperty: 0, boolProperty: false)
//
//    // WHEN
//    dataManager.register(entity: entity)
//
//    dataManager.observeObjects(forContentType: ContentMock.self, inEntity: .init(id: EntityMock.identifier))
//      .filter { $0.contains(where: { $0.id == newObjectId }) }
//      .subscribe(onNext: { objects in
//        expectation.fulfill()
//      })
//      .disposed(by: disposeBag)
//
//    remoteProvider.inject(content: newObject)
//
//    // THEN
//    wait(for: [expectation], timeout: 1)
//  }
  
  func testAdd() {
    // GIVEN
    let scheduler = StaticRunnablesMock()
    let calculator = ChangeCalculatorMock()
    let retryPolicyEvaluator = RetryPolicyEvaluatorMock()
    let localStorage = LocalStorageMock()
    let remoteProvider = RemoteProviderMock()
    let entity = EntityMock(dataStorage: localStorage, remoteProvider: remoteProvider)
    let dataManager = AccordDataManager(scheduler: scheduler, changeCalculator: calculator, retryPolicyEvaluator: retryPolicyEvaluator)
    
    let expectation = XCTestExpectation(description: "Insert New Object")
    
    let newObjectId = "newObjectId"
    let newObject = ContentMock(id: newObjectId, stringProperty: "", intProperty: 0, boolProperty: false)
    
    // WHEN
    _ = try! dataManager.register(entity: entity, for: ContentMock.self).toBlocking().first()
    
    dataManager.add(object: newObject, toEntity: .init(id: EntityMock.identifier))
      .subscribe(fulfilling: expectation)
      .disposed(by: disposeBag)
    
    // THEN
    wait(for: [expectation], timeout: 1)
    XCTAssert(localStorage.currentContent().contains(where: { $0.id == newObjectId }))
    XCTAssertEqual(1, scheduler.runnables.count)
  }
  
  func testUpdate() {
    // GIVEN
    let scheduler = StaticRunnablesMock()
    let calculator = ChangeCalculatorMock()
    let retryPolicyEvaluator = RetryPolicyEvaluatorMock()
    let localStorage = LocalStorageMock()
    let remoteProvider = RemoteProviderMock()
    let entity = EntityMock(dataStorage: localStorage, remoteProvider: remoteProvider)
    let dataManager = AccordDataManager(scheduler: scheduler, changeCalculator: calculator, retryPolicyEvaluator: retryPolicyEvaluator)
    
    let expectationInsert = XCTestExpectation(description: "Insert New Object")
    let expectationUpdate = XCTestExpectation(description: "Update Object")
    
    let newObjectId = "newObjectId"
    let newObject = ContentMock(id: newObjectId, stringProperty: "", intProperty: 0, boolProperty: false)
    
    let updatedObject = ContentMock(id: newObjectId, stringProperty: "", intProperty: 1, boolProperty: true)
    
    // WHEN
    _ = try! dataManager.register(entity: entity, for: ContentMock.self).toBlocking().first()
    
    dataManager.add(object: newObject, toEntity: .init(id: EntityMock.identifier))
      .subscribe(fulfilling: expectationInsert)
      .disposed(by: disposeBag)
    
    dataManager.update(object: updatedObject, inEntity: .init(id: EntityMock.identifier))
      .subscribe(fulfilling: expectationUpdate)
      .disposed(by: disposeBag)
    
    // THEN
    wait(for: [expectationInsert, expectationUpdate], timeout: 1)
    XCTAssert(localStorage.currentContent().contains(where: { $0.id == newObjectId }))
    XCTAssertEqual(2, scheduler.runnables.count)
  }
  
  func testRemove() {
    // GIVEN
    let scheduler = StaticRunnablesMock()
    let calculator = ChangeCalculatorMock()
    let retryPolicyEvaluator = RetryPolicyEvaluatorMock()
    let localStorage = LocalStorageMock()
    let remoteProvider = RemoteProviderMock()
    let entity = EntityMock(dataStorage: localStorage, remoteProvider: remoteProvider)
    let dataManager = AccordDataManager(scheduler: scheduler, changeCalculator: calculator, retryPolicyEvaluator: retryPolicyEvaluator)
    
    let expectationInsert = XCTestExpectation(description: "Insert New Object")
    let expectationRemove = XCTestExpectation(description: "Delete Object")
    
    let newObjectId = "newObjectId"
    let newObject = ContentMock(id: newObjectId, stringProperty: "", intProperty: 0, boolProperty: false)
    
    // WHEN
    _ = try! dataManager.register(entity: entity, for: ContentMock.self).toBlocking().first()
    
    dataManager.add(object: newObject, toEntity: .init(id: EntityMock.identifier))
      .subscribe(fulfilling: expectationInsert)
      .disposed(by: disposeBag)
    
    dataManager.remove(object: newObject, fromEntity: .init(id: EntityMock.identifier))
      .subscribe(fulfilling: expectationRemove)
      .disposed(by: disposeBag)
    
    // THEN
    wait(for: [expectationInsert, expectationRemove], timeout: 1)
    XCTAssertFalse(localStorage.currentContent().contains(where: { $0.id == newObjectId }))
    XCTAssertEqual(2, scheduler.runnables.count)
  }

//    static var allTests = [
////        ("testExample", testExample),
//    ]
}

private extension Completable {
  func subscribe(fulfilling expectation: XCTestExpectation) -> Disposable {
    subscribe(onCompleted: { expectation.fulfill() })
  }
}
