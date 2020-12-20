//
//  File.swift
//  
//
//  Created by Alessio Moiso on 30.11.20.
//

import RxSwift

public enum RetryPolicy {
  case retryImmediately,
       retryAfter(RxTimeInterval),
       giveUp
  
  func toObservable(fromError error: Error, onScheduler scheduler: SchedulerType) -> Observable<Void> {
    switch self {
    case .retryImmediately:
      return Observable.just(())
    case let .retryAfter(delay):
      return Observable<Int>.timer(delay, scheduler: scheduler).map { _ in () }
    case .giveUp:
      return Observable.error(error)
    }
  }
}
