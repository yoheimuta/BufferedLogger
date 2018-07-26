//
//  BufferedOutput.swift
//  BufferedLogger
//
//  Created by YOSHIMUTA YOHEI on 2018/07/25.
//  Copyright © 2018年 YOSHIMUTA YOHEI. All rights reserved.
//

import Foundation

final class BufferedOutput {
    private let queue = DispatchQueue(label: "com.github.yoheimuta.BufferedLogger.BufferedOutput",
                                      qos: .background)

    private let writer: Writer
    private let config: Config

    private var buffer: Set<Entry> = []
    private var timer: Timer?
    private var lastFlushDate: Date?
    private var now: Date {
        return Date()
    }

    init(writer: Writer, config: Config) {
        self.writer = writer
        self.config = config
    }

    deinit {
        DispatchQueue.main.sync {
            timer?.invalidate()
        }
    }

    func start() {
        DispatchQueue.main.sync {
            setUpTimer()
        }
    }

    func resume() {
        queue.sync {
            flush()
        }
        DispatchQueue.main.sync {
            setUpTimer()
        }
    }

    func suspend() {
        DispatchQueue.main.sync {
            timer?.invalidate()
        }
    }

    func emit(_ entry: Entry) {
        queue.async {
            self.buffer.insert(entry)
            if self.buffer.count >= self.config.flushEntryCount {
                self.flush()
            }
        }
    }

    /// setUpTimer must be called by the main thread.
    private func setUpTimer() {
        self.timer?.invalidate()

        let timer = Timer(timeInterval: 1.0,
                          target: self,
                          selector: #selector(tick(_:)),
                          userInfo: nil,
                          repeats: true)
        RunLoop.current.add(timer, forMode: .commonModes)
        self.timer = timer
    }

    @objc private func tick(_: Timer) {
        if let lastFlushDate = lastFlushDate {
            if now.timeIntervalSince(lastFlushDate) > config.flushInterval {
                queue.async {
                    self.flush()
                }
            }
        } else {
            queue.async {
                self.flush()
            }
        }
    }

    /// flush must be called by the queue worker.
    private func flush() {
        lastFlushDate = now

        if buffer.isEmpty {
            return
        }

        let logCount = min(buffer.count, config.flushEntryCount)
        let newBuffer = Set(buffer.dropFirst(logCount))
        let dropped = buffer.subtracting(newBuffer)
        buffer = newBuffer
        let chunk = Chunk(entries: dropped)
        callWriteChunk(chunk)
    }

    private func callWriteChunk(_ chunk: Chunk) {
        writer.write(chunk) { success in
            if success {
                return
            }

            var chunk = chunk
            chunk.incrementRetryCount()

            if chunk.retryCount <= config.retryRule.retryLimit {
                let delay = config.retryRule.delay(try: chunk.retryCount)
                queue.asyncAfter(deadline: .now() + delay) {
                    self.callWriteChunk(chunk)
                }
            }
        }
    }
}
