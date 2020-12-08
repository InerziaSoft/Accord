//
//  File.swift
//  
//
//  Created by Alessio Moiso on 30.11.20.
//

import RxSwift

public protocol DataManagerType {
  
  func register<T: AccordableEntity>(entity: T)
  
  func add<T: AccordableContent>(object: T, toEntity entityDescriptor: AccordableEntityDescriptor) -> Completable
  
  func update<T: AccordableContent>(object: T, inEntity entityDescriptor: AccordableEntityDescriptor) -> Completable
  
  func remove<T: AccordableContent>(object: T, fromEntity entityDescriptor: AccordableEntityDescriptor) -> Completable
  
  func observeObjects<T: AccordableContent>(forContentType accordableContent: T, inEntity entityDescriptor: AccordableEntityDescriptor) -> Observable<[T]>
  
}
