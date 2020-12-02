//
//  File.swift
//  
//
//  Created by Alessio Moiso on 02.12.20.
//

import Foundation
import RxSwift

enum AccordDataManagerError: Error {
  case deallocatedInstance
  case unknownEntity
}

class AccordDataManager: DataManagerType {
  
  private lazy var entitiesScheduler = SerialDispatchQueueScheduler(queue: entitiesQueue, internalSerialQueueName: Constants.entitiesRxQueueName)
  private let entitiesQueue = DispatchQueue(label: Constants.entitiesQueueName)
  private var entities = [String: AccordableEntity]()
  
  private let scheduler: Scheduler
  
  init(scheduler: Scheduler) {
    self.scheduler = scheduler
  }
  
  func register<T>(entity: T) where T : AccordableEntity {
    entitiesQueue.sync {
      entities[entity.id] = entity
    }
  }
  
  func add<T>(object: T, toEntity entityDescriptor: AccordableEntityDescriptor) -> Completable where T : AccordableContent {
    entity(forEntityDescriptor: entityDescriptor)
      .flatMapCompletable { [weak self] in self?.operation(onEntity: $0, withContent: object) ?? .error(AccordDataManagerError.deallocatedInstance) }
  }
  
  func update<T>(object: T, inEntity entityDescriptor: AccordableEntityDescriptor) -> Completable where T : AccordableContent {
    entity(forEntityDescriptor: entityDescriptor)
      .flatMapCompletable { [weak self] in self?.operation(onEntity: $0, withContent: object) ?? .error(AccordDataManagerError.deallocatedInstance) }
  }
  
  func remove<T>(object: T, fromEntity entityDescriptor: AccordableEntityDescriptor) -> Completable where T : AccordableContent {
    entity(forEntityDescriptor: entityDescriptor)
      .flatMapCompletable { [weak self] in self?.operation(onEntity: $0, withContent: object) ?? .error(AccordDataManagerError.deallocatedInstance) }
  }
  
  func observeObjects<T>(forContentType accordableContent: T, inEntity entityDescriptor: AccordableEntityDescriptor) -> Observable<[T]> where T : AccordableContent {
    entity(forEntityDescriptor: entityDescriptor)
      .asObservable()
      .flatMap { [weak self] (entity: AccordableEntity) -> Observable<[T]> in
        guard let self = self else { return .empty() }
        return self.observe(entity: entity) as Observable<[T]>
      }
  }
    
}

private extension AccordDataManager {
  func entity(forEntityDescriptor entityDescriptor: AccordableEntityDescriptor) -> Single<AccordableEntity> {
    Single.deferred { [weak self] in
      guard let self = self else { return .error(AccordDataManagerError.deallocatedInstance) }
      if let entity = self.entities[entityDescriptor.id] {
        return .just(entity)
      }
      return .error(AccordDataManagerError.unknownEntity)
    }
    .subscribeOn(entitiesScheduler)
  }
  
  func operation<T: AccordableContent>(onEntity entity: AccordableEntity, withContent object: T) -> Completable {
    Completable.deferred {
      var action = entity.localStorage.performAction(withContent: object, action: .insert)
      
      if let remoteProviderAction = entity.remoteProvider?.performAction(withContent: object, action: .insert) {
        action = action.andThen(remoteProviderAction)
          .do(onSuccess: { [weak self] in self?.scheduler.schedule(operation: $0) })
          .asCompletable()
      }
      
      return action
    }
  }
  
  func observe<T: AccordableContent>(entity: AccordableEntity) -> Observable<[T]> {
    Observable.create { observer in
      let localStorageObservable: Observable<[T]> = entity.localStorage.observeObjects()
      let remoteProviderObservable: Observable<[T]>? = entity.remoteProvider?.observeObjects()
      
      let localSubscription = localStorageObservable
        .subscribe(onNext: observer.onNext, onError: observer.onError)
      
      var remoteSubscription: Disposable? = nil
      if let remoteProviderObservable = remoteProviderObservable {
        remoteSubscription = remoteProviderObservable
          .flatMap { entity.localStorage.refreshFromRemote(withContent: $0).asObservable() }
          .subscribe()
      }
      
      return Disposables.create {
        localSubscription.dispose()
        remoteSubscription?.dispose()
      }
    }
  }
}
