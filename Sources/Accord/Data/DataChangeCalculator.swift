//
//  File.swift
//  
//
//  Created by Alessio Moiso on 27.12.20.
//

import RxSwift

public class DataChangeCalculator: ChangeCalculator {
  
  public func compute<T>(change: Change<T>, in entity: AccordableEntity) -> Completable where T : AccordableContent {
    switch change.changeType {
    case .sync:
      guard let content = change.current else { return .empty() }
      return entity.dataStorage.perform(action: .sync, withContent: content)
    case .insert:
      guard let content = change.current else { return .empty() }
      return entity.dataStorage.perform(action: .insert, withContent: content)
    case .update:
      guard let content = change.current else { return .empty() }
      return entity.dataStorage.perform(action: .update, withContent: content)
    case .delete:
      guard let content = change.old else { return .empty() }
      return entity.dataStorage.perform(action: .delete, withContent: content)
    }
  }
  
}
