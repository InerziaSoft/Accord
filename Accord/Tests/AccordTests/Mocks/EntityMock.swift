//
//  File.swift
//  
//
//  Created by Alessio Moiso on 07.12.20.
//

import Accord
import RxSwift

class EntityMock: AccordableEntity {
  
  static let identifier = "EntityMock"
  
  let id: String
  
  let dataStorage: LocalStorage
  
  let remoteProvider: RemoteProvider?
  
  let scheduler: SchedulerType? = MainScheduler.instance
  
  init(dataStorage: LocalStorage, remoteProvider: RemoteProvider?) {
    self.id = Self.identifier
    self.dataStorage = dataStorage
    self.remoteProvider = remoteProvider
  }
  
}
