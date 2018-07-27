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

@testable import BufferedLogger
import XCTest

final class MockWriter: Writer {
    private let shouldSuccess: Bool

    var writeCallback: ((Int) -> Void)?
    private(set) var calledWriteCount: Int = 0
    private(set) var givenPayloads: [Data] = []

    init(shouldSuccess: Bool) {
        self.shouldSuccess = shouldSuccess
    }

    func write(_ chunk: Chunk,
               completion: (Bool) -> Void) {
        calledWriteCount += 1
        chunk.entries.forEach {
            givenPayloads.append($0.payload)
        }

        completion(shouldSuccess)
        writeCallback?(calledWriteCount-1)
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
            waitTime: TimeInterval,
            wantPayloads: [Data]
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
                    waitTime: 1,
                    wantPayloads: [
                        "1".data(using: .utf8)!
                    ]
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
                    waitTime: 1,
                    wantPayloads: [
                        "1".data(using: .utf8)!,
                        "2".data(using: .utf8)!
                    ]
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
                    waitTime: 1,
                    wantPayloads: [
                        "1".data(using: .utf8)!,
                        "2".data(using: .utf8)!
                    ]
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
                    waitTime: 2,
                    wantPayloads: [
                        "1".data(using: .utf8)!,
                        "2".data(using: .utf8)!,
                        "3".data(using: .utf8)!
                    ]
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
                    waitTime: 4,
                    wantPayloads: [
                        "1".data(using: .utf8)!,
                        "2".data(using: .utf8)!,
                        "3".data(using: .utf8)!,
                        "4".data(using: .utf8)!
                    ]
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
                    waitTime: 4,
                    wantPayloads: [
                        "1".data(using: .utf8)!,
                        "1".data(using: .utf8)!,
                        "1".data(using: .utf8)!,
                        "1".data(using: .utf8)!
                    ]
                )
        ]

        for test in tests {
            test.writer.writeCallback = { count in
                test.expectations[count].fulfill()
            }

            let output = BufferedOutput(writer: test.writer,
                                        config: test.config)

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
        }
    }

    func testSuspend() {
        let tests: [(
            name: String,
            isCallSuspend: Bool,
            wantCalledWriteCount: Int
        )] = [
            (
                name: "expect a call to flush without suspension",
                isCallSuspend: false,
                wantCalledWriteCount: 1
            ),
            (
                name: "expect no call to flush after suspension",
                isCallSuspend: true,
                wantCalledWriteCount: 0
            )
        ]

        for test in tests {
            let mwriter = MockWriter(shouldSuccess: true)
            let output = BufferedOutput(writer: mwriter,
                                        config: Config(flushEntryCount: 10,
                                                       flushInterval: 1,
                                                       retryRule: DefaultRetryRule(retryLimit: 1)))
            output.start()

            if test.isCallSuspend {
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
}
