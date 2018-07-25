//
//  Writer.swift
//  BufferedLogger
//
//  Created by YOSHIMUTA YOHEI on 2018/07/25.
//  Copyright © 2018年 YOSHIMUTA YOHEI. All rights reserved.
//

import Foundation

/// Writer represents a protocol to write a chunk of logs.
public protocol Writer {
    /// write is invoked with logs periodically.
    ///
    /// - Parameters:
    ///   - chunk: a set of log entries
    ///   - completion: call with true when the write action is success.
    func write(_ chunk: Chunk, completion: (Bool) -> Void)
}

extension Writer {
    /// delay is used for writer to decide how long to wait for a next retry.
    public func delay(try count: Int) -> TimeInterval {
        return 2.0 * pow(2.0, Double(count - 1))
    }
}
