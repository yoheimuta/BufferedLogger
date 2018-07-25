//
//  BufferedOutputTests.swift
//  BufferedLoggerTests
//
//  Created by YOSHIMUTA YOHEI on 2018/07/25.
//  Copyright © 2018年 YOSHIMUTA YOHEI. All rights reserved.
//

@testable import BufferedLogger
import XCTest

final class MockWriter: Writer {
    private let shouldSuccess: Bool

    var writeCallback: (() -> Void)?
    private(set) var calledWriteCount: Int = 0

    init(shouldSuccess: Bool) {
        self.shouldSuccess = shouldSuccess
    }

    func write(_ chunk: Chunk,
               completion: (Bool) -> Void) {
        completion(shouldSuccess)
        calledWriteCount += 1
        writeCallback?()
    }
}

class BufferedOutputTests: XCTestCase {
    func testFlush() {
        let tests: [(
            name: String,
            writer: MockWriter,
            config: Config,
            inputPayloads: [Data]
        )] = [
                (
                    name: "expect to be called a writer.write() after emitting one entry.",
                    writer: MockWriter(shouldSuccess: true),
                    config: Config(flushEntryCount: 1,
                                   flushInterval: CFTimeInterval.infinity,
                                   retryRule: DefaultRetryRule(retryLimit: 1)),
                    inputPayloads: [
                        "1".data(using: .utf8)!
                    ]
                )
        ]

        for test in tests {
            let expectation = self.expectation(description: "flush")
            test.writer.writeCallback = {
                expectation.fulfill()
            }

            let output = BufferedOutput(writer: test.writer,
                                        config: test.config)
            for payload in test.inputPayloads {
                output.emit(Entry(payload))
            }

            wait(for: [expectation], timeout: 1.0)
            XCTAssertEqual(test.writer.calledWriteCount, 1, test.name)
        }
    }
}
