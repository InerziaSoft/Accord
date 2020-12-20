//
//  File.swift
//  
//
//  Created by Alessio Moiso on 20.12.20.
//

import XCTest
@testable import Accord
import RxSwift

class PersistentSchedulerTests: XCTestCase {
  
  func testInit() {
    // GIVEN
    let storage = SchedulerStorageMock()
    let retryPolicy = RetryPolicyEvaluatorMock()
    
    let maxConcurrentRunnables = 3
    let bufferPeriod = RxTimeInterval.seconds(3)
    
    // WHEN
    let scheduler = PersistentScheduler(
      configuration: .init(maxConcurrentRunnables: maxConcurrentRunnables, bufferPeriod: bufferPeriod),
      storage: storage,
      retryPolicy: retryPolicy
    )
    
    // THEN
    XCTAssertEqual(maxConcurrentRunnables, scheduler.configuration.maxConcurrentRunnables)
    XCTAssertEqual(bufferPeriod, scheduler.configuration.bufferPeriod)
  }
  
  func testExecute() {
    // GIVEN
    let storage = SchedulerStorageMock()
    let retryPolicy = RetryPolicyEvaluatorMock()
    
    let maxConcurrentRunnables = 3
    let bufferPeriod = RxTimeInterval.seconds(3)
    
    let scheduler = PersistentScheduler(configuration: .init(maxConcurrentRunnables: maxConcurrentRunnables, bufferPeriod: bufferPeriod), storage: storage, retryPolicy: retryPolicy)
    
    let expectation = XCTestExpectation(description: "Run the Runnable")
    let expectableRunnable = ExpectableRunnable(expectation: expectation)
    
    let removeExpectation = XCTestExpectation(description: "Runnables Removed From Storage")
    storage.removeExpectation = removeExpectation
    
    // WHEN
    scheduler.schedule(runnable: expectableRunnable)
    
    // THEN
    XCTAssertEqual(1, storage.runnables.count)
    wait(for: [expectation, removeExpectation], timeout: 10)
    XCTAssertEqual(0, storage.runnables.count)
  }
  
  func testExecutionFailure() {
    // GIVEN
    let storage = SchedulerStorageMock()
    let retryPolicy = RetryPolicyEvaluatorMock()
    
    let maxConcurrentRunnables = 3
    let bufferPeriod = RxTimeInterval.seconds(3)
    
    let scheduler = PersistentScheduler(configuration: .init(maxConcurrentRunnables: maxConcurrentRunnables, bufferPeriod: bufferPeriod), storage: storage, retryPolicy: retryPolicy)
    
    let failingRunnable = FailingRunnable()
    
    let retryPolicyExpectation = XCTestExpectation(description: "Retry Policy Evaluation Requested")
    retryPolicy.evaluateExpectation = retryPolicyExpectation
    
    // WHEN
    scheduler.schedule(runnable: failingRunnable)
    
    // THEN
    wait(for: [retryPolicyExpectation], timeout: 5)
    XCTAssertEqual(0, storage.runnables.count)
  }
  
}
