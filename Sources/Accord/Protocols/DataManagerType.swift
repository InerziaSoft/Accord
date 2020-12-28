//
//  File.swift
//  
//
//  Created by Alessio Moiso on 30.11.20.
//

import RxSwift

public protocol DataManagerType {
  
  func register<T: AccordableEntity, C: AccordableContent>(entity: T, for contentType: C.Type) -> Completable
  
  func add<T: AccordableContent>(object: T, toEntity entityDescriptor: AccordableEntityDescriptor) -> Completable
  
  func update<T: AccordableContent>(object: T, inEntity entityDescriptor: AccordableEntityDescriptor) -> Completable
  
  func remove<T: AccordableContent>(object: T, fromEntity entityDescriptor: AccordableEntityDescriptor) -> Completable
  
  func observeObjects<T: AccordableContent>(forContentType accordableContent: T.Type, inEntity entityDescriptor: AccordableEntityDescriptor) -> Observable<[T]>
  
}
