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
    func write(_ chunk: Chunk, completion: @escaping (Bool) -> Void)
}
