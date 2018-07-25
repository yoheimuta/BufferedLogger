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
    /// payload is a log content.
    public let payload: Data

    private let identifier: UUID = UUID()

    public var hashValue: Int {
        return identifier.hashValue
    }

    public static func == (lhs: Entry, rhs: Entry) -> Bool {
        return lhs.identifier == rhs.identifier
    }

    init(_ payload: Data) {
        self.payload = payload
    }
}
