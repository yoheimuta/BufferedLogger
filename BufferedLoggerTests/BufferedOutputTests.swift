//
//  BufferedOutputTests.swift
//  BufferedLoggerTests
//
//  Created by YOSHIMUTA YOHEI on 2018/07/25.
//  Copyright © 2018年 YOSHIMUTA YOHEI. All rights reserved.
//
// swiftlint:disable superfluous_disable_command
// swiftlint:disable function_body_length
// swiftlint:disable line_length
// swiftlint:disable file_length
// swiftlint:disable type_body_length

@testable import BufferedLogger
import XCTest

final class MockWriter: Writer {
    private let queue = DispatchQueue.global()
    private let shouldSuccess: Bool

    var writeCallback: ((Int) -> Void)?
    private(set) var calledWriteCount: Int = 0
    private(set) var givenPayloads: [Data] = []

    init(shouldSuccess: Bool) {
        self.shouldSuccess = shouldSuccess
    }

    func write(_ chunk: Chunk,
               completion: @escaping (Bool) -> Void) {
        calledWriteCount += 1
        chunk.entries.forEach {
            givenPayloads.append($0.payload)
        }

        let count = calledWriteCount

        queue.async {
            completion(self.shouldSuccess)
            self.writeCallback?(count-1)
        }
    }
}

final class MockRetryRule: RetryRule {
    let retryLimit: Int

    init(retryLimit: Int) {
        self.retryLimit = retryLimit
    }

    func delay(try _: Int) -> TimeInterval {
        return 1
    }
}

final class MockEntryStorage: EntryStorage {
    private let removeCallback: ((Int) -> Void)?
    private(set) var calledRemoveCount: Int = 0
    private var buffer: [String: Set<Entry>] = [:]

    init(removeCallback: ((Int) -> Void)? = nil) {
        self.removeCallback = removeCallback
    }

    func retrieveAll(from path: String) throws -> Set<Entry> {
        guard let logs = buffer[path] else {
            return []
        }
        return logs
    }

    func save(_ log: Entry, to path: String) throws {
        if buffer[path] == nil {
            buffer[path] = Set<Entry>()
        }
        buffer[path]?.formUnion([log])
    }

    func remove(_ logs: Set<Entry>, from path: String) throws {
        buffer[path]?.subtract(logs)

        calledRemoveCount += 1
        if let callback = removeCallback {
            callback(calledRemoveCount - 1)
        }
    }
}

enum PayloadDecorder {
    static func decode(_ payloads: [Data]) -> [String] {
        return payloads.map { PayloadDecorder.decode($0) }
    }

    static private func decode(_ payload: Data) -> String {
        return String(data: payload, encoding: .utf8)!
    }
}

class BufferedOutputTests: XCTestCase {
    func testFlush() {
        let tests: [(
            name: String,
            writer: MockWriter,
            config: Config,
            inputPayloads: [Data],
            expectations: [XCTestExpectation],
            storageRemovalExpectations: [XCTestExpectation],
            waitTime: TimeInterval,
            wantPayloads: [Data],
            wantLeftEntryCount: Int
        )] = [
                (
                    name: "expect to be called a writer.write() after emitting one entry.",
                    writer: MockWriter(shouldSuccess: true),
                    config: Config(flushEntryCount: 1,
                                   flushInterval: CFTimeInterval.infinity,
                                   retryRule: DefaultRetryRule(retryLimit: 1)),
                    inputPayloads: [
                        "1".data(using: .utf8)!
                    ],
                    expectations: [
                        self.expectation(description: "flush 1")
                    ],
                    storageRemovalExpectations: [
                        self.expectation(description: "remove 1")
                    ],
                    waitTime: 1,
                    wantPayloads: [
                        "1".data(using: .utf8)!
                    ],
                    wantLeftEntryCount: 0
                ),
                (
                    name: "expect to be called twice writer.write() after emitting two entries.",
                    writer: MockWriter(shouldSuccess: true),
                    config: Config(flushEntryCount: 1,
                                   flushInterval: CFTimeInterval.infinity,
                                   retryRule: DefaultRetryRule(retryLimit: 1)),
                    inputPayloads: [
                        "1".data(using: .utf8)!,
                        "2".data(using: .utf8)!
                    ],
                    expectations: [
                        self.expectation(description: "flush 1"),
                        self.expectation(description: "flush 2")
                    ],
                    storageRemovalExpectations: [
                        self.expectation(description: "remove 1"),
                        self.expectation(description: "remove 2")
                    ],
                    waitTime: 1,
                    wantPayloads: [
                        "1".data(using: .utf8)!,
                        "2".data(using: .utf8)!
                    ],
                    wantLeftEntryCount: 0
                ),
                (
                    name: "expect to be called a writer.write() after emitting two entries.",
                    writer: MockWriter(shouldSuccess: true),
                    config: Config(flushEntryCount: 2,
                                   flushInterval: CFTimeInterval.infinity,
                                   retryRule: DefaultRetryRule(retryLimit: 1)),
                    inputPayloads: [
                        "1".data(using: .utf8)!,
                        "2".data(using: .utf8)!
                    ],
                    expectations: [
                        self.expectation(description: "flush 1")
                    ],
                    storageRemovalExpectations: [
                        self.expectation(description: "remove 1")
                    ],
                    waitTime: 1,
                    wantPayloads: [
                        "1".data(using: .utf8)!,
                        "2".data(using: .utf8)!
                    ],
                    wantLeftEntryCount: 0
                ),
                (
                    name: "expect to be called a writer.write() after interval time passed.",
                    writer: MockWriter(shouldSuccess: true),
                    config: Config(flushEntryCount: 10,
                                   flushInterval: 1,
                                   retryRule: DefaultRetryRule(retryLimit: 1)),
                    inputPayloads: [
                        "1".data(using: .utf8)!,
                        "2".data(using: .utf8)!,
                        "3".data(using: .utf8)!
                    ],
                    expectations: [
                        self.expectation(description: "flush 1")
                    ],
                    storageRemovalExpectations: [
                        self.expectation(description: "remove 1")
                    ],
                    waitTime: 2,
                    wantPayloads: [
                        "1".data(using: .utf8)!,
                        "2".data(using: .utf8)!,
                        "3".data(using: .utf8)!
                    ],
                    wantLeftEntryCount: 0
                ),
                (
                    name: "expect to be called twice writer.write() after emitting entries and then interval time passed.",
                    writer: MockWriter(shouldSuccess: true),
                    config: Config(flushEntryCount: 3,
                                   flushInterval: 2,
                                   retryRule: DefaultRetryRule(retryLimit: 1)),
                    inputPayloads: [
                        "1".data(using: .utf8)!,
                        "2".data(using: .utf8)!,
                        "3".data(using: .utf8)!,
                        "4".data(using: .utf8)!
                    ],
                    expectations: [
                        self.expectation(description: "flush 1"),
                        self.expectation(description: "flush 2")
                    ],
                    storageRemovalExpectations: [
                        self.expectation(description: "remove 1"),
                        self.expectation(description: "remove 2")
                    ],
                    waitTime: 4,
                    wantPayloads: [
                        "1".data(using: .utf8)!,
                        "2".data(using: .utf8)!,
                        "3".data(using: .utf8)!,
                        "4".data(using: .utf8)!
                    ],
                    wantLeftEntryCount: 0
                ),
                (
                    name: "expect to be called writer.write() 4 times after emitting one entry.",
                    writer: MockWriter(shouldSuccess: false),
                    config: Config(flushEntryCount: 1,
                                   flushInterval: CFTimeInterval.infinity,
                                   retryRule: MockRetryRule(retryLimit: 3)),
                    inputPayloads: [
                        "1".data(using: .utf8)!
                    ],
                    expectations: [
                        self.expectation(description: "flush 1"),
                        self.expectation(description: "retry 1"),
                        self.expectation(description: "retry 2"),
                        self.expectation(description: "retry 3")
                    ],
                    storageRemovalExpectations: [
                    ],
                    waitTime: 4,
                    wantPayloads: [
                        "1".data(using: .utf8)!,
                        "1".data(using: .utf8)!,
                        "1".data(using: .utf8)!,
                        "1".data(using: .utf8)!
                    ],
                    wantLeftEntryCount: 1
                )
        ]

        for test in tests {
            test.writer.writeCallback = { count in
                test.expectations[count].fulfill()
            }

            let mStorage = MockEntryStorage(removeCallback: { count in
                test.storageRemovalExpectations[count].fulfill()
            })

            let output = BufferedOutput(writer: test.writer,
                                        config: test.config,
                                        entryStorage: mStorage,
                                        internalErrorLogger: InternalErrorLogger(LogConsoleDestination()))

            let setupExpectation = expectation(description: "setup")
            DispatchQueue.global(qos: .default).async {
                output.start()
                setupExpectation.fulfill()
            }
            wait(for: [setupExpectation], timeout: 1.0)

            for payload in test.inputPayloads {
                DispatchQueue.global(qos: .default).async {
                    output.emit(Entry(payload))
                }
            }

            wait(for: test.expectations, timeout: test.waitTime)
            XCTAssertEqual(test.writer.calledWriteCount,
                           test.expectations.count,
                           test.name)

            XCTAssertEqual(PayloadDecorder.decode(test.writer.givenPayloads).sorted(),
                           PayloadDecorder.decode(test.wantPayloads).sorted(),
                           test.name)

            // Wait for a while until the entries are deleted from entryStorage
            // because the callback block of Writer.write is run on any thread.
            // ref. https://github.com/yoheimuta/BufferedLogger/pull/7 {
            wait(for: test.storageRemovalExpectations, timeout: 2.0)
            XCTAssertEqual(mStorage.calledRemoveCount,
                           test.storageRemovalExpectations.count,
                           test.name)
            XCTAssertEqual(try mStorage.retrieveAll(from: defaultStoragePath).count,
                           test.wantLeftEntryCount,
                           test.name)
            // }
        }
    }

    func testSuspend() {
        let tests: [(
            name: String,
            callSuspend: Bool,
            wantCalledWriteCount: Int
        )] = [
            (
                name: "expect a call to flush without suspension",
                callSuspend: false,
                wantCalledWriteCount: 1
            ),
            (
                name: "expect no call to flush after suspension",
                callSuspend: true,
                wantCalledWriteCount: 0
            )
        ]

        for test in tests {
            let mwriter = MockWriter(shouldSuccess: true)
            let output = BufferedOutput(writer: mwriter,
                                        config: Config(flushEntryCount: 10,
                                                       flushInterval: 1,
                                                       retryRule: DefaultRetryRule(retryLimit: 1)),
                                        entryStorage: MockEntryStorage(),
                                        internalErrorLogger: InternalErrorLogger(LogConsoleDestination()))
            output.start()

            if test.callSuspend {
                output.suspend()
            }

            output.emit(Entry("1".data(using: .utf8)!))

            let afterExpectation = expectation(description: "after")
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                afterExpectation.fulfill()
            }
            wait(for: [afterExpectation], timeout: 4.0)
            XCTAssertEqual(mwriter.calledWriteCount,
                           test.wantCalledWriteCount,
                           test.name)
        }
    }

    func testResume() {
        let tests: [(
            name: String,
            callResume: Bool,
            wantCalledWriteCount: Int
            )] = [
                (
                    name: "expect no call to flush without resumption",
                    callResume: false,
                    wantCalledWriteCount: 0
                ),
                (
                    name: "expect a call to flush after resumption",
                    callResume: true,
                    wantCalledWriteCount: 1
                )
        ]

        for test in tests {
            let mwriter = MockWriter(shouldSuccess: true)
            let output = BufferedOutput(writer: mwriter,
                                        config: Config(flushEntryCount: 10,
                                                       flushInterval: 1,
                                                       retryRule: DefaultRetryRule(retryLimit: 1)),
                                        entryStorage: MockEntryStorage(),
                                        internalErrorLogger: InternalErrorLogger(LogConsoleDestination()))
            output.start()
            output.suspend()

            if test.callResume {
                output.resume()
            }

            output.emit(Entry("1".data(using: .utf8)!))

            let afterExpectation = expectation(description: "after")
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                afterExpectation.fulfill()
            }
            wait(for: [afterExpectation], timeout: 4.0)
            XCTAssertEqual(mwriter.calledWriteCount,
                           test.wantCalledWriteCount,
                           test.name)
        }
    }

    func testStartWithEntryStorage() {
        let path = "testStartWithEntryStorage"

        let tests: [(
            name: String,
            config: Config,
            inputLogs: Set<Entry>,
            expectations: [XCTestExpectation],
            wantCalledWriteCount: Int
        )] = [
                (
                    name: "expect no flush calls when there were not any entries in the storage",
                    config: Config(flushEntryCount: 2,
                                   flushInterval: CFTimeInterval.infinity,
                                   retryRule: DefaultRetryRule(retryLimit: 1),
                                   storagePath: path),
                    inputLogs: [],
                    expectations: [],
                    wantCalledWriteCount: 0
                ),
                (
                    name: "expect a flush call when there were an entry in the storage",
                    config: Config(flushEntryCount: 2,
                                   flushInterval: CFTimeInterval.infinity,
                                   retryRule: DefaultRetryRule(retryLimit: 1),
                                   storagePath: path),
                    inputLogs: [
                        Entry("1".data(using: .utf8)!)
                    ],
                    expectations: [
                        self.expectation(description: "flush 1")
                    ],
                    wantCalledWriteCount: 1
                ),
                (
                    name: "expect a flush call when there were entries in the storage",
                    config: Config(flushEntryCount: 4,
                                   flushInterval: 1,
                                   retryRule: DefaultRetryRule(retryLimit: 1),
                                   storagePath: path),
                    inputLogs: [
                        Entry("1".data(using: .utf8)!),
                        Entry("2".data(using: .utf8)!),
                        Entry("3".data(using: .utf8)!),
                        Entry("4".data(using: .utf8)!)
                    ],
                    expectations: [
                        self.expectation(description: "flush 1")
                    ],
                    wantCalledWriteCount: 1
                ),
                (
                    name: "expect twice flush calls when there were entries in the storage",
                    config: Config(flushEntryCount: 2,
                                   flushInterval: 1,
                                   retryRule: DefaultRetryRule(retryLimit: 1),
                                   storagePath: path),
                    inputLogs: [
                        Entry("1".data(using: .utf8)!),
                        Entry("2".data(using: .utf8)!),
                        Entry("3".data(using: .utf8)!),
                        Entry("4".data(using: .utf8)!)
                    ],
                    expectations: [
                        self.expectation(description: "flush 1"),
                        self.expectation(description: "flush 2")
                    ],
                    wantCalledWriteCount: 2
                )
        ]

        for test in tests {
            let mwriter = MockWriter(shouldSuccess: true)
            mwriter.writeCallback = { count in
                test.expectations[count].fulfill()
            }

            let mStorage = MockEntryStorage()
            for l in test.inputLogs {
                do {
                    try mStorage.save(l, to: path)
                } catch {
                    XCTFail("[\(test.name)] \(error)")
                }
            }

            let output = BufferedOutput(writer: mwriter,
                                        config: test.config,
                                        entryStorage: mStorage,
                                        internalErrorLogger: InternalErrorLogger(LogConsoleDestination()))
            output.start()

            wait(for: test.expectations, timeout: TimeInterval(test.expectations.count))
            XCTAssertEqual(mwriter.calledWriteCount,
                           test.wantCalledWriteCount,
                           test.name)
        }
    }

    func testDropEntries() {
        let path = "testDropEntries"
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"

        let tests: [(
            name: String,
            config: Config,
            inputLogs: Set<Entry>,
            emitLogs: Set<Entry>,
            expectations: [XCTestExpectation],
            wantPayloads: [Data]
            )] = [
                (
                    name: "expect to drop no entries",
                    config: Config(flushEntryCount: 2,
                                   flushInterval: CFTimeInterval.infinity,
                                   retryRule: DefaultRetryRule(retryLimit: 1),
                                   maxEntryCountInStorage: 3,
                                   storagePath: path),
                    inputLogs: [
                        Entry("1".data(using: .utf8)!),
                        Entry("1".data(using: .utf8)!),
                        Entry("1".data(using: .utf8)!)
                    ],
                    emitLogs: [
                        Entry("2".data(using: .utf8)!)
                    ],
                    expectations: [
                        self.expectation(description: "flush 1"),
                        self.expectation(description: "flush 2")
                    ],
                    wantPayloads: [
                        "1".data(using: .utf8)!,
                        "1".data(using: .utf8)!,
                        "1".data(using: .utf8)!,
                        "2".data(using: .utf8)!
                    ]
                ),
                (
                    name: "expect to drop entries",
                    config: Config(flushEntryCount: 2,
                                   flushInterval: CFTimeInterval.infinity,
                                   retryRule: DefaultRetryRule(retryLimit: 1),
                                   maxEntryCountInStorage: 2,
                                   storagePath: path),
                    inputLogs: [
                        Entry("1".data(using: .utf8)!),
                        Entry("1".data(using: .utf8)!),
                        Entry("1".data(using: .utf8)!),
                        Entry("1".data(using: .utf8)!)
                    ],
                    emitLogs: [
                        Entry("2".data(using: .utf8)!),
                        Entry("3".data(using: .utf8)!)
                    ],
                    expectations: [
                        self.expectation(description: "flush 1"),
                        self.expectation(description: "flush 2")
                    ],
                    wantPayloads: [
                        "1".data(using: .utf8)!,
                        "1".data(using: .utf8)!,
                        "2".data(using: .utf8)!,
                        "3".data(using: .utf8)!
                    ]
                ),
                (
                    name: "expect to drop older entries",
                    config: Config(flushEntryCount: 2,
                                   flushInterval: CFTimeInterval.infinity,
                                   retryRule: DefaultRetryRule(retryLimit: 1),
                                   maxEntryCountInStorage: 2,
                                   storagePath: path),
                    inputLogs: [
                        Entry("1".data(using: .utf8)!, createTime: fmt.date(from: "2018-1-29")!),
                        Entry("2".data(using: .utf8)!, createTime: fmt.date(from: "2018-3-29")!),
                        Entry("3".data(using: .utf8)!, createTime: fmt.date(from: "2018-7-28")!),
                        Entry("4".data(using: .utf8)!, createTime: fmt.date(from: "2018-7-29")!),
                        Entry("5".data(using: .utf8)!, createTime: fmt.date(from: "2018-7-30")!),
                        Entry("6".data(using: .utf8)!, createTime: fmt.date(from: "2018-7-31")!),
                        Entry("7".data(using: .utf8)!, createTime: fmt.date(from: "2018-6-30")!),
                        Entry("8".data(using: .utf8)!, createTime: fmt.date(from: "2018-5-30")!),
                        Entry("9".data(using: .utf8)!, createTime: fmt.date(from: "2018-4-29")!)
                    ],
                    emitLogs: [
                        Entry("10".data(using: .utf8)!)
                    ],
                    expectations: [
                        self.expectation(description: "flush 1"),
                        self.expectation(description: "flush 2")
                    ],
                    wantPayloads: [
                        "1".data(using: .utf8)!,
                        "2".data(using: .utf8)!,
                        "6".data(using: .utf8)!,
                        "10".data(using: .utf8)!
                    ]
                )
        ]

        for test in tests {
            let mwriter = MockWriter(shouldSuccess: true)
            mwriter.writeCallback = { count in
                test.expectations[count].fulfill()
            }

            let mStorage = MockEntryStorage()
            let output = BufferedOutput(writer: mwriter,
                                        config: test.config,
                                        entryStorage: mStorage,
                                        internalErrorLogger: InternalErrorLogger(LogConsoleDestination()))
            for l in test.inputLogs {
                do {
                    try mStorage.save(l, to: path)
                } catch {
                    XCTFail("[\(test.name)] \(error)")
                }
            }

            output.start()

            for l in test.emitLogs {
                output.emit(l)
            }

            wait(for: test.expectations, timeout: TimeInterval(test.expectations.count))
            XCTAssertEqual(PayloadDecorder.decode(mwriter.givenPayloads).sorted(),
                           PayloadDecorder.decode(test.wantPayloads).sorted(),
                           test.name)
        }
    }
}
