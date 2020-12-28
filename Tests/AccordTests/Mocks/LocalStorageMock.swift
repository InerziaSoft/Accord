//
//  File.swift
//  
//
//  Created by Alessio Moiso on 07.12.20.
//

import Accord
import RxSwift
import RxRelay

class LocalStorageMock: LocalStorage {
  
  enum Errors: Error {
    case invalidType
  }
  
  private let contentRelay = BehaviorRelay<[ContentMock]>(value: [])
  
  func currentContent() -> [ContentMock] {
    contentRelay.value
  }
  
  func syncFromRemote<T>(_ content: [T]) -> Completable where T : AccordableContent {
    .deferred { [contentRelay] in
      contentRelay.accept(content as! [ContentMock])
      return .empty()
    }
  }
  
  func observeObjects<T>(ofType type: T.Type) -> Observable<[T]> where T : AccordableContent {
    guard let _ = type as? ContentMock.Type else { return .error(Errors.invalidType) }
    
    return contentRelay.asObservable() as! Observable<[T]>
  }
  
  func perform<T>(action: DataAction, withContent content: T) -> Completable where T : AccordableContent {
    guard let content = content as? ContentMock else { return .error(Errors.invalidType) }
    
    return self.contentRelay
      .take(1).asSingle()
      .map { currentContent -> [ContentMock] in
        switch action {
        case .insert:
          return currentContent + [content]
        case .update, .sync:
          var newContent = currentContent
          newContent.removeAll(where: { $0.id == content.id })
          return newContent + [content]
        case .delete:
          var newContent = currentContent
          newContent.removeAll(where: { $0.id == content.id })
          return newContent
        }
      }
      .do(onSuccess: { [weak self] in self?.contentRelay.accept($0) })
      .asCompletable()
  }
  
}
