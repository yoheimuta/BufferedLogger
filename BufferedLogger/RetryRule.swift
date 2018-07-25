//
//  RetryRule.swift
//  BufferedLogger
//
//  Created by YOSHIMUTA YOHEI on 2018/07/25.
//  Copyright © 2018年 YOSHIMUTA YOHEI. All rights reserved.
//

import Foundation

/// RetryRule is a rule about retry.
public protocol RetryRule {
    /// retryLimit is a retry count.
    /// The chunk is deleted after it failed more than this number of times.
    var retryLimit: Int { get }
    
    /// delay is an interval to decide how long to wait for a next retry.
    func delay(try count: Int) -> TimeInterval
}

/// DefaultRetryRule is a default implementation of RetryRule.
public class DefaultRetryRule: RetryRule {
    public let retryLimit: Int
    
    public init(retryLimit: Int) {
        self.retryLimit = retryLimit
    }
    
    public func delay(try count: Int) -> TimeInterval {
        return 2.0 * pow(2.0, Double(count - 1))
    }
}
