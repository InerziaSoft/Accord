//
//  File.swift
//  
//
//  Created by Alessio Moiso on 30.11.20.
//

import Foundation
import RxSwift

/// An entity is a type of objects that can be synced through a
/// `DataManagerType`.
///
/// You can think of an entity as a table of a database or
/// an entity of Core Data.
public protocol AccordableEntity: Identifiable {
  
  /// Get the type of objects that this entity stores.
  var contentType: AccordableContent.Type { get }
  
  /// Get an object responsible of storing this entity locally.
  ///
  /// This can be a database, a file manager or whatever logic you
  /// want to use to save this entity on the local device.
  var dataStorage: LocalStorage { get }
  
  /// Get an object responsible of syncing this entity on the remote server.
  ///
  /// This can be an implementation of a network service or whatever logic
  /// you want to use to sync this entity with your backend.
  ///
  /// Objects can provide `nil` here to be saved locally only.
  var remoteProvider: RemoteProvider? { get }
  
  /// Get a scheduler on which actions performed on this entity
  /// must be executed.
  var scheduler: SchedulerType? { get }
  
}
