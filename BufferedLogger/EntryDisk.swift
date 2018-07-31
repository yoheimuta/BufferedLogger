//
//  EntryDisk.swift
//  BufferedLogger
//
//  Created by YOSHIMUTA YOHEI on 2018/07/30.
//  Copyright © 2018年 YOSHIMUTA YOHEI. All rights reserved.
//

import Foundation

/// EntryDisk is a controller to save entries to the local file system.
public final class EntryDisk: EntryStorage {
    public static let `default` = EntryDisk()

    private let directory: FileManager.SearchPathDirectory
    private let fileNamePrefix: String

    public init(directory: FileManager.SearchPathDirectory = .cachesDirectory,
                fileNamePrefix: String = "com.github.yoheimuta.BufferedLogger.EntryDisk") {
        self.directory = directory
        self.fileNamePrefix = fileNamePrefix
    }

    public func retrieveAll(from path: String) throws -> Set<Entry> {
        guard try exist(for: path) else {
            return []
        }

        let data = try read(from: path)
        let decorder = PropertyListDecoder()
        let logs = try decorder.decode([Entry].self, from: data)
        return Set<Entry>(logs)
    }

    public func save(_ log: Entry, to path: String) throws {
        let unioned = try retrieveAll(from: path).union([log])
        try write(unioned, to: path)
    }

    public func remove(_ logs: Set<Entry>, from path: String) throws {
        guard try exist(for: path) else {
            return
        }

        let rest = try retrieveAll(from: path).subtracting(logs)
        try write(rest, to: path)
    }
}

extension EntryDisk {
    /// removeAll removes an item located at path.
    public func removeAll(from path: String = defaultStoragePath) throws {
        guard try exist(for: path) else {
            return
        }

        try remove(for: path)
    }
}

extension EntryDisk {
    private func createURL(for path: String) throws -> URL {
        let url = try cachesDirectoryURL()
        return url.appendingPathComponent("\(fileNamePrefix)_\(path)")
    }

    private func cachesDirectoryURL() throws -> URL {
        return try FileManager.default.url(for: directory,
                                           in: .userDomainMask,
                                           appropriateFor: nil,
                                           create: true)
    }

    private func read(from path: String) throws -> Data {
        return try Data(contentsOf: createURL(for: path))
    }

    private func write(_ logs: Set<Entry>, to path: String) throws {
        let encoder = PropertyListEncoder()
        let data = try encoder.encode(logs)
        try data.write(to: createURL(for: path))
    }

    private func exist(for path: String) throws -> Bool {
        return FileManager.default.fileExists(atPath: try createURL(for: path).path)
    }

    private func remove(for path: String) throws {
        try FileManager.default.removeItem(at: createURL(for: path))
    }
}
