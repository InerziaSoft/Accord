//
//  File.swift
//  
//
//  Created by Alessio Moiso on 07.12.20.
//

import Accord

class StaticRunnablesMock: RunnablesScheduler {
  
  private(set) var runnables = [Runnable]()
  
  func schedule(runnable: Runnable) {
    runnables += [runnable]
  }
  
}
