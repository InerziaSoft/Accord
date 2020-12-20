//
//  File.swift
//  
//
//  Created by Alessio Moiso on 20.12.20.
//

import Accord
import XCTest

class RetryPolicyEvaluatorMock: RetryPolicyEvaluator {
  
  var nextPolicy = RetryPolicy.giveUp
  var evaluateExpectation: XCTestExpectation?
  
  func evaluate(error: Error, attempt: Int) -> RetryPolicy {
    evaluateExpectation?.fulfill()
    return nextPolicy
  }
  
}
