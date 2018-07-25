//
//  BufferedOutputTests.swift
//  BufferedLoggerTests
//
//  Created by YOSHIMUTA YOHEI on 2018/07/25.
//  Copyright © 2018年 YOSHIMUTA YOHEI. All rights reserved.
//
// swiftlint:disable superfluous_disable_command
// swiftlint:disable function_body_length

@testable import BufferedLogger
import XCTest

final class MockWriter: Writer {
    private let shouldSuccess: Bool

    var writeCallback: ((Int) -> Void)?
    private(set) var calledWriteCount: Int = 0

    init(shouldSuccess: Bool) {
        self.shouldSuccess = shouldSuccess
    }

    func write(_ chunk: Chunk,
               completion: (Bool) -> Void) {
        completion(shouldSuccess)
        writeCallback?(calledWriteCount)
        calledWriteCount += 1
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
            waitTime: TimeInterval
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
                    waitTime: 1
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
                    waitTime: 1
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
                    waitTime: 1
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
                    waitTime: 2
                )
        ]

        for test in tests {
            test.writer.writeCallback = { count in
                test.expectations[count].fulfill()
            }

            let output = BufferedOutput(writer: test.writer,
                                        config: test.config)
            output.start()

            for payload in test.inputPayloads {
                output.emit(Entry(payload))
            }

            wait(for: test.expectations, timeout: test.waitTime)
            XCTAssertEqual(test.writer.calledWriteCount,
                           test.expectations.count,
                           test.name)
        }
    }
}
