//
//  File.swift
//  
//
//  Created by Alessio Moiso on 01.12.20.
//

/// This protocol represents a generic content.
///
/// Anything that can be saved and synced through a `DataManagerType`
/// needs to conform to this protocol.
public protocol AccordableContent: Identifiable & Codable { }
