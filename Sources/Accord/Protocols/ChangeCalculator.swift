//
//  File.swift
//  
//
//  Created by Alessio Moiso on 27.12.20.
//

import RxSwift

public protocol ChangeCalculator {
  
  func compute<T: AccordableContent>(change: Change<T>, in entity: AccordableEntity) -> Completable
  
}
