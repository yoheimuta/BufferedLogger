//
//  Config.swift
//  BufferedLogger
//
//  Created by YOSHIMUTA YOHEI on 2018/07/25.
//  Copyright © 2018年 YOSHIMUTA YOHEI. All rights reserved.
//

import Foundation

public let defaultStoragePath = "Buffer"

/// Config represents a configuration for buffering and writing logs.
public struct Config {
    /// flushEntryCount is the maximum number of entries per one chunk.
    /// When the number of entries of buffer reaches this count, it starts to write a chunk.
    public let flushEntryCount: Int

    /// flushInterval is a interval to write a chunk.
    public let flushInterval: TimeInterval

    /// retryRule is a rule of retry.
    public let retryRule: RetryRule

    /// storagePath is a path to the entries.
    /// When you uses multiple BFLogger, you must set an unique path.
    public let storagePath: String

    public init(flushEntryCount: Int = 5,
                flushInterval: TimeInterval = 10,
                retryRule: RetryRule = DefaultRetryRule(retryLimit: 3),
                storagePath: String = defaultStoragePath) {
        self.flushEntryCount = flushEntryCount
        self.flushInterval = flushInterval
        self.retryRule = retryRule
        self.storagePath = storagePath
    }

    /// default is a default configuration.
    public static let `default` = Config()
}
