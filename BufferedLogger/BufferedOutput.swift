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
    private let entryStorage: EntryStorage

    private var buffer: Set<Entry> = []
    private var timer: Timer?
    private var lastFlushDate: Date?
    private var now: Date {
        return Date()
    }

    init(writer: Writer, config: Config, entryStorage: EntryStorage) {
        self.writer = writer
        self.config = config
        self.entryStorage = entryStorage
    }

    deinit {
        queue.sync {
            timer?.invalidate()
        }
    }

    func start() {
        queue.sync {
            reloadEntities()
            flush()

            setUpTimer()
        }
    }

    func resume() {
        queue.sync {
            reloadEntities()
            flush()

            setUpTimer()
        }
    }

    func suspend() {
        queue.sync {
            timer?.invalidate()
        }
    }

    func emit(_ entry: Entry) {
        queue.async {
            do {
                try self.entryStorage.save(entry, to: self.config.storagePath)
            } catch {
                print("\(error)")
            }

            self.buffer.insert(entry)
            if self.buffer.count >= self.config.flushEntryCount {
                self.flush()
            }
        }
    }

    /// setUpTimer must be called by the queue worker.
    private func setUpTimer() {
        self.timer?.invalidate()

        let timer = Timer(timeInterval: 1.0,
                          target: self,
                          selector: #selector(tick(_:)),
                          userInfo: nil,
                          repeats: true)
        DispatchQueue.main.async {
            RunLoop.main.add(timer, forMode: .commonModes)
        }
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

    /// reloadEntities must be called by the queue worker.
    private func reloadEntities() {
        buffer.removeAll()

        do {
            let entries = try entryStorage.retrieveAll(from: config.storagePath)
            buffer = buffer.union(entries)
        } catch {
            print("\(error)")
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
                do {
                    try self.entryStorage.remove(chunk.entries,
                                                 from: self.config.storagePath)
                } catch {
                    print("\(error)")
                }
                return
            }

            var chunk = chunk
            chunk.incrementRetryCount()

            if chunk.retryCount <= self.config.retryRule.retryLimit {
                let delay = self.config.retryRule.delay(try: chunk.retryCount)
                self.queue.asyncAfter(deadline: .now() + delay) {
                    self.callWriteChunk(chunk)
                }
            }
        }
    }
}
