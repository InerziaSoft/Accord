//
//  File.swift
//  
//
//  Created by Alessio Moiso on 27.12.20.
//

import Foundation

public struct Change<T: AccordableContent>: Codable {
  
  let current: T?
  
  let old: T?
  
  let changeType: ChangeType
  
  public init(current: T?, old: T?, changeType: ChangeType) {
    self.current = current
    self.old = old
    self.changeType = changeType
  }
  
}
