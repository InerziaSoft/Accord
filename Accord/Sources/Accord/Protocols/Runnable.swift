//
//  File.swift
//  
//
//  Created by Alessio Moiso on 02.12.20.
//

import RxSwift

public typealias RunnableRepresentation = [String: Any]

public protocol Runnable: Identifiable {
  
  func run() -> Completable
  
  func toRepresentation() -> RunnableRepresentation
  
}
