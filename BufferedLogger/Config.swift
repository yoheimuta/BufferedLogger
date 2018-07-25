//
//  Config.swift
//  BufferedLogger
//
//  Created by YOSHIMUTA YOHEI on 2018/07/25.
//  Copyright © 2018年 YOSHIMUTA YOHEI. All rights reserved.
//

import Foundation

/// Config represents a configuration for buffering and writing logs.
public struct Config {
    /// flushEntryCount is the maximum number of entries per one chunk.
    /// When the number of entries of buffer reaches this count, it starts to write a chunk.
    public let flushEntryCount: Int
    
    /// flushInterval is a interval to write a chunk.
    public let flushInterval: TimeInterval
    
    /// retryLimit is a retry count.
    /// The chunk is deleted after it failed more than this number of times.
    public let retryLimit: Int
    
    static let `default` = Config(flushEntryCount: 5,
                                  flushInterval: 10,
                                  retryLimit: 3)
}
