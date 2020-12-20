//
//  File.swift
//  
//
//  Created by Alessio Moiso on 20.12.20.
//

import Accord
import RxSwift

class FailingRunnable: Runnable {
  
  enum Errors: Error {
    case failure
  }
  
  var id: String = "failure"
  
  func run() -> Completable {
    .error(Errors.failure)
  }
  
  func toRepresentation() -> RunnableRepresentation {
    [:]
  }
  
}
