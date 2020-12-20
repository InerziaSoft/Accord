//
//  File.swift
//  
//
//  Created by Alessio Moiso on 30.11.20.
//

import RxSwift

public protocol LocalStorage {
  
  func observeObjects<T: AccordableContent>(ofType type: T.Type) -> Observable<[T]>
  
  func refreshFromRemote<T: AccordableContent>(withContent content: [T]) -> Completable
  
  func perform<T: AccordableContent>(action: DataAction, withContent content: T) -> Completable
  
}
