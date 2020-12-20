//
//  File.swift
//  
//
//  Created by Alessio Moiso on 20.12.20.
//

import Accord
import RxSwift
import XCTest

class SchedulerStorageMock: SchedulerStorageType {
  
  private(set) var runnables = [Runnable]()
  
  var appendExpectation: XCTestExpectation?
  var removeExpectation: XCTestExpectation?
  
  func inject(runnables: [Runnable]) {
    self.runnables = runnables
  }
  
  func flushAll() -> Single<[Runnable]> {
    .just(runnables)
  }
  
  func append(runnable: Runnable) throws {
    runnables += [runnable]
    appendExpectation?.fulfill()
  }
  
  func remove(runnable: Runnable) throws {
    runnables.removeAll(where: { $0.id == runnable.id })
    removeExpectation?.fulfill()
  }
  
}
