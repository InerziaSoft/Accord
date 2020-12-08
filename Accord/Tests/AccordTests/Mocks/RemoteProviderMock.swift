//
//  File.swift
//  
//
//  Created by Alessio Moiso on 07.12.20.
//

import Accord
import RxSwift
import RxRelay

class RemoteProviderMock: RemoteProvider {
  
  private let content = BehaviorRelay<[ContentMock]>(value: [])
  
  func inject(content: ContentMock) {
    self.content.accept(self.content.value + [content])
  }
  
  func observeObjects<T>() -> Observable<[T]> where T : AccordableContent {
    content as! Observable<[T]>
  }
  
  func performAction<T>(withContent content: T, action: DataAction) -> Single<Runnable> where T : AccordableContent {
    
  }
  
}
