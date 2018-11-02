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
    private let queue = DispatchQueue(label: "com.github.yoheimuta.Demo.MyWriter")

    func write(_ chunk: Chunk, completion: @escaping (Bool) -> Void) {
        print("chunk is \(chunk)")

        chunk.entries.forEach {
            print("entry is \($0)")
        }

        queue.async {
            completion(true)
        }
    }
}
