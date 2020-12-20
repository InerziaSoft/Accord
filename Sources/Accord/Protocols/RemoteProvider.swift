//
//  File.swift
//  
//
//  Created by Alessio Moiso on 30.11.20.
//

import RxSwift

public protocol RemoteProvider {
  
  func observeObjects<T: AccordableContent>() -> Observable<[T]>
  
  func performAction<T: AccordableContent>(withContent content: T, action: DataAction) -> Single<Runnable>
  
}
