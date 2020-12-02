//
//  File.swift
//  
//
//  Created by Alessio Moiso on 30.11.20.
//

import RxSwift

protocol LocalStorage {
  
  func observeObjects<T: AccordableContent>() -> Observable<[T]>
  
  func refreshFromRemote<T: AccordableContent>(withContent content: [T]) -> Completable
  
  func performAction<T: AccordableContent>(withContent content: T, action: DataAction) -> Completable
  
}
