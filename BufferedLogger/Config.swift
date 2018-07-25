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
    
    /// retryRule is a rule of retry.
    public let retryRule: RetryRule
    
    public init(flushEntryCount: Int,
                flushInterval: TimeInterval,
                retryRule: RetryRule) {
        self.flushEntryCount = flushEntryCount
        self.flushInterval = flushInterval
        self.retryRule = retryRule
    }
    
    /// default is a default configuration.
    public static let `default` = Config(flushEntryCount: 5,
                                  flushInterval: 10,
                                  retryRule: DefaultRetryRule(retryLimit: 3))
}
