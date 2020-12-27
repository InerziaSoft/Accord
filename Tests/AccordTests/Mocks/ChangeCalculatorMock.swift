//
//  File.swift
//  
//
//  Created by Alessio Moiso on 27.12.20.
//

import RxSwift
import Accord

class ChangeCalculatorMock: ChangeCalculator {
  
  func compute<T>(change: Change<T>, in entity: AccordableEntity) -> Completable where T : AccordableContent {
    return .empty()
  }
  
}
