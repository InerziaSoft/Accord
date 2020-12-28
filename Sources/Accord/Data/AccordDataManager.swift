//
//  File.swift
//  
//
//  Created by Alessio Moiso on 02.12.20.
//

import Foundation
import RxSwift
import RxRelay

/// The `AccordDataManager` is the main entry point to get,
/// observe and make changes to accordable data types.
///
/// To instantiate a data manager, you need to pass a `RunnablesScheduler`
/// and you also need to register all the known entities, by calling `register(entity:)`.
///
/// Ideally, you only have one instance of the `AccordDataManager` in your app.
/// Using multiple instance at the same time may lead to unexpected behaviors.
public class AccordDataManager: DataManagerType {
  
  /// Errors that can be thrown by instances of this class.
  enum Errors: Error {
          /// The data manager has been deallocated before returning a result.
          ///
          /// Make sure that you are holding a reference to the data manager.
    case  deallocatedInstance
          /// The requested entity is not known.
          ///
          /// Before using an entity with the data manager, you must register it
          /// by calling `register(entity:)`.
    case  unknownEntity
  }
  
  /// Get the scheduler where entities can be queried safely.
  private lazy var entitiesScheduler = SerialDispatchQueueScheduler(queue: entitiesQueue, internalSerialQueueName: Constants.entitiesRxQueueName)
  /// Get the queue where entities can be queried safely.
  private let entitiesQueue = DispatchQueue(label: Constants.entitiesQueueName)
  
  /// Get the relay that contains all the registered entities.
  private let entitiesRelay = BehaviorRelay<[String: AccordableEntity]>(value: [:])
  
  /// Get the registered entity associated with their IDs.
  public var entities: [String: AccordableEntity] {
    entitiesRelay.value
  }
  
  /// Get the runnables scheduler.
  let scheduler: RunnablesScheduler
  
  /// Get the change calculator.
  let changeCalculator: ChangeCalculator
  
  /// Initialize a new instance.
  ///
  /// - parameters:
  ///   - scheduler: A scheduler.
  public init(scheduler: RunnablesScheduler, changeCalculator: ChangeCalculator) {
    self.scheduler = scheduler
    self.changeCalculator = changeCalculator
  }
  
  /// Register a new entity for the specified content type.
  ///
  /// - parameters:
  ///   - entity: A entity.
  ///   - contentType: A content type.
  public func register<T, C>(entity: T, for contentType: C.Type) -> Completable where T : AccordableEntity, C: AccordableContent {
    Observable.deferred { () -> Observable<T> in
      if let remoteProvider = entity.remoteProvider {
        let remoteObjects: Single<[C]> = remoteProvider.objects()
        return remoteObjects
          .flatMapCompletable(entity.dataStorage.syncFromRemote)
          .andThen(.just(entity))
      }
      return .just(entity)
    }
    .withLatestFrom(entitiesRelay) { (entity, entities) -> [String: AccordableEntity] in
      var newEntities = entities
      newEntities[entity.id] = entity
      return newEntities
    }
    .do(onNext: { [entitiesRelay] in
      entitiesRelay.accept($0)
    })
    .ignoreElements()
  }
  
  /// Observe all objects in the specified entity.
  ///
  /// This function returns an `Observable` which emits
  /// new values every time something changes (either locally or from the
  /// remote provider) on the specified entity.
  ///
  /// - parameters:
  ///   - accordableContent: The expected content type.
  ///   - entityDescriptor: A entity descriptor.
  /// - returns: An Observable which emits new values every time something in the entity changes.
  public func observeObjects<T>(forContentType accordableContent: T.Type, inEntity entityDescriptor: AccordableEntityDescriptor) -> Observable<[T]> where T : AccordableContent {
    entity(forEntityDescriptor: entityDescriptor)
      .asObservable()
      .flatMap { [weak self] (entity: AccordableEntity) -> Observable<[T]> in
        guard let self = self else { return .empty() }
        return self.observe(entity: entity, forObjectsOfType: accordableContent) as Observable<[T]>
      }
  }
  
  /// Add an object to the specified entity.
  ///
  /// Entities can decide on their own what to do when
  /// trying to add an object that already exists.
  ///
  /// - parameters:
  ///   - object: An object.
  ///   - entityDescriptor: A entity descriptor.
  /// - returns: A Completable to observe.
  public func add<T>(object: T, toEntity entityDescriptor: AccordableEntityDescriptor) -> Completable where T : AccordableContent {
    entity(forEntityDescriptor: entityDescriptor)
      .flatMapCompletable { [weak self] in self?.action(.insert, onEntity: $0, withContent: object) ?? .error(Errors.deallocatedInstance) }
  }
  
  /// Update the passed object in the specified entity.
  ///
  /// Entities can decide on their own what to do when trying
  /// to update an object that doesn't exist.
  ///
  /// - parameters:
  ///   - object: An object.
  ///   - entityDescriptor: A entity descriptor.
  /// - returns: A Completable to observe.
  public func update<T>(object: T, inEntity entityDescriptor: AccordableEntityDescriptor) -> Completable where T : AccordableContent {
    entity(forEntityDescriptor: entityDescriptor)
      .flatMapCompletable { [weak self] in self?.action(.update, onEntity: $0, withContent: object) ?? .error(Errors.deallocatedInstance) }
  }
  
  /// Remove the passed object in the specified entity.
  ///
  /// Entities can decide on their own what to do when trying
  /// to remove an object that doesn't exist.
  ///
  /// - parameters:
  ///   - object: An object.
  ///   - entityDescriptor: A entity descriptor.
  /// - returns: A Completable to observe.
  public func remove<T>(object: T, fromEntity entityDescriptor: AccordableEntityDescriptor) -> Completable where T : AccordableContent {
    entity(forEntityDescriptor: entityDescriptor)
      .flatMapCompletable { [weak self] in self?.action(.delete, onEntity: $0, withContent: object) ?? .error(Errors.deallocatedInstance) }
  }
    
}

private extension AccordDataManager {
  /// Get the entity for the passed descriptor.
  ///
  /// This function will wait for the entity to appear in the entities dictionary,
  /// assuming that it has been registered or that it'll be registered in the future.
  /// The Single will never emit if the entity does not exist.
  ///
  /// - parameters:
  ///   - entityDescriptor: A entity descriptor.
  /// - returns: A Single that emits the correct entity or nothing if the entity does not exist.
  func entity(forEntityDescriptor entityDescriptor: AccordableEntityDescriptor) -> Single<AccordableEntity> {
    entitiesRelay
      .subscribeOn(entitiesScheduler)
      .observeOn(entitiesScheduler)
      .filter { $0.keys.contains(entityDescriptor.id) }
      .take(1)
      .map { $0[entityDescriptor.id]! }
      .flatMap { entity -> Single<AccordableEntity> in
        var single = Single.just(entity)
        if let scheduler = entity.scheduler {
          single = single.observeOn(scheduler)
        }
        return single
      }
      .asSingle()
  }
  
  /// Get the appropriate action for the passed action on the specified entity.
  ///
  /// This function creates a Completable which performs the action on the local storage
  /// and, if available, schedules the same action for the remote provider.
  ///
  /// - parameters:
  ///   - action: An action.
  ///   - entity: A entity.
  ///   - object: An object.
  /// - returns: A Completable to observe.
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
  
  /// Observe an entity for objects of the specified type.
  ///
  /// - parameters:
  ///   - entity; A entity.
  ///   - type: The expected type of the objects.
  /// - returns: An Observable that emits new values when something changes in the specified entity.
  func observe<T: AccordableContent>(entity: AccordableEntity, forObjectsOfType type: T.Type) -> Observable<[T]> {
    Observable.create { [changeCalculator] observer in
      let localStorageObservable: Observable<[T]> = entity.dataStorage.observeObjects(ofType: type)
      let remoteProviderObservable: Observable<Change<T>>? = entity.remoteProvider?.observeObjects()
      
      let localSubscription = localStorageObservable
        .subscribe(onNext: observer.onNext, onError: observer.onError)
      
      var remoteSubscription: Disposable? = nil
      if let remoteProviderObservable = remoteProviderObservable {
        remoteSubscription = remoteProviderObservable
          .flatMap { changeCalculator.compute(change: $0, in: entity) }
          .subscribe()
      }
      
      return Disposables.create {
        localSubscription.dispose()
        remoteSubscription?.dispose()
      }
    }
  }
}
