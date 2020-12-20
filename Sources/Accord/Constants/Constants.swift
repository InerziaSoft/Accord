//
//  File.swift
//  
//
//  Created by Alessio Moiso on 02.12.20.
//

/// Contains definitions of constant values.
struct Constants {
  /// Get the name of the queue on which actions related to entities will be performed.
  static let entitiesQueueName = "eu.inerziasoft.Accord.entities"
  /// Get the name of the Rx queue associated to entity actions.
  static let entitiesRxQueueName = "eu.inerziasoft.Accord.entities.rx"
  /// Get the name of the queue on which actions related to schedulers will be performed.
  static let schedulerQueueName = "eu.inerziasoft.Accord.scheduler"
  /// Get the name of the Rx queue associated to scheduler actions.
  static let scheduleRxQueueName = "eu.inerziasoft.Accord.scheduler.rx"
}
