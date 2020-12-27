//
//  File.swift
//  
//
//  Created by Alessio Moiso on 27.12.20.
//

public enum ChangeType: String, Codable {
  case sync = "sync",
       insert = "insert",
       update = "update",
       delete = "delete"
}
