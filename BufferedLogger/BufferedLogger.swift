//
//  BufferedLogger.swift
//  BufferedLogger
//
//  Created by YOSHIMUTA YOHEI on 2018/07/25.
//  Copyright © 2018年 YOSHIMUTA YOHEI. All rights reserved.
//

import Foundation

/// BufferedLogger is a logger that has a buffering function to bundle logs and retry flushing.
public final class BufferedLogger {
    private let output: BufferedOutput
    
    public init(writer: Writer, config: Config?) {
        output = BufferedOutput(writer: writer,
                                config: config ?? Config.default)
    }
    
    /// post emits a log payload to the buffer without blocking.
    public func post(_ payload: Data) {
        let entry = Entry(payload)
        output.emit(entry)
    }
    
    public func suspend() {
        output.suspend()
    }
    
    public func resume() {
        output.resume()
    }
    
    deinit {
        suspend()
    }
}
