//
//  BufferedOutput.swift
//  BufferedLogger
//
//  Created by YOSHIMUTA YOHEI on 2018/07/25.
//  Copyright © 2018年 YOSHIMUTA YOHEI. All rights reserved.
//

import Foundation

final class BufferedOutput {
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
        timer?.invalidate()
    }

    func start() {
        setUpTimer()
    }

    func resume() {
        flush()

        setUpTimer()
    }

    func suspend() {
        timer?.invalidate()
    }

    func emit(_ entry: Entry) {
        buffer.insert(entry)
        if buffer.count >= config.flushEntryCount {
            flush()
        }
    }

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
                flush()
            }
        } else {
            flush()
        }
    }

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
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self.callWriteChunk(chunk)
                }
            }
        }
    }
}
