//
//  File.swift
//  
//
//  Created by Alessio Moiso on 06.12.20.
//

import RxSwift

public protocol SchedulerStorageType {
  
  func flushAll() -> Single<[Runnable]>
  
  func append(runnable: Runnable) throws
  
  func remove(runnable: Runnable) throws
  
}
