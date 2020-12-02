//
//  File.swift
//  
//
//  Created by Alessio Moiso on 30.11.20.
//

import Foundation

protocol AccordableEntity: Identifiable {
  
  var contentType: AccordableContent.Type { get }
  
  var localStorage: LocalStorage { get }
  
  var remoteProvider: RemoteProvider? { get }
  
  var queue: DispatchQueue? { get }
  
}
