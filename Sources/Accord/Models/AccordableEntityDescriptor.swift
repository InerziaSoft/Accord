//
//  File.swift
//  
//
//  Created by Alessio Moiso on 02.12.20.
//

public struct AccordableEntityDescriptor: ExpressibleByStringLiteral {
  public let id: String
  
  public init(id: String) {
    self.id = id
  }
  
  public init(stringLiteral value: StringLiteralType) {
    self.id = value
  }
}
