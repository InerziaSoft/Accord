//
//  File.swift
//  
//
//  Created by Alessio Moiso on 30.11.20.
//

public protocol RetryPolicyEvaluator {
  
  func evaluate(error: Error, attempt: Int) -> RetryPolicy
  
}
