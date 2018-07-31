//
//  EntryDiskTests.swift
//  BufferedLoggerTests
//
//  Created by YOSHIMUTA YOHEI on 2018/07/30.
//  Copyright © 2018年 YOSHIMUTA YOHEI. All rights reserved.
//
// swiftlint:disable superfluous_disable_command
// swiftlint:disable function_body_length
// swiftlint:disable line_length

@testable import BufferedLogger
import XCTest

class EntryDiskTests: XCTestCase {

    func testBasic() {
        let entries = [
            Entry("1".data(using: .utf8)!),
            Entry("2".data(using: .utf8)!),
            Entry("3".data(using: .utf8)!)
        ]

        let tests: [(
            name: String,
            inputSavingLogs: Set<Entry>,
            inputRemovingLogs: Set<Entry>,
            wantRetrievingAllLogs: Set<Entry>,
            wantRetrievingAllLogs2: Set<Entry>
        )] = [
            (
                name: "expect to get empty logs",
                inputSavingLogs: [],
                inputRemovingLogs: [],
                wantRetrievingAllLogs: [],
                wantRetrievingAllLogs2: []
            ),
            (
                name: "expect to save and get a log",
                inputSavingLogs: [
                    entries[0]
                ],
                inputRemovingLogs: [],
                wantRetrievingAllLogs: [
                    entries[0]
                ],
                wantRetrievingAllLogs2: [
                    entries[0]
                ]
            ),
            (
                name: "expect to remove a log",
                inputSavingLogs: [
                    entries[0]
                ],
                inputRemovingLogs: [
                    entries[0]
                ],
                wantRetrievingAllLogs: [
                    entries[0]
                ],
                wantRetrievingAllLogs2: [
                ]
            ),
            (
                name: "expect to manipulate logs",
                inputSavingLogs: [
                    entries[0],
                    entries[1]
                ],
                inputRemovingLogs: [
                    entries[1],
                    entries[2]
                ],
                wantRetrievingAllLogs: [
                    entries[0],
                    entries[1]
                ],
                wantRetrievingAllLogs2: [
                    entries[0]
                ]
            )
        ]

        for test in tests {
            let path = "testBasic"
            let entryDisk = EntryDisk(fileNamePrefix: "com.github.yoheimuta.BufferedLogger.EntryDiskTests")

            defer {
                do {
                    try entryDisk.removeAll(from: path)
                } catch {
                    XCTFail("[\(test.name)] \(error)")
                }
            }

            do {
                for l in test.inputSavingLogs {
                    try entryDisk.save(l, to: path)
                }
                XCTAssertEqual(try entryDisk.retrieveAll(from: path),
                               test.wantRetrievingAllLogs,
                               test.name)

                try entryDisk.remove(test.inputRemovingLogs, from: path)
                XCTAssertEqual(try entryDisk.retrieveAll(from: path),
                               test.wantRetrievingAllLogs2,
                               test.name)
            } catch {
                XCTFail("[\(test.name)] \(error)")
            }
        }
    }
}
