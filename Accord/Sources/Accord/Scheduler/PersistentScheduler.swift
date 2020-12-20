//
//  File.swift
//  
//
//  Created by Alessio Moiso on 06.12.20.
//

import Foundation
import RxSwift
import RxRelay

/// A persistent scheduler is an object responsible of running
/// `Runnable` instances following a set of rules.
///
/// Scheduling a `Runnable` on the scheduler will not instantly run it,
/// as the scheduler will wait for the next available window. An execution window is determined
/// by either a time or count limit, that can be specified through a `Configuration` instance.
///
/// A persistent scheduler is also able to store the actions that have been scheduled with it,
/// by means of a `SchedulerStorageType` instance. The scheduler will try to run
/// as much `Runnables` as possible while it's alive. To avoid losing operations, as soon as a new
/// `Runnable` is scheduled, it is also sent to the storage to be saved for later. If there's enough time
/// to execute it, it'll be removed from the storage, otherwise it'll be restored the next session.
///
/// Because of this, immediately after initialization, the scheduler will try to perform all the `Runnables`
/// that have been saved in the storage, always following the same time/count limits.
///
/// `Runnable` instances can also throw errors: if this happen, the scheduler will ask the instance
/// of `RetryPolicyEvaluator` to provide the behavior to follow. `Runnable`s that have failed
/// are not removed from the storage until they succeed or they are cancelled by the `RetryPolicyEvaluator`
/// instance.
public class PersistentScheduler: RunnablesScheduler {
  
  /// Describe the configuration of a `PersistentScheduler`.
  struct Configuration {
    /// Get the maximum number of runnables that
    /// can run at the same time.
    ///
    /// The persistent scheduler will wait for other runnables
    /// until this count is reached.
    let maxConcurrentRunnables: Int
    /// Get the amount of time that should be waited before
    /// executing a newly scheduled runnable.
    ///
    /// The persistent scheduler will wait for other runnables
    /// for this time interval.
    let bufferPeriod: RxTimeInterval
  }
  
  /// Get the queue reserved for this scheduler.
  private let queue = DispatchQueue(label: Constants.schedulerQueueName)
  /// Get the Rx queue reserved for this scheduler.
  private lazy var scheduler = SerialDispatchQueueScheduler(queue: queue, internalSerialQueueName: Constants.scheduleRxQueueName)
  
  /// Get the runnables publish subject.
  private let runnables = PublishSubject<Runnable>()
  
  /// Get the runnables storage.
  let storage: SchedulerStorageType
  /// Get the retry policy evaluator.
  let retryPolicy: RetryPolicyEvaluator
  
  /// Get the dispose bag.
  private let disposeBag = DisposeBag()
  
  /// Get the configuration.
  let configuration: Configuration
  
  /// Initialize a new scheduler.
  ///
  /// - parameters:
  ///   - configuration: The scheduler configuration.
  ///   - storage: The runnables storage.
  ///   - retryPolicy: The retry policy evaluator for runnables.
  init(configuration: Configuration, storage: SchedulerStorageType, retryPolicy: RetryPolicyEvaluator) {
    self.configuration = configuration
    self.storage = storage
    self.retryPolicy = retryPolicy
    
    readFromStorage()
    observeRunnables()
  }
  
  /// Schedule the passed runnable.
  ///
  /// This runnable will not be executed immediately,
  /// but it is guaranteed to be scheduled as soon as
  /// this function returns.
  ///
  /// - parameters:
  ///   - runnable: A runnable.
  public func schedule(runnable: Runnable) {
    queue.sync {
      runnables.onNext(runnable)
    }
  }
  
}

private extension PersistentScheduler {
  /// Get all runnables from the storage.
  func readFromStorage() {
    storage.flushAll()
      .observeOn(scheduler)
      .map { [runnables] in $0.forEach(runnables.onNext) }
      .subscribe()
      .disposed(by: disposeBag)
  }
  
  /// Begin observing incoming runnables.
  func observeRunnables() {
    runnables
      .do(
        onNext: { [storage] in try storage.append(runnable: $0) }
      )
      .buffer(
        timeSpan: configuration.bufferPeriod,
        count: configuration.maxConcurrentRunnables,
        scheduler: scheduler
      )
      .map { [scheduler, storage, retryPolicy] in
        $0.run(onScheduler: scheduler, withStorage: storage, withRetryPolicy: retryPolicy)
      }
      .flatMap(Completable.zip)
      .asCompletable()
      .subscribe()
      .disposed(by: disposeBag)
  }
}

private extension Array where Element == Runnable {
  /// Get all the runnables' completables.
  ///
  /// - parameters:
  ///   - scheduler: The scheduler to use.
  ///   - storage: The runnables storage.
  ///   - retryPolicy: The retry policy evaluator.
  /// - returns: An array of `Completable` where each item represent a runnable.
  func run(onScheduler scheduler: SchedulerType, withStorage storage: SchedulerStorageType, withRetryPolicy retryPolicy: RetryPolicyEvaluator) -> [Completable] {
    map { runnable in
      runnable.run()
        .observeOn(scheduler)
        .retryWhen { (errors: Observable<Error>) in
          errors.enumerated().flatMap { attempt, error -> Observable<Void> in
            retryPolicy.evaluate(error: error, attempt: attempt)
              .toObservable(fromError: error, onScheduler: scheduler)
          }
        }
        .do(
          onError: { _ in try storage.remove(runnable: runnable) },
          onCompleted: { try storage.remove(runnable: runnable) }
        )
    }
  }
}
