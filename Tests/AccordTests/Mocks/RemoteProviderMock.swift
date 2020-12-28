//
//  File.swift
//  
//
//  Created by Alessio Moiso on 07.12.20.
//

import Foundation
import Accord
import RxSwift
import RxRelay

class RemoteProviderMock: RemoteProvider {
  
  enum Errors: Error {
    case invalidType
  }
  
  private let contentRelay = BehaviorRelay<[ContentMock]>(value: [])
  
  func inject(content: ContentMock) {
    contentRelay.accept(contentRelay.value + [content])
  }
  
  func objects<T>() -> Single<[T]> where T : AccordableContent {
    contentRelay
      .take(1).asSingle()
      .map { $0.map { $0 as! T } }
  }
  
  func observeObjects<T>() -> Observable<Change<T>> where T : AccordableContent {
    .just(Change(current: nil, old: nil, changeType: .sync))
  }
  
  func performAction<T>(withContent content: T, action: DataAction) -> Single<Runnable> where T : AccordableContent {
    guard let content = content as? ContentMock else { return .error(Errors.invalidType) }
    
    switch action {
    case .insert:
      return self.contentRelay
        .take(1).asSingle()
        .map { $0 + [content] }
        .map { [contentRelay] in RemoteProviderRunnableMock(relay: contentRelay, newContent: $0) }
    case .delete:
      return self.contentRelay
        .take(1).asSingle()
        .map { array -> [ContentMock] in
          var newContent = array
          newContent.removeAll(where: { $0.id == content.id })
          return newContent
        }
        .map { [contentRelay] in RemoteProviderRunnableMock(relay: contentRelay, newContent: $0) }
    case .update:
      return self.contentRelay
        .take(1).asSingle()
        .map { array -> [ContentMock] in
          var newContent = array
          guard let index = newContent.firstIndex(where: { $0.id == content.id }) else { return newContent }
          newContent.replaceSubrange(index..<index+1, with: [content])
          return newContent
        }
        .map { [contentRelay] in RemoteProviderRunnableMock(relay: contentRelay, newContent: $0) }
    case .sync:
      return .never()
    }
  }
  
}

struct RemoteProviderRunnableMock: Runnable {
  
  let id = UUID().uuidString
  private let relay: BehaviorRelay<[ContentMock]>?
  private let newContent: [ContentMock]
  
  init(relay: BehaviorRelay<[ContentMock]>, newContent: [ContentMock]) {
    self.relay = relay
    self.newContent = newContent
  }
  
  func run() -> Completable {
    .deferred { [relay, newContent] in
      relay?.accept(newContent)
      return .empty()
    }
  }
  
  func toRepresentation() -> RunnableRepresentation {
    ["content": try! JSONEncoder().encode(newContent)]
  }
  
}
