//
//  File.swift
//  
//
//  Created by Alessio Moiso on 06.12.20.
//

import Foundation

public protocol RunnableFactoryType {
  
  func make(fromRepresentation representation: RunnableRepresentation) -> Runnable?
  
}
