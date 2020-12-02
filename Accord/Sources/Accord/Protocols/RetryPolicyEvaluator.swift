//
//  File.swift
//  
//
//  Created by Alessio Moiso on 30.11.20.
//

protocol RetryPolicyEvaluator {
  
  func evaluate(operation: Runnable) -> RetryPolicy
  
}
