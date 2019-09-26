//
//  Entry.swift
//  BufferedLogger
//
//  Created by YOSHIMUTA YOHEI on 2018/07/25.
//  Copyright © 2018年 YOSHIMUTA YOHEI. All rights reserved.
//

import Foundation

/// Entry represents an entity to be written by a writer.
public struct Entry: Codable, Hashable {
    /// createTime is the date the entry is created.
    public let createTime: Date

    /// payload is a log content.
    public let payload: Data

    /// identifier is an unique entry ID.
    public let identifier: UUID

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }

    public static func == (lhs: Entry, rhs: Entry) -> Bool {
        return lhs.identifier == rhs.identifier
    }

    init(_ payload: Data, createTime: Date = Date()) {
        self.payload = payload
        self.createTime = createTime
        identifier = UUID()
    }
}
