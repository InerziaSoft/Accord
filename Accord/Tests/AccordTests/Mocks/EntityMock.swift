//
//  File.swift
//  
//
//  Created by Alessio Moiso on 07.12.20.
//

import Accord
import RxSwift

class EntityMock: AccordableEntity {
  
  var id = "entityMock"
  
  var contentType: AccordableContent.Type
  
  var dataStorage: LocalStorage
  
  var remoteProvider: RemoteProvider?
  
  var scheduler: SchedulerType?
  
}
