//
//  File.swift
//  
//
//  Created by Alessio Moiso on 30.11.20.
//

protocol Scheduler {
  
  func schedule(operation: Runnable)
  
  func operation(withId: String) -> Runnable?
  
  func cancelOperation(withId id: String)
  
}
