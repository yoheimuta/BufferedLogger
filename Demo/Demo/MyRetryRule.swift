//
//  MyRetryRule.swift
//  Demo
//
//  Created by YOSHIMUTA YOHEI on 2018/07/25.
//  Copyright © 2018年 YOSHIMUTA YOHEI. All rights reserved.
//

import Foundation
import BufferedLogger

class MyRetryRule: RetryRule {
    public let retryLimit: Int
    
    public init(retryLimit: Int) {
        self.retryLimit = retryLimit
    }
    
    public func delay(try count: Int) -> TimeInterval {
        return 2.0 * pow(2.0, Double(count - 1))
    }
}
