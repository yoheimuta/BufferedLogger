//
//  MyWriter.swift
//  Demo
//
//  Created by YOSHIMUTA YOHEI on 2018/07/25.
//  Copyright © 2018年 YOSHIMUTA YOHEI. All rights reserved.
//

import BufferedLogger
import Foundation

class MyWriter: Writer {
    func write(_ chunk: Chunk, completion: (Bool) -> Void) {
        print("chunk is \(chunk)")

        chunk.entries.forEach {
            print("entry is \($0)")
        }

        completion(true)
    }
}
