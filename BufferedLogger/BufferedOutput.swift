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
    private let internalErrorLogger: InternalErrorLogger

    private var buffer: Set<Entry> = []
    private var timer: Timer?
    private var lastFlushDate: Date?
    private var now: Date {
        return Date()
    }

    private var sortedBuffer: [Entry] {
        return buffer.sorted { left, right in
            left.createTime < right.createTime
        }
    }

    init(writer: Writer,
         config: Config,
         entryStorage: EntryStorage,
         internalErrorLogger: InternalErrorLogger
    ) {
        self.writer = writer
        self.config = config
        self.entryStorage = entryStorage
        self.internalErrorLogger = internalErrorLogger
    }

    deinit {
        queue.sync {
            timer?.invalidate()
        }
    }

    func start() {
        queue.sync {
            reloadEntriesFromStorage()
            flush()

            setUpTimer()
        }
    }

    func resume() {
        queue.sync {
            reloadEntriesFromStorage()
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
            var dropFailed = false
            if self.config.maxEntryCountInStorage <= self.buffer.count {
                do {
                    try self.dropEntriesFromStorage()
                } catch {
                    dropFailed = true
                    self.internalErrorLogger.log("failed to drop logs from the storage: \(error)")
                }
            }

            if !dropFailed {
                do {
                    try self.entryStorage.save(entry, to: self.config.storagePath)
                } catch {
                    self.internalErrorLogger.log("failed to save a log to the storage: \(error)")
                }
            }

            self.buffer.insert(entry)
            if self.buffer.count >= self.config.flushEntryCount {
                self.flush()
            }
        }
    }

    /// setUpTimer must be called by the queue worker.
    private func setUpTimer() {
        if #available(iOS 10.0, *) {
            dispatchPrecondition(condition: .onQueue(queue))
        }

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

    /// reloadEntriesFromStorage must be called by the queue worker.
    private func reloadEntriesFromStorage() {
        if #available(iOS 10.0, *) {
            dispatchPrecondition(condition: .onQueue(queue))
        }

        buffer.removeAll()

        do {
            let entries = try entryStorage.retrieveAll(from: config.storagePath)
            buffer = buffer.union(entries)
        } catch {
            internalErrorLogger.log("failed to retrieve logs from the storage: \(error)")
        }
    }

    /// dropEntriesFromStorage must be called by the queue worker.
    private func dropEntriesFromStorage() throws {
        if #available(iOS 10.0, *) {
            dispatchPrecondition(condition: .onQueue(queue))
        }

        let dropCountAtOneTime = config.flushEntryCount * 3
        let newBuffer = Set(sortedBuffer.dropFirst(dropCountAtOneTime))
        let dropped = buffer.subtracting(newBuffer)

        // dropped the buffer before the failurable action.
        buffer = newBuffer
        try entryStorage.remove(dropped, from: config.storagePath)
    }

    /// flush must be called by the queue worker.
    private func flush() {
        if #available(iOS 10.0, *) {
            dispatchPrecondition(condition: .onQueue(queue))
        }

        lastFlushDate = now

        if buffer.isEmpty {
            return
        }

        let logCount = min(buffer.count, config.flushEntryCount)
        let newBuffer = Set(sortedBuffer.dropFirst(logCount))
        let dropped = buffer.subtracting(newBuffer)
        buffer = newBuffer
        let chunk = Chunk(entries: dropped)
        callWriteChunk(chunk)
    }

    private func callWriteChunk(_ chunk: Chunk) {
        if #available(iOS 10.0, *) {
            dispatchPrecondition(condition: .onQueue(queue))
        }

        writer.write(chunk) { success in
            self.queue.async {
                if #available(iOS 10.0, *) {
                    // Leave this check for a certain period to attest that the thread-safety bug is fixed.
                    dispatchPrecondition(condition: .onQueue(self.queue))
                }

                if success {
                    do {
                        try self.entryStorage.remove(chunk.entries,
                                                     from: self.config.storagePath)
                    } catch {
                        self.internalErrorLogger.log("failed to remove logs from the storage: \(error)")
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
}
