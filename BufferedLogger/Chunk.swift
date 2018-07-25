//
//  Chunk.swift
//  BufferedLogger
//
//  Created by YOSHIMUTA YOHEI on 2018/07/25.
//  Copyright © 2018年 YOSHIMUTA YOHEI. All rights reserved.
//

import Foundation

/// Chunk represents a set of Entity.
public struct Chunk {
    // entries is a set of Entry.
    public let entries: Set<Entry>
    
    var retryCount: Int = 0
    
    init(entries: Set<Entry>) {
        self.entries = entries
    }
    
    mutating func incrementRetryCount() {
        retryCount += 1
    }
}
