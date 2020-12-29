//
//  File.swift
//  
//
//  Created by Alessio Moiso on 06.12.20.
//

import Foundation
import RxSwift

public class FileSchedulerStorage: SchedulerStorageType {
  
  enum Errors: Error {
    case unreadableStorage,
         unsupportedMigration(toVersion: StorageVersion)
  }
  
  enum StorageVersion: String {
    case v1_0_0 = "1.0.0"
  }
  
  enum StorageKey: String {
    case items = "items",
         lastSavedDate = "lastSaved",
         version = "version"
  }
  
  static let storageVersion = StorageVersion.v1_0_0
  
  private let fileURL: URL
  private let runnableFactory: RunnableFactoryType
  
  public init(fileURL: URL, runnableFactory: RunnableFactoryType) {
    self.fileURL = fileURL
    self.runnableFactory = runnableFactory
  }
  
  public func flushAll() -> Single<[Runnable]> {
    .deferred { [weak self] in
      guard let self = self else { return Single.just([]) }
      do {
        return Single.just(try self.read())
      } catch {
        return Single.error(error)
      }
    }
  }
  
  public func append(runnable: Runnable) throws {
    var items = try readRaw()
    items += [runnable.toRepresentation()]
    try write(items: items)
  }
  
  public func remove(runnable: Runnable) throws {
    var items = try read()
    items.removeAll(where: { $0.id == runnable.id })
    try write(items: items.map { $0.toRepresentation() })
  }
  
}

private extension FileSchedulerStorage {
  func readRaw() throws -> [RunnableRepresentation] {
    if !FileManager.default.fileExists(atPath: fileURL.path) {
      try write(items: [])
    }
    
    guard
      let file = NSDictionary(contentsOfFile: fileURL.path) as? [String: Any],
      let versionString = file[StorageKey.version.rawValue] as? String,
      let version = StorageVersion(rawValue: versionString),
      let items = file[StorageKey.items.rawValue] as? [[String: Any]]
    else {
      throw Errors.unreadableStorage
    }
    guard
      version == Self.storageVersion
    else {
      throw Errors.unsupportedMigration(toVersion: version)
    }
    
    return items
  }
  
  func read() throws -> [Runnable] {
    try readRaw()
      .compactMap { [runnableFactory] in runnableFactory.make(fromRepresentation: $0) }
  }
  
  func makeStorageDictionary(items: [RunnableRepresentation]) -> [String: Any] {
    return [
      StorageKey.items.rawValue: items,
      StorageKey.lastSavedDate.rawValue: Date(),
      StorageKey.version.rawValue: Self.storageVersion
    ]
  }
  
  func write(items: [RunnableRepresentation]) throws {
    (makeStorageDictionary(items: items) as NSDictionary)
      .write(toFile: fileURL.path, atomically: true)
  }
}
