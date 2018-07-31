//
//  InternalErrorLogger.swift
//  BufferedLogger
//
//  Created by YOSHIMUTA YOHEI on 2018/07/31.
//  Copyright © 2018年 YOSHIMUTA YOHEI. All rights reserved.
//
// swiftlint:disable function_parameter_count

import Foundation

/// InternalErrorLogDestination outputs a log to the specific destination.
public protocol InternalErrorLogDestination {
    /// log ouputs a log to the destination.
    func log(
        time: String,
        message: String,
        fileName: String,
        line: Int,
        column: Int,
        funcName: String
    )
}

/// LogConsoleDestination outputs a log to the console.
public final class LogConsoleDestination: InternalErrorLogDestination {
    private let queue = DispatchQueue(label: "com.github.yoheimuta.BufferedLogger.LogConsoleDestination",
                                      qos: .background)

    public init() {}

    public func log(
        time: String,
        message: String,
        fileName: String,
        line: Int,
        column: Int,
        funcName: String
    ) {
        queue.async {
            print("\(time) [BufferedLogger \(fileName)]:\(line) \(column) \(funcName) -> \(message)")
        }
    }
}

final class InternalErrorLogger {
    private let logDestination: InternalErrorLogDestination

    init(_ logDestination: InternalErrorLogDestination) {
        self.logDestination = logDestination
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter
    }

    func log(
        _ message: String,
        filePath: String = #file,
        line: Int = #line,
        column: Int = #column,
        funcName: String = #function
    ) {
        logDestination.log(time: dateFormatter.string(from: Date()),
                           message: message,
                           fileName: sourceFileName(filePath: filePath),
                           line: line,
                           column: column,
                           funcName: funcName)
    }
}

private func sourceFileName(filePath: String) -> String {
    let components = filePath.components(separatedBy: "/")
    return components.isEmpty ? "" : components.last!
}
