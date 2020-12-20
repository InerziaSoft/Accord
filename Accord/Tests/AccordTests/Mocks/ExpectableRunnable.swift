//
//  File.swift
//  
//
//  Created by Alessio Moiso on 20.12.20.
//

import XCTest
import Accord
import RxSwift

struct ExpectableRunnable: Runnable {
  
  var id: String {
    expectation.expectationDescription
  }
  
  let expectation: XCTestExpectation
  
  func run() -> Completable {
    .deferred { [expectation] in
      expectation.fulfill()
      return .empty()
    }
  }
  
  func toRepresentation() -> RunnableRepresentation {
    [:]
  }
  
}
