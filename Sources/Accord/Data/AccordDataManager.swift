//
//  File.swift
//  
//
//  Created by Alessio Moiso on 02.12.20.
//

import Foundation
import RxSwift

public class AccordDataManager: DataManagerType {
  
  enum Errors: Error {
    case deallocatedInstance
    case unknownEntity
  }
  
  private lazy var entitiesScheduler = SerialDispatchQueueScheduler(queue: entitiesQueue, internalSerialQueueName: Constants.entitiesRxQueueName)
  private let entitiesQueue = DispatchQueue(label: Constants.entitiesQueueName)
  
  public private(set) var entities = [String: AccordableEntity]()
  
  let scheduler: RunnablesScheduler
  
  init(scheduler: RunnablesScheduler) {
    self.scheduler = scheduler
  }
  
  public func register<T>(entity: T) where T : AccordableEntity {
    entitiesQueue.sync {
      entities[entity.id] = entity
    }
  }
  
  public func observeObjects<T>(forContentType accordableContent: T.Type, inEntity entityDescriptor: AccordableEntityDescriptor) -> Observable<[T]> where T : AccordableContent {
    entity(forEntityDescriptor: entityDescriptor)
      .asObservable()
      .flatMap { [weak self] (entity: AccordableEntity) -> Observable<[T]> in
        guard let self = self else { return .empty() }
        return self.observe(entity: entity, forObjectsOfType: accordableContent) as Observable<[T]>
      }
  }
  
  public func add<T>(object: T, toEntity entityDescriptor: AccordableEntityDescriptor) -> Completable where T : AccordableContent {
    entity(forEntityDescriptor: entityDescriptor)
      .flatMapCompletable { [weak self] in self?.action(.insert, onEntity: $0, withContent: object) ?? .error(Errors.deallocatedInstance) }
  }
  
  public func update<T>(object: T, inEntity entityDescriptor: AccordableEntityDescriptor) -> Completable where T : AccordableContent {
    entity(forEntityDescriptor: entityDescriptor)
      .flatMapCompletable { [weak self] in self?.action(.update, onEntity: $0, withContent: object) ?? .error(Errors.deallocatedInstance) }
  }
  
  public func remove<T>(object: T, fromEntity entityDescriptor: AccordableEntityDescriptor) -> Completable where T : AccordableContent {
    entity(forEntityDescriptor: entityDescriptor)
      .flatMapCompletable { [weak self] in self?.action(.delete, onEntity: $0, withContent: object) ?? .error(Errors.deallocatedInstance) }
  }
    
}

private extension AccordDataManager {
  func entity(forEntityDescriptor entityDescriptor: AccordableEntityDescriptor) -> Single<AccordableEntity> {
    Single.deferred { [weak self] in
      guard let self = self else { return .error(Errors.deallocatedInstance) }
      if let entity = self.entities[entityDescriptor.id] {
        var single = Single.just(entity)
        if let scheduler = entity.scheduler {
          single = single.observeOn(scheduler)
        }
        return single
      }
      return .error(Errors.unknownEntity)
    }
    .subscribeOn(entitiesScheduler)
  }
  
  func action<T: AccordableContent>(_ action: DataAction, onEntity entity: AccordableEntity, withContent object: T) -> Completable {
    Completable.deferred {
      var action = entity.dataStorage.perform(action: action, withContent: object)
      
      if let remoteProviderAction = entity.remoteProvider?.performAction(withContent: object, action: .insert) {
        action = action.andThen(remoteProviderAction)
          .do(onSuccess: { [weak self] in self?.scheduler.schedule(runnable: $0) })
          .asCompletable()
      }
      
      return action
    }
  }
  
  func observe<T: AccordableContent>(entity: AccordableEntity, forObjectsOfType type: T.Type) -> Observable<[T]> {
    Observable.create { observer in
      let localStorageObservable: Observable<[T]> = entity.dataStorage.observeObjects(ofType: type)
      let remoteProviderObservable: Observable<[T]>? = entity.remoteProvider?.observeObjects()
      
      let localSubscription = localStorageObservable
        .subscribe(onNext: observer.onNext, onError: observer.onError)
      
      var remoteSubscription: Disposable? = nil
      if let remoteProviderObservable = remoteProviderObservable {
        remoteSubscription = remoteProviderObservable
          .flatMap { entity.dataStorage.refreshFromRemote(withContent: $0).asObservable() }
          .subscribe()
      }
      
      return Disposables.create {
        localSubscription.dispose()
        remoteSubscription?.dispose()
      }
    }
  }
}
